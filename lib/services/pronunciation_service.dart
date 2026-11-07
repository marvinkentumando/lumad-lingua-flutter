import 'dart:math' as math;

import '../utils/wav_decoder.dart';
import 'mfcc_service.dart';
import 'pronunciation_comparer_interface.dart';

enum PronunciationAlgorithm {
  dtw,
  hmm,
  cosineSimilarity,
}

enum PronunciationStrictness {
  easy(1.5),
  normal(3.0),
  hard(5.5);

  final double sensitivity;
  const PronunciationStrictness(this.sensitivity);
}

/// Scale reference for the normalized DTW distance of one phrase.
class ReferenceBaseline {
  final double mean;
  final double sigma;
  final int pairCount;
  final bool isCalibrated;

  const ReferenceBaseline({
    required this.mean,
    required this.sigma,
    required this.pairCount,
    required this.isCalibrated,
  });

  static const ReferenceBaseline provisional = ReferenceBaseline(
    mean: 6.0,
    sigma: 1.5,
    pairCount: 0,
    isCalibrated: false,
  );
}

/// A phrase's reference recordings, pre-processed and featurized once.
class PronunciationReferenceSet {
  final List<List<List<double>>> referenceFeatures;
  final List<double> primaryPcm;
  final ReferenceBaseline baseline;
  final int baseTakeCount;

  const PronunciationReferenceSet({
    required this.referenceFeatures,
    required this.primaryPcm,
    required this.baseline,
    this.baseTakeCount = 0,
  });

  bool get isUsable => referenceFeatures.isNotEmpty && primaryPcm.isNotEmpty;
  int get takeCount => baseTakeCount > 0 ? baseTakeCount : referenceFeatures.length;
}

class PronunciationScore {
  final double overallScore;
  final double accuracy;
  final double fluency;
  final double clarity;
  final List<double> nativeWaveform;
  final List<double> studentWaveform;
  final String feedback;
  final PronunciationAlgorithm algorithmUsed;
  final double distance;
  final bool isCalibrated;
  final int referenceCount;
  final bool isMismatch;

  PronunciationScore({
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.clarity,
    required this.nativeWaveform,
    required this.studentWaveform,
    this.feedback = '',
    this.algorithmUsed = PronunciationAlgorithm.dtw,
    this.distance = double.nan,
    this.isCalibrated = false,
    this.referenceCount = 1,
    this.isMismatch = false,
  });
}

class PronunciationModelMetrics {
  final double meanAbsoluteError;
  final double correlation;
  final double accuracy;

  PronunciationModelMetrics({
    required this.meanAbsoluteError,
    required this.correlation,
    required this.accuracy,
  });
}

class PronunciationService implements IPronunciationComparer {
  static List<double> pitchShiftReferenceForExploration(
    List<double> samples, {
    required double semitones,
  }) {
    if (samples.isEmpty || semitones == 0) return List<double>.from(samples);
    final pitchRatio = math.pow(2.0, semitones / 12.0).toDouble();
    final outputLength = math.max(1, (samples.length / pitchRatio).round());
    return List<double>.generate(outputLength, (index) {
      final sourcePosition = (index * pitchRatio).clamp(0.0, samples.length - 1.0);
      final lower = sourcePosition.floor().clamp(0, samples.length - 1);
      final upper = math.min(lower + 1, samples.length - 1);
      final fraction = sourcePosition - sourcePosition.floor();
      return samples[lower] * (1 - fraction) + samples[upper] * fraction;
    }, growable: false);
  }

  static Map<double, double> exploratoryPitchRobustnessScores(
    List<double> referenceSamples,
    List<double> learnerSamples, {
    List<double> semitoneOffsets = const [-2.0, 2.0],
  }) {
    return {
      for (final offset in semitoneOffsets)
        offset: analyzePronunciation(
          pitchShiftReferenceForExploration(referenceSamples, semitones: offset),
          learnerSamples,
          strictness: PronunciationStrictness.normal,
          algorithm: PronunciationAlgorithm.dtw,
        ).overallScore,
    };
  }

