import 'dart:math' as math;

import '../utils/wav_decoder.dart';
import 'mfcc_service.dart';
import 'pronunciation_comparer_interface.dart';
import 'speech_embedding_service.dart';

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
    mean: 0.15,
    sigma: 0.04,
    pairCount: 0,
    isCalibrated: false,
  );
}

/// A phrase's reference recordings, pre-processed and featurized once.
class PronunciationReferenceSet {
  final List<List<List<double>>> referenceFeatures;
  final List<double> featurePenalties;
  final List<double> primaryPcm;
  final ReferenceBaseline baseline;
  final int baseTakeCount;

  const PronunciationReferenceSet({
    required this.referenceFeatures,
    this.featurePenalties = const [],
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
<<<<<<< HEAD
  /// One tunable mismatch gate instead of the previous fixed bands.
  static const double _mismatchRejectionMultiplier = 4.5;

  /// Should the live path still reject clearly wrong words by distance?
  static const bool _liveMismatchEnabled = true;

  static List<List<double>> _extractFeatures(List<double> pcm) {
    if (pcm.isEmpty) return [];
    final embeddings = SpeechEmbeddingService.extractEmbeddings(pcm);
    if (embeddings.isNotEmpty) return embeddings;
    return MFCCService.extractMFCC(pcm);
  }

  static DtwAlignment _align(List<List<double>> referenceFeatures, List<List<double>> userFeatures) {
    if (referenceFeatures.isEmpty || userFeatures.isEmpty) {
      return const DtwAlignment(
        meanLocalCost: double.infinity,
        totalCost: double.infinity,
        pathWeight: 0,
        pathLength: 0,
      );
    }
    final sslAlign = MFCCService.align(
      referenceFeatures,
      userFeatures,
      frameCost: SpeechEmbeddingService.calculateCosineDistance,
    );
    if (sslAlign.isUsable && sslAlign.meanLocalCost.isFinite) {
      return sslAlign;
    }
    return MFCCService.align(referenceFeatures, userFeatures);
  }

=======
  /// One tunable mismatch gate instead of the previous fixed bands. When live
  /// mismatch rejection is enabled, this is the main knob that controls how far
  /// a spoken take has to be from the target phrase before it is rejected by the
  /// mismatch branch. Tweak only this number, with [_liveMismatchEnabled] on,
  /// until a correct loud take can pass while a wrong word still fails.
  static const double _mismatchRejectionMultiplier = 4.5;

  /// Should the live path still reject clearly wrong words by distance? When
  /// false, the live path never returns the mismatch score; a non-empty spoken
  /// take gets a real score even if it is phonetically far from the target. When
  /// true, the mismatch branch stays active and uses
  /// [_mismatchRejectionMultiplier] as its only tuning knob right now.
  static const bool _liveMismatchEnabled = true;

>>>>>>> origin/lingua-duel
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
      nativeFeatures = _extractFeatures(processedNative);
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
    final penalties = <double>[];
    final processedPcms = <List<double>>[];

    for (final pcm in referencePcmSamples) {
      if (pcm.isEmpty) continue;
      try {
        final processed = WavDecoder.prepareReferencePcm(pcm);
        if (processed.isEmpty) continue;
        final feat = _extractFeatures(processed);
        if (feat.isEmpty) continue;
        features.add(feat);
        penalties.add(0.0);
        processedPcms.add(processed);
        for (final factor in const [0.94, 1.06]) {
          final variantRate = (WavDecoder.targetSampleRate * factor).round();
          final variantPcm = WavDecoder.resampleToTargetRate(processed, variantRate);
          if (variantPcm.length < 200) continue;
          final variantReady = WavDecoder.prepareReferencePcm(variantPcm);
          final variantFeat = _extractFeatures(variantReady);
          if (variantFeat.isNotEmpty) {
            features.add(variantFeat);
            penalties.add(0.018);
          }
        }
      } catch (_) {}
    }

    final baseFeatures = features.isEmpty
        ? <List<List<double>>>[]
        : [for (int i = 0; i < features.length && i < processedPcms.length * 3; i += 3) features[i]];

    return PronunciationReferenceSet(
      referenceFeatures: features,
      featurePenalties: penalties,
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
        final alignment = _align(references[i], references[j]);
        if (alignment.isUsable && alignment.meanLocalCost.isFinite) {
          distances.add(alignment.meanLocalCost);
        }
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
      userFeatures = _extractFeatures(processedUser);
    } catch (_) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }
    if (userFeatures.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }

    final distances = <double>[];
<<<<<<< HEAD
    for (int i = 0; i < referenceSet.referenceFeatures.length; i++) {
      final referenceFeatures = referenceSet.referenceFeatures[i];
      final penalty = i < referenceSet.featurePenalties.length ? referenceSet.featurePenalties[i] : 0.0;
      final alignment = _align(referenceFeatures, userFeatures);
      if (alignment.isUsable && alignment.meanLocalCost.isFinite) {
        distances.add(alignment.meanLocalCost + penalty);
=======
    for (final referenceFeatures in referenceSet.referenceFeatures) {
      final alignment = MFCCService.align(referenceFeatures, userFeatures);
      if (alignment.isUsable && alignment.meanLocalCost.isFinite) {
        distances.add(alignment.meanLocalCost);
>>>>>>> origin/lingua-duel
      }
    }
    if (distances.isEmpty) {
      return _emptyScore(referenceSet.primaryPcm, userSamples);
    }
    distances.sort();
    final bestCount = distances.length >= 2 ? 2 : 1;
    final distance = distances.take(bestCount).reduce((a, b) => a + b) / bestCount;

    // Rejection is decided by the aggregate distance and by whether the learner
    // produced speech at all. A single-frame spike is deliberately NOT a rejection
    // reason: one transient frame (breath, click, consonant burst) must never zero
    // out an otherwise well-scored take.
    final lacksSpokenEnergy = !_learnerHasSpokenEnergy(processedUser);
    final exceedsDistanceGate =
        _liveMismatchEnabled && distance > _mismatchThreshold(referenceSet.baseline);

    if (exceedsDistanceGate || lacksSpokenEnergy) {
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
<<<<<<< HEAD
            ? _calculateHMMScore(userFeatures, referenceFeatures, strictness, baseline: referenceSet.baseline)
            : _calculateCosineScore(userFeatures, referenceFeatures, strictness, baseline: referenceSet.baseline);
=======
            ? _calculateHMMScore(userFeatures, referenceFeatures, strictness)
            : _calculateCosineScore(userFeatures, referenceFeatures, strictness);
>>>>>>> origin/lingua-duel
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
<<<<<<< HEAD
    if (!baseline.mean.isFinite || baseline.mean <= 0) return 0.60;
    final sigma = math.max(baseline.sigma, math.max(baseline.mean * 0.10, 1e-6));
    if (baseline.isCalibrated) {
      return baseline.mean - 0.4 * sigma;
    }
    return baseline.mean * 1.25;
=======
    final sigma = math.max(baseline.sigma, math.max(baseline.mean * 0.15, 1e-6));
    final calibrated = baseline.mean + _mismatchRejectionMultiplier * sigma;
    if (baseline.isCalibrated) return math.max(calibrated, baseline.mean * (_mismatchRejectionMultiplier - 1.0));
    // Provisional CMN-scale band: keep the floor high enough that real speech
    // passes, but let the multiplier control the wrong-word distance band.
    return math.max(
      calibrated,
      math.max(
        baseline.mean + (_mismatchRejectionMultiplier + 1.0) * sigma,
        _mismatchRejectionMultiplier * 6.0,
      ),
    );
>>>>>>> origin/lingua-duel
  }

  static double scoreFromDistance(
    double distance,
    ReferenceBaseline baseline,
    PronunciationStrictness strictness,
  ) {
    if (!distance.isFinite) return 0.0;
    if (distance <= 0) return 1.0;
    final sigma = math.max(baseline.sigma, 1e-6);
<<<<<<< HEAD
    final pivot = baseline.isCalibrated
        ? baseline.mean - 0.5 * sigma
        : baseline.mean * 0.85;
    final slope = 3.5 * (strictness.sensitivity / 3.0);
=======
    final pivot = baseline.mean + 2.5 * sigma;
    final slope = 0.35 * (strictness.sensitivity / 3.0);
>>>>>>> origin/lingua-duel
    final z = (distance - pivot) / sigma;
    if (z >= 6.0) return 0.0;
    if (z <= -6.0) return 1.0;
    final score = 1.0 / (1.0 + math.exp(slope * z));
    return score.isFinite ? score.clamp(0.0, 1.0) : 0.0;
  }

  static bool _learnerHasSpokenEnergy(List<double> pcm) {
    if (pcm.isEmpty) return false;
    double sumSquares = 0.0;
    double maxAbs = 0.0;
    for (final s in pcm) {
      final absVal = s.abs();
      if (absVal > maxAbs) maxAbs = absVal;
      sumSquares += absVal * absVal;
    }
    final rms = math.sqrt(sumSquares / pcm.length);
    return maxAbs >= 0.005 && rms >= 0.001;
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
    PronunciationStrictness strictness, {
    ReferenceBaseline? baseline,
  }) {
    if (modelFrames.isEmpty || observationFrames.isEmpty) return 0.0;

    double logLikelihood = 0.0;
    for (int i = 0; i < observationFrames.length; i++) {
      final obs = observationFrames[i];
      double bestFrameDist = double.infinity;
      for (final state in modelFrames) {
        double d = SpeechEmbeddingService.calculateCosineDistance(obs, state);
        if (d < bestFrameDist) bestFrameDist = d;
      }
      logLikelihood -= bestFrameDist;
    }

    final avgLogLikelihood = logLikelihood / observationFrames.length;
    final score = math.exp(strictness.sensitivity * 2.0 * avgLogLikelihood).clamp(0.0, 1.0);
    if (baseline != null && (-avgLogLikelihood) > _mismatchThreshold(baseline)) return 0.0;
    return score;
  }

  static double _calculateCosineScore(
    List<List<double>> s,
    List<List<double>> t,
    PronunciationStrictness strictness, {
    ReferenceBaseline? baseline,
  }) {
    final alignment = MFCCService.align(
      s,
      t,
      frameCost: SpeechEmbeddingService.calculateCosineDistance,
    );
    if (!alignment.isUsable) return 0.0;
    if (baseline != null && alignment.meanLocalCost > _mismatchThreshold(baseline)) {
      return 0.0;
    }

    return math.exp(-strictness.sensitivity * 2.5 * alignment.meanLocalCost).clamp(0.0, 1.0);
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
