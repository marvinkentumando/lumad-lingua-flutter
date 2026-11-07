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
    this.feedback = "",
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
      } catch (_) {}
    }

    final baseFeatures = features.isEmpty
        ? <List<List<double>>>[]
        : [for (int i = 0; i < features.length && i < processedPcms.length * 3; i += 3) features[i]];

    return PronunciationReferenceSet(
      referenceFeatures: features,
      primaryPcm: processedPcms.isEmpty ? const [] : processedPcms.first,
      baseline: _baselineFromReferences(baseFeatures),
      baseTakeCount: processedPcms.length,
    );
  }

  static ReferenceBaseline _baselineFromReferences(List<List<List<double>>> references) {
    if (references.length < 2) return ReferenceBaseline.provisional;

    final distances = <double>[];
    for (int i = 0; i < references.length; i++) {
      for (int j = i + 1; j < references.length; j++) {
        final distance = MFCCService.calculateMFCCDistance(references[i], references[j]);
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
    double bestMeanCost = double.infinity;
    double bestMaxCost = 0.0;
    for (final referenceFeatures in referenceSet.referenceFeatures) {
      final alignment = MFCCService.align(referenceFeatures, userFeatures);
      if (alignment.isUsable && alignment.meanLocalCost.isFinite) {
        distances.add(alignment.meanLocalCost);
        if (alignment.meanLocalCost < bestMeanCost) {
          bestMeanCost = alignment.meanLocalCost;
          bestMaxCost = alignment.maxLocalCost;
        }
      }
    }
    if (distances.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }
    distances.sort();
    final bestCount = distances.length >= 2 ? 2 : 1;
    final distance = distances.take(bestCount).reduce((a, b) => a + b) / bestCount;

    final bool maxFrameMismatch = bestMaxCost > 35.0;
    final bool lacksSpokenEnergy = !_learnerHasSpokenEnergy(processedUser);

    if (distance > _mismatchThreshold(referenceSet.baseline) || maxFrameMismatch || lacksSpokenEnergy) {
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

    double similarity;
    if (algorithm == PronunciationAlgorithm.dtw) {
      similarity = scoreFromDistance(distance, referenceSet.baseline, strictness);
    } else {
      var best = 0.0;
      for (final referenceFeatures in referenceSet.referenceFeatures) {
        final candidate = algorithm == PronunciationAlgorithm.hmm
            ? _calculateHMMScore(referenceFeatures, userFeatures, strictness)
            : _calculateCosineScore(referenceFeatures, userFeatures, strictness);
        if (candidate > best) best = candidate;
      }
      similarity = best;
    }

    final paceRatio = processedUser.length / math.max(1, referenceSet.primaryPcm.length);
    final paceScore = (1.0 - (paceRatio - 1.0).abs() / 1.5).clamp(0.0, 1.0);
    final fluency = (0.6 * paceScore + 0.4 * similarity).clamp(0.0, 1.0);

    return PronunciationScore(
      overallScore: similarity * 100,
      accuracy: similarity,
      fluency: fluency,
      clarity: _speechClarity(processedUser),
      nativeWaveform: referenceSet.primaryPcm,
      studentWaveform: userSamples,
      feedback: _generateFeedback(similarity),
      algorithmUsed: algorithm,
      distance: distance,
      isCalibrated: referenceSet.baseline.isCalibrated,
      referenceCount: referenceSet.takeCount,
      isMismatch: false,
    );
  }

  static double _mismatchThreshold(ReferenceBaseline baseline) {
    final sigma = math.max(baseline.sigma, math.max(baseline.mean * 0.15, 1e-6));
    final calibrated = baseline.mean + 3.5 * sigma;
    if (baseline.isCalibrated) return math.max(calibrated, baseline.mean * 2.0);
    return math.max(calibrated, math.max(baseline.mean + 4.0 * sigma, 16.5));
  }

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
    final score = 1.0 / (1.0 + math.exp(slope * z));
    return score.isFinite ? score.clamp(0.0, 1.0) : 0.0;
  }

  static bool _learnerHasSpokenEnergy(List<double> pcm) {
    if (pcm.isEmpty) return false;
    const frameSize = 256;
    const minActiveFrames = 2;
    final activeCount = <double>[];
    for (int i = 0; i + frameSize <= pcm.length; i += frameSize) {
      double sum = 0.0;
      for (int j = i; j < i + frameSize; j++) {
        sum += pcm[j] * pcm[j];
      }
      final rms = math.sqrt(sum / frameSize);
      activeCount.add(rms);
    }
    if (activeCount.isEmpty) return false;

    final peak = activeCount.reduce(math.max);
    if (peak <= 1e-7) return false;
    final activeAboveFloor = activeCount
        .where((v) => v >= math.max(peak * 0.18, 1e-5))
        .length;
    return activeAboveFloor >= minActiveFrames;
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

      bool predictedPass = score >= 0.6;
      bool actualPass = truth >= 0.6;
      if (predictedPass == actualPass) correctPredictions++;
    }

    final mae = totalError / dataset.length;
    final accuracy = correctPredictions / dataset.length;
    double correlation = _calculateCorrelation(predictedScores, groundTruthScores);

    return PronunciationModelMetrics(
      meanAbsoluteError: mae,
      correlation: correlation,
      accuracy: accuracy,
    );
  }

  static double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    int n = x.length;
    double sumX = x.reduce((a, b) => a + b);
    double sumY = y.reduce((a, b) => a + b);
    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;

    for (int i = 0; i < n; i++) {
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }

    double numerator = n * sumXY - sumX * sumY;
    double denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }

  static double _calculateHMMScore(
    List<List<double>> modelFrames,
    List<List<double>> observationFrames,
    PronunciationStrictness strictness
  ) {
    if (modelFrames.isEmpty || observationFrames.isEmpty) return 0.0;

    double logLikelihood = 0.0;
    for (int i = 0; i < observationFrames.length; i++) {
      final obs = observationFrames[i];
      double bestFrameDist = double.infinity;
      for (final state in modelFrames) {
        double d = _euclideanDistance(obs, state);
        if (d < bestFrameDist) bestFrameDist = d;
      }
      logLikelihood -= bestFrameDist;
    }

    final avgLogLikelihood = logLikelihood / observationFrames.length;
    return math.exp(strictness.sensitivity * 0.4 * avgLogLikelihood).clamp(0.0, 1.0);
  }

  static double _calculateCosineScore(
    List<List<double>> s,
    List<List<double>> t,
    PronunciationStrictness strictness
  ) {
    final alignment = MFCCService.align(
      s,
      t,
      frameCost: (a, b) => 1.0 - _cosineSimilarity(a, b),
    );
    if (!alignment.isUsable) return 0.0;

    return math.exp(-strictness.sensitivity * 2.0 * alignment.meanLocalCost).clamp(0.0, 1.0);
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

  static double _speechClarity(List<double> pcm) {
    if (pcm.length < 160) return 0.0;
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
      feedback: "Audio processing failed. Please check your recording and try again.",
    );
  }

  static String _mismatchFeedback(double distance, PronunciationReferenceSet referenceSet) {
    final threshold = _mismatchThreshold(referenceSet.baseline);
    if (!threshold.isFinite || threshold <= 0) {
      return "That doesn't sound like the target phrase. Please listen to the native speaker and record the phrase shown.";
    }
    final distanceCloseness = distance / threshold;
    if (distanceCloseness < 0.65) {
      return "Your shape is getting close, but the timing and fullness aren't quite right yet. Slow it down, hold the vowel a bit longer, and record again.";
    }
    if (distanceCloseness < 0.85) {
      return "This sounds a lot closer than a different word, so you're on the right track. Listen again for the stressed syllable and record it a little more clearly.";
    }
    return "That clearly doesn't match the target phrase. Please listen to the native speaker and record the phrase shown.";
  }

  static String _generateFeedback(double score) {
    if (score >= 0.80) return "Excellent! Your pronunciation is near-perfect.";
    if (score >= 0.60) return "Great job! Very clear and accurate.";
    if (score >= 0.45) return "Good effort! Try matching the native speaker's rhythm and vowels.";
    if (score >= 0.25) return "Mispronunciation detected. Listen closely to the native speaker and record again.";
    return "Different word or incorrect speech detected. Please listen to the native speaker and record again.";
  }

  static String _getFeedbackKey(double score) {
    if (score >= 0.80) return 'feedback_excellent';
    if (score >= 0.60) return 'feedback_good_effort';
    return 'feedback_needs_work';
  }
}