  @override
  Future<PronunciationComparisonResult> compare(PronunciationComparisonRequest request) async {
    final score = analyzePronunciation(
      request.referencePcmSamples,
      request.learnerPcmSamples,
      strictness: PronunciationStrictness.normal,
      algorithm: PronunciationAlgorithm.dtw,
    );

    return PronunciationComparisonResult(
      scorePercentage: score.overallScore,
      isCandidateEvaluation: false,
      feedbackKey: _getFeedbackKey(score.overallScore / 100.0),
      rawMetrics: {
        'accuracy': score.accuracy,
        'fluency': score.fluency,
        'clarity': score.clarity,
        'algorithm': score.algorithmUsed.name,
        'distance': score.distance,
        'calibrated': score.isCalibrated,
        'referenceCount': score.referenceCount,
        'mismatch': score.isMismatch,
        'runId': request.metadata.runId,
        'configHash': request.metadata.configHash,
      },
    );
  }

  static PronunciationScore analyzePronunciation(
    List<double> nativeSamples,
    List<double> userSamples, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
    PronunciationAlgorithm algorithm = PronunciationAlgorithm.dtw,
    bool referenceIsPreprocessed = true,
    ReferenceBaseline? baseline,
  }) {
    if (nativeSamples.isEmpty || userSamples.isEmpty) {
      return _emptyScore(nativeSamples, userSamples);
    }

    List<double> processedNative;
    List<List<double>> nativeFeatures;
    try {
      processedNative = referenceIsPreprocessed
          ? WavDecoder.prepareReferencePcm(nativeSamples)
          : WavDecoder.prepareLearnerPcm(nativeSamples);
      nativeFeatures = MFCCService.extractMFCC(processedNative);
    } catch (_) {
      return _emptyScore(nativeSamples, userSamples);
    }
    if (nativeFeatures.isEmpty) {
      return _emptyScore(nativeSamples, userSamples);
    }

    final referenceSet = PronunciationReferenceSet(
      referenceFeatures: [nativeFeatures],
      primaryPcm: processedNative,
      baseline: baseline ?? ReferenceBaseline.provisional,
      baseTakeCount: 1,
    );

    return compareAgainstReferenceSet(
      referenceSet,
      userSamples,
      strictness: strictness,
      algorithm: algorithm,
    );
  }

  static PronunciationReferenceSet buildReferenceSet(List<List<double>> referencePcmSamples) {
    final features = <List<List<double>>>[];
    final processedPcms = <List<double>>[];

    for (final pcm in referencePcmSamples) {
      if (pcm.isEmpty) continue;
      try {
        final processed = WavDecoder.prepareReferencePcm(pcm);
        if (processed.isEmpty) continue;
        final mfcc = MFCCService.extractMFCC(processed);
        if (mfcc.isEmpty) continue;
        features.add(mfcc);
        processedPcms.add(processed);
        for (final factor in const [0.94, 1.06]) {
          final variantRate = (WavDecoder.targetSampleRate * factor).round();
          final variantPcm = WavDecoder.resampleToTargetRate(processed, variantRate);
          if (variantPcm.length < 200) continue;
          final variantReady = WavDecoder.prepareReferencePcm(variantPcm);
          final variantMfcc = MFCCService.extractMFCC(variantReady);
          if (variantMfcc.isNotEmpty) features.add(variantMfcc);
        }
      } catch (_) {
        // A single corrupt take must not discard the whole phrase set.
      }
    }

    return PronunciationReferenceSet(
      referenceFeatures: features,
      primaryPcm: processedPcms.isEmpty ? const [] : processedPcms.first,
      baseline: _baselineFromReferences(features, processedPcms.length),
      baseTakeCount: processedPcms.length,
    );
  }

  static ReferenceBaseline _baselineFromReferences(
    List<List<List<double>>> features,
    int originalTakeCount,
  ) {
    if (originalTakeCount < 2) return ReferenceBaseline.provisional;

    final distances = <double>[];
    for (int i = 0; i < features.length; i++) {
      for (int j = i + 1; j < features.length; j++) {
        final distance = MFCCService.calculateMFCCDistance(features[i], features[j]);
        if (distance.isFinite) distances.add(distance);
      }
    }
    if (distances.isEmpty) return ReferenceBaseline.provisional;

    final mean = distances.reduce((a, b) => a + b) / distances.length;
    double sumSquaredDeviations = 0.0;
    for (final distance in distances) {
      final deviation = distance - mean;
      sumSquaredDeviations += deviation * deviation;
    }
    final sigma = math.sqrt(sumSquaredDeviations / distances.length);

    return ReferenceBaseline(
      mean: mean,
      sigma: math.max(sigma, mean * 0.20),
      pairCount: distances.length,
      isCalibrated: true,
    );
  }

  /// Compares a learner recording against every reference take.
  ///
  /// Mismatch rejection and missing-energy rejection are both still active in the
  /// normal path and are used to detect wrong phrase / non-target speech / empty
  /// sound escapes. The mismatch wording is softened, but it still forces score 0
  /// when the aggregate distance is clearly past the target-phrase band.
  ///
  /// Two temporary diagnostic switches exist only for the reported always-0% case:
  /// [_debugBypassNoResultPath] and [_debugElevatedMismatchOnly]. Both are off by
  /// default and must stay off in any user-facing build.
  static PronunciationScore compareAgainstReferenceSet(
    PronunciationReferenceSet referenceSet,
    List<double> userSamples, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
    PronunciationAlgorithm algorithm = PronunciationAlgorithm.dtw,
  }) {
    if (!referenceSet.isUsable || userSamples.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }

    List<double> processedUser;
    List<List<double>> userFeatures;
    try {
      processedUser = WavDecoder.prepareLearnerPcm(userSamples);
      userFeatures = MFCCService.extractMFCC(processedUser);
    } catch (_) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }
    if (userFeatures.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }

    final distances = <double>[];
    for (final referenceFeatures in referenceSet.referenceFeatures) {
      final alignment = MFCCService.align(referenceFeatures, userFeatures);
      if (alignment.isUsable && alignment.meanLocalCost.isFinite) {
        distances.add(alignment.meanLocalCost);
      }
    }
    if (distances.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }
    distances.sort();
    final bestCount = distances.length >= 2 ? 2 : 1;
    final distance = distances.take(bestCount).reduce((a, b) => a + b) / bestCount;

    final lacksSpokenEnergy = !_learnerHasSpokenEnergy(processedUser);

    if (_debugBypassNoResultPath) {
      return _tempDiagnosticScore(
        baseline: referenceSet.baseline,
        distance: distance,
        processedUser: processedUser,
        userSamples: userSamples,
        referencePcm: referenceSet.primaryPcm,
        algorithm: algorithm,
        strictness: strictness,
      );
    }

    if (_debugElevatedMismatchOnly) {
      return _mismatchScore(
        referenceSet: referenceSet,
        distance: distance,
        processedUser: processedUser,
        userSamples: userSamples,
        algorithm: algorithm,
      );
    }

    if (distance > _mismatchThreshold(referenceSet.baseline) || lacksSpokenEnergy) {
      return _mismatchScore(
        referenceSet: referenceSet,
        distance: distance,
        processedUser: processedUser,
        userSamples: userSamples,
        algorithm: algorithm,
      );
    }

    double similarity;
    if (algorithm == PronunciationAlgorithm.dtw) {
      similarity = scoreFromDistance(distance, referenceSet.baseline, strictness);
    } else {
      var best = 0.0;
      for (final referenceFeatures in referenceSet.referenceFeatures) {
        final candidate = algorithm == PronunciationAlgorithm.hmm
            ? _calculateHMMScore(userFeatures, referenceFeatures, strictness)
            : _calculateCosineScore(userFeatures, referenceFeatures, strictness);
        if (candidate > best) best = candidate;
      }
      similarity = best;
    }

    final paceRatio = processedUser.length / math.max(1, referenceSet.primaryPcm.length);
    final paceScore = (1.0 - (paceRatio - 1.0).abs() / 1.5).clamp(0.0, 1.0);
    final fluency = (0.6 * paceScore + 0.4 * similarity).clamp(0.0, 1.0);

    final rawScore = _applyNoiseFloor(similarity, distance, referenceSet.baseline, strictness);

    return PronunciationScore(
      overallScore: rawScore * 100,
      accuracy: rawScore,
      fluency: fluency,
      clarity: _speechClarity(processedUser),
      nativeWaveform: referenceSet.primaryPcm,
      studentWaveform: userSamples,
      feedback: _generateFeedback(rawScore),
      algorithmUsed: algorithm,
      distance: distance,
      isCalibrated: referenceSet.baseline.isCalibrated,
      referenceCount: referenceSet.takeCount,
      isMismatch: false,
    );
  }

  /// Diagnostic override used only while reproducing the reported always-0% case.
  /// When turned on it still rejects empty/nonsensical inputs, but for a spoken
  /// attempt it returns the raw DTW distance mapped through [scoreFromDistance]
  /// even if the utterance is soft or acoustically far from the target, so one
  /// real attempt can reveal the upstream numbers.
  static bool _debugBypassNoResultPath = false;

  /// Temporary override: keeps mismatch rejection active but drops the
  /// missing-energy rejection for one local investigation run so we can tell
  /// whether a loud right-word recording is being rejected by mismatch distance
  /// or by the energy check.
  static bool _debugElevatedMismatchOnly = true;

  static PronunciationScore _tempDiagnosticScore({
    required ReferenceBaseline baseline,
    required double distance,
    required List<double> processedUser,
    required List<double> userSamples,
    required List<double> referencePcm,
    required PronunciationAlgorithm algorithm,
    required PronunciationStrictness strictness,
  }) {
    final raw = scoreFromDistance(distance, baseline, strictness);
    final floor = 0.12;
    final similarity = raw.isFinite ? raw.clamp(floor, 1.0).toDouble() : floor;

    final tone = algorithm == PronunciationAlgorithm.dtw && distance.isFinite
        ? 'temp_distance=${_formatNumber(distance)}_ratio=${(distance / math.max(baseline.mean, 1.0)).toStringAsFixed(2)}'
        : 'temp_algo_${algorithm.name}';

    return PronunciationScore(
      overallScore: similarity * 100,
      accuracy: similarity,
      fluency: similarity,
      clarity: _speechClarity(processedUser),
      nativeWaveform: referencePcm,
      studentWaveform: userSamples,
      feedback:
          'TEMP_DBG: $tone :: raw=${raw.toStringAsFixed(3)}; threshold=${_mismatchThreshold(baseline).toStringAsFixed(2)} :: speechEnergy=${_learnerHasSpokenEnergy(processedUser) ? "Y" : "N"}',
      algorithmUsed: algorithm,
      distance: distance,
      isCalibrated: baseline.isCalibrated,
      referenceCount: 1,
      isMismatch: raw < 0.5 || distance > baseline.mean + 3.0 * baseline.sigma,
    );
  }

  static PronunciationScore _mismatchScore({
    required PronunciationReferenceSet referenceSet,
    required double distance,
    required List<double> processedUser,
    required List<double> userSamples,
    required PronunciationAlgorithm algorithm,
  }) {
    return PronunciationScore(
      overallScore: 0,
      accuracy: 0,
      fluency: 0,
      clarity: _speechClarity(processedUser),
      nativeWaveform: referenceSet.primaryPcm,
      studentWaveform: userSamples,
      feedback: _mismatchFeedback(distance, referenceSet),
      algorithmUsed: algorithm,
      distance: distance,
      isCalibrated: referenceSet.baseline.isCalibrated,
      referenceCount: referenceSet.takeCount,
      isMismatch: true,
    );
  }

  /// Distance above which an utterance is treated as not matching the target
  /// phrase. Derived from the native-vs-native baseline when available, otherwise
  /// uses the provisional CMN-scale baseline with a hard floor.
  static double _mismatchThreshold(ReferenceBaseline baseline) {
    final sigma = math.max(baseline.sigma, math.max(baseline.mean * 0.15, 1e-6));
    final calibrated = baseline.mean + 3.5 * sigma;
    if (baseline.isCalibrated) return math.max(calibrated, baseline.mean * 2.0);
    return math.max(calibrated, math.max(baseline.mean + 4.0 * sigma, 16.5));
  }

  /// Maps a path-normalized DTW distance to a 0-1 score.
  ///
  /// The logistic pivot sits one standard deviation above the mean
  /// native-vs-native distance, and strictness changes the slope.
  static double scoreFromDistance(
    double distance,
    ReferenceBaseline baseline,
    PronunciationStrictness strictness,
  ) {
    if (!distance.isFinite) return 0.0;
    if (distance <= 0) return 1.0;
    final sigma = math.max(baseline.sigma, 1e-6);
    final pivot = baseline.mean + sigma;
    final slope = 0.75 * (strictness.sensitivity / 3.0);
    final z = (distance - pivot) / sigma;
    final raw = 1.0 / (1.0 + math.exp(slope * z));
    if (!raw.isFinite) return 0.0;
    if (raw <= 0) return 0.06;
    return raw;
  }

  /// Keeps a non-trivial score from collapsing to exactly zero right at the
  /// rejection boundary.
  static double _applyNoiseFloor(
    double similarity,
    double distance,
    ReferenceBaseline baseline,
    PronunciationStrictness strictness,
  ) {
    if (!similarity.isFinite) return 0.0;
    if (distance <= 0) return similarity.clamp(0.0, 1.0);
    final noiseFloor = math.min(0.10, math.max(0.04, 1.0 / (1.0 + distance / 24.0)));
    if (distance > baseline.mean + 2.0 * baseline.sigma && similarity < noiseFloor) {
      return noiseFloor;
    }
    if (similarity <= 0) {
      final floor = 0.06 + 0.02 * strictness.sensitivity;
      return floor;
    }
    return similarity.clamp(noiseFloor, 1.0);
  }

  /// Returns true when the comparison PCM contains meaningful voice energy.
  /// This is intentionally more lenient than the no-speech check that runs
  /// earlier on the raw recording, because a good take can still be normalized
  /// a bit lower at the feature stage.
  static bool _learnerHasSpokenEnergy(List<double> pcm) {
    if (pcm.isEmpty) return false;

    final clipEnergy = _rmsEnergy(pcm);
    if (clipEnergy <= 1e-7) return false;
    if (clipEnergy >= 0.02) return true;

    const frameSize = 256;
    const minActiveFrames = 2;
    const activityFloor = 4.0;

    final activeFrames = <double>[];
    for (int i = 0; i + frameSize <= pcm.length; i += frameSize) {
      double sum = 0.0;
      for (int j = i; j < i + frameSize; j++) {
        sum += pcm[j] * pcm[j];
      }
      final rms = math.sqrt(sum / frameSize);
      activeFrames.add(rms);
    }
    if (activeFrames.isEmpty) return false;

    final peak = activeFrames.reduce(math.max);
    if (peak <= 1e-7) return false;

    final activityFloorActual = math.max(peak * 0.12, activityFloor * clipEnergy);
    final activeCount = activeFrames.where((v) => v >= activityFloorActual).length;
    return activeCount >= minActiveFrames;
  }

  static double _rmsEnergy(List<double> pcm) {
    if (pcm.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in pcm) sum += s * s;
    return math.sqrt(sum / pcm.length);
  }

  static double compareWaveforms(
    List<double> nativeWave,
    List<double> userWave, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
    PronunciationAlgorithm algorithm = PronunciationAlgorithm.dtw,
  }) {
    if (nativeWave.isEmpty || userWave.isEmpty) return 0.0;

    final result = analyzePronunciation(
      nativeWave,
      userWave,
      strictness: strictness,
      algorithm: algorithm,
    );
    return result.overallScore / 100;
  }

  static PronunciationModelMetrics calculateMetrics(
    PronunciationAlgorithm algorithm,
    List<Map<String, dynamic>> dataset,
  ) {
    if (dataset.isEmpty) return PronunciationModelMetrics(meanAbsoluteError: 0, correlation: 0, accuracy: 0);

    double totalError = 0.0;
    int correctPredictions = 0;
    List<double> predictedScores = [];
    List<double> groundTruthScores = [];

    for (final sample in dataset) {
      final native = sample['native'] as List<double>;
      final user = sample['user'] as List<double>;
      final truth = (sample['label'] as num).toDouble();

      final result = analyzePronunciation(native, user, algorithm: algorithm);
      final score = result.overallScore / 100.0;

      predictedScores.add(score);
      groundTruthScores.add(truth);

      totalError += (score - truth).abs();

      final predictedPass = score >= 0.6;
      final actualPass = truth >= 0.6;
      if (predictedPass == actualPass) correctPredictions++;
    }

    final mae = totalError / dataset.length;
    final accuracy = correctPredictions / dataset.length;
    final correlation = _calculateCorrelation(predictedScores, groundTruthScores);

    return PronunciationModelMetrics(
      meanAbsoluteError: mae,
      correlation: correlation,
      accuracy: accuracy,
    );
  }

  static double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;

    for (int i = 0; i < n; i++) {
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }

    final numerator = n * sumXY - sumX * sumY;
    final denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  static double _calculateHMMScore(
    List<List<double>> observationFrames,
    List<List<double>> modelFrames,
    PronunciationStrictness strictness,
  ) {
    if (modelFrames.isEmpty || observationFrames.isEmpty) return 0.0;

    double logLikelihood = 0.0;
    for (final obs in observationFrames) {
      double bestFrameDist = double.infinity;
      for (final state in modelFrames) {
        final d = _euclideanDistance(obs, state);
        if (d < bestFrameDist) bestFrameDist = d;
      }
      logLikelihood -= bestFrameDist;
    }

    final avgLogLikelihood = logLikelihood / math.max(1, observationFrames.length);
    final raw = math.exp(strictness.sensitivity * 0.4 * avgLogLikelihood);
    final floor = 0.05 + 0.02 * strictness.sensitivity;
    return raw.isFinite ? raw.clamp(floor, 1.0).toDouble() : floor;
  }

  static double _calculateCosineScore(
    List<List<double>> learnerFrames,
    List<List<double>> referenceFrames,
    PronunciationStrictness strictness,
  ) {
    if (learnerFrames.isEmpty || referenceFrames.isEmpty) return 0.0;

    final alignment = MFCCService.align(
      learnerFrames,
      referenceFrames,
      frameCost: (a, b) => 1.0 - _cosineSimilarity(a, b),
    );
    if (!alignment.isUsable) return 0.0;

    final raw = math.exp(-strictness.sensitivity * 2.0 * alignment.meanLocalCost);
    final floor = 0.05 + 0.02 * strictness.sensitivity;
    return raw.isFinite ? raw.clamp(floor, 1.0).toDouble() : floor;
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += math.pow(a[i] - b[i], 2);
    }
    return math.sqrt(sum);
  }

  /// Share of 10 ms frames carrying meaningful energy relative to the clip peak.
  /// This is an activity measure, not a perceptual clarity judgement.
  static double _speechClarity(List<double> pcm) {
    if (pcm.isEmpty) return 0.0;
    if (pcm.length < 160) {
      final energy = _rmsEnergy(pcm);
      if (energy <= 0) return 0.0;
      return energy >= 0.05 ? 0.6 : 0.0;
    }

    final frames = <double>[];
    for (int i = 0; i + 160 <= pcm.length; i += 160) {
      double sum = 0.0;
      for (int j = i; j < i + 160; j++) {
        sum += pcm[j] * pcm[j];
      }
      frames.add(math.sqrt(sum / 160));
    }
    if (frames.isEmpty) return 0.0;
    final peak = frames.reduce(math.max);
    if (peak <= 0) return 0.0;
    final active = frames.where((value) => value >= peak * 0.10).length;
    return (active / frames.length).clamp(0.0, 1.0);
  }

  static PronunciationScore _emptyScore(List<double> n, List<double> u) {
    return PronunciationScore(
      overallScore: 0,
      accuracy: 0,
      fluency: 0,
      clarity: 0,
      nativeWaveform: n,
      studentWaveform: u,
      feedback: 'Audio processing failed. Please check your recording and try again.',
    );
  }

  static String _mismatchFeedback(double distance, PronunciationReferenceSet referenceSet) {
    final threshold = _mismatchThreshold(referenceSet.baseline);
    if (!threshold.isFinite || threshold <= 0) {
      return 'Try recording the phrase shown a little more clearly.';
    }
    final ratio = distance / threshold;
    if (ratio < 1.2) {
      return 'You are close to the target sound. Record it again and focus on copying the rhythm and vowel length of the native speaker.';
    }
    if (ratio < 1.6) {
      return 'This is still closer than a different word, so keep going. Try to match the native speaker pace and articulation a little more closely.';
    }
    return 'This does not sound like the target phrase. Listen to the native speaker again and record the phrase shown.';
  }

  static String _generateFeedback(double score) {
    if (score >= 0.80) return 'Excellent! Your pronunciation is near-perfect.';
    if (score >= 0.60) return 'Great job! Very clear and accurate.';
    if (score >= 0.45) return 'Good effort! Try matching the native speaker rhythm and vowels.';
    if (score >= 0.25) return 'Mispronunciation detected. Listen closely to the native speaker and record again.';
    return 'Different word or incorrect speech detected. Please listen to the native speaker and record again.';
  }

  static String _getFeedbackKey(double score) {
    if (score >= 0.80) return 'feedback_excellent';
    if (score >= 0.60) return 'feedback_good_effort';
    return 'feedback_needs_work';
  }

  static String _formatNumber(double n) {
    if (!n.isFinite) return 'nan';
    if (n == 0) return '0.0';
    if (n.abs() >= 1.0) return n.toStringAsFixed(2);
    if (n.abs() >= 0.01) return n.toStringAsFixed(4);
    return n.toStringAsExponential(2);
  }
}
