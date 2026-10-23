import 'dart:math' as math;
import 'mfcc_service.dart';
import '../utils/wav_decoder.dart';
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

class PronunciationScore {
  final double overallScore;
  final double accuracy;
  final double fluency;
  final double clarity;
  final List<double> nativeWaveform;
  final List<double> studentWaveform;
  final String feedback;
  final PronunciationAlgorithm algorithmUsed;

  PronunciationScore({
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.clarity,
    required this.nativeWaveform,
    required this.studentWaveform,
    this.feedback = "",
    this.algorithmUsed = PronunciationAlgorithm.dtw,
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
      isCandidateEvaluation: true,
      feedbackKey: _getFeedbackKey(score.overallScore / 100.0),
      rawMetrics: {
        'accuracy': score.accuracy,
        'fluency': score.fluency,
        'clarity': score.clarity,
        'algorithm': score.algorithmUsed.name,
        'runId': request.metadata.runId,
        'configHash': request.metadata.configHash,
      },
    );
  }

  /// Compares two 16kHz mono PCM waveforms using the Recommended (v1) preprocessing pipeline.
  static PronunciationScore analyzePronunciation(
    List<double> nativeSamples,
    List<double> userSamples, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
    PronunciationAlgorithm algorithm = PronunciationAlgorithm.dtw,
  }) {
    // 1. Preprocessing using the exact Recommended (v1) pipeline
    List<double> processedNative = [];
    List<double> processedUser = [];

    try {
      processedNative = WavDecoder.preprocessPcmRecommendedV1(nativeSamples);
      processedUser = WavDecoder.preprocessPcmRecommendedV1(userSamples);
    } catch (e) {
      return _emptyScore(nativeSamples, userSamples);
    }

    if (processedNative.isEmpty || processedUser.isEmpty) {
      return _emptyScore(nativeSamples, userSamples);
    }

    // 2. Feature Extraction (13 MFCC coefficients)
    final nativeMFCC = MFCCService.extractMFCC(processedNative);
    final userMFCC = MFCCService.extractMFCC(processedUser);

    double similarity;

    // 3. Algorithmic Comparison
    switch (algorithm) {
      case PronunciationAlgorithm.dtw:
        similarity = _calculateDTWScore(nativeMFCC, userMFCC, strictness);
        break;
      case PronunciationAlgorithm.hmm:
        similarity = _calculateHMMScore(nativeMFCC, userMFCC, strictness);
        break;
      case PronunciationAlgorithm.cosineSimilarity:
        similarity = _calculateCosineScore(nativeMFCC, userMFCC, strictness);
        break;
    }

    final accuracy = similarity;
    final durationRatio = math.min(processedNative.length, processedUser.length) / 
                         math.max(processedNative.length, processedUser.length);
    final fluency = (durationRatio * 0.5 + similarity * 0.5).clamp(0.0, 1.0);
    final clarity = (processedUser.where((v) => v.abs() > 0.05).length / processedUser.length).clamp(0.3, 1.0);

    return PronunciationScore(
      overallScore: similarity * 100,
      accuracy: accuracy,
      fluency: fluency,
      clarity: clarity,
      nativeWaveform: nativeSamples,
      studentWaveform: userSamples,
      feedback: _generateFeedback(similarity),
      algorithmUsed: algorithm,
    );
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

  static double _calculateDTWScore(
    List<List<double>> s, 
    List<List<double>> t, 
    PronunciationStrictness strictness
  ) {
    final distance = MFCCService.calculateMFCCDistance(s, t);
    if (distance == double.infinity) return 0.0;
    return math.exp(-strictness.sensitivity * (distance / 15.0)).clamp(0.0, 1.0);
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
    final n = s.length;
    final m = t.length;
    List<List<double>> dtw = List.generate(n + 1, (_) => List.filled(m + 1, 0.0));

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = 1.0 - _cosineSimilarity(s[i - 1], t[j - 1]);
        if (i == 1 && j == 1) {
          dtw[i][j] = cost;
        } else if (i == 1) {
          dtw[i][j] = cost + dtw[i][j - 1];
        } else if (j == 1) {
          dtw[i][j] = cost + dtw[i - 1][j];
        } else {
          dtw[i][j] = cost + math.min(dtw[i - 1][j], math.min(dtw[i][j - 1], dtw[i - 1][j - 1]));
        }
      }
    }

    final avgDistance = dtw[n][m] / (n + m);
    return math.exp(-strictness.sensitivity * 2.0 * avgDistance).clamp(0.0, 1.0);
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

  static String _generateFeedback(double score) {
    if (score >= 0.85) return "Excellent! Your pronunciation is near-perfect.";
    if (score >= 0.70) return "Great job! Very clear and accurate.";
    if (score >= 0.50) return "Good attempt. Listen closely to the native accent and try again.";
    if (score >= 0.30) return "Understandable, but needs more practice on rhythm.";
    return "Needs improvement. Focus on the individual sounds of the word.";
  }

  static String _getFeedbackKey(double score) {
    if (score >= 0.80) return 'feedback_excellent';
    if (score >= 0.60) return 'feedback_good_effort';
    return 'feedback_needs_work';
  }
}
