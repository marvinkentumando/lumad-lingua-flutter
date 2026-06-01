import 'dart:math';
import 'mfcc_service.dart';

enum PronunciationStrictness {
  /// Very forgiving, good for absolute beginners.
  easy(1.5), // Adjusted for MFCC distance scales

  /// Balanced, the default setting.
  normal(3.0),

  /// Strict, requires high precision in rhythm and tone.
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

  PronunciationScore({
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.clarity,
    required this.nativeWaveform,
    required this.studentWaveform,
    this.feedback = "",
  });
}

class PronunciationService {
  /// Compares two waveforms and returns a detailed analysis score.
  static PronunciationScore analyzePronunciation(
    List<double> nativeSamples,
    List<double> userSamples, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
  }) {
    // If the data looks like volume peaks (mostly positive, low count), use Envelope Comparison
    // Otherwise, attempt MFCC (though UI currently provides peaks)
    final bool isEnvelope = _isVolumeEnvelope(nativeSamples);

    double overallMatch;
    if (isEnvelope) {
      overallMatch = _compareEnvelopes(nativeSamples, userSamples, strictness);
    } else {
      // Fallback/Standard MFCC
      final nativeMFCC = MFCCService.extractMFCC(nativeSamples);
      final userMFCC = MFCCService.extractMFCC(userSamples);
      final mfccDistance = MFCCService.calculateMFCCDistance(nativeMFCC, userMFCC);
      overallMatch = exp(-strictness.sensitivity * (mfccDistance / 20.0)).clamp(0.0, 1.0);
    }

    // 3. Heuristic-based metrics
    final accuracy = overallMatch;
    final durationRatio = min(nativeSamples.length, userSamples.length) / max(nativeSamples.length, userSamples.length);
    final fluency = (durationRatio * 0.6 + overallMatch * 0.4).clamp(0.0, 1.0);
    final clarity = (userSamples.where((v) => v.abs() > 0.05).length / (userSamples.isEmpty ? 1 : userSamples.length)).clamp(0.3, 1.0);

    return PronunciationScore(
      overallScore: overallMatch * 100,
      accuracy: accuracy,
      fluency: fluency,
      clarity: clarity,
      nativeWaveform: nativeSamples,
      studentWaveform: userSamples,
      feedback: _generateFeedback(overallMatch),
    );
  }

  static bool _isVolumeEnvelope(List<double> samples) {
    if (samples.isEmpty) return false;
    // Heuristic: Peaks from audio_waveforms are mostly positive and sparse
    int positiveCount = samples.where((s) => s >= 0).length;
    return (positiveCount / samples.length) > 0.9;
  }

  /// Direct DTW comparison for volume envelopes (peaks)
  static double _compareEnvelopes(List<double> s, List<double> t, PronunciationStrictness strictness) {
    if (s.isEmpty || t.isEmpty) return 0.0;

    // Normalize amplitudes to 0.0 - 1.0 for fair volume comparison
    final maxS = s.fold(0.01, max);
    final maxT = t.fold(0.01, max);
    final normS = s.map((v) => v / maxS).toList();
    final normT = t.map((v) => v / maxT).toList();

    // 1D Dynamic Time Warping
    final n = normS.length;
    final m = normT.length;
    List<List<double>> dtw = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = (normS[i - 1] - normT[j - 1]).abs();
        dtw[i][j] = cost + min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
      }
    }

    final distance = dtw[n][m] / (n + m);
    // Adjusted scoring curve for envelope distance
    return exp(-strictness.sensitivity * distance).clamp(0.0, 1.0);
  }

  /// Compatibility method for existing waveform comparison.
  static double compareWaveforms(
    List<double> nativeWave,
    List<double> userWave, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
  }) {
    if (nativeWave.isEmpty || userWave.isEmpty) return 0.0;
    
    final result = analyzePronunciation(nativeWave, userWave, strictness: strictness);
    return result.overallScore / 100;
  }

  static String _generateFeedback(double score) {
    if (score >= 0.8) return "Excellent! Your pronunciation is very close to the native speaker.";
    if (score >= 0.6) return "Good job! You're understandable, but watch your vowel clarity.";
    if (score >= 0.4) return "Fair. Try listening to the native speaker again and focus on the rhythm.";
    return "Needs improvement. Keep practicing the specific sounds of this word.";
  }
}
