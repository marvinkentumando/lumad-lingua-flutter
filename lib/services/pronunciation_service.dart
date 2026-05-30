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
    // 1. MFCC Analysis
    final nativeMFCC = MFCCService.extractMFCC(nativeSamples);
    final userMFCC = MFCCService.extractMFCC(userSamples);

    final mfccDistance = MFCCService.calculateMFCCDistance(nativeMFCC, userMFCC);

    // 2. Convert MFCC distance to 0.0 - 1.0 score
    // MFCC distance is usually higher than raw waveform distance, so we adjust mapping
    final overallMatch = exp(-strictness.sensitivity * mfccDistance).clamp(0.0, 1.0);

    // 3. Heuristic-based metrics
    final accuracy = overallMatch;
    
    // Fluency: Compare relative duration and MFCC stability
    final durationRatio = min(nativeSamples.length, userSamples.length) / max(nativeSamples.length, userSamples.length);
    final fluency = (durationRatio * 0.7 + (1.0 - min(mfccDistance, 1.0)) * 0.3).clamp(0.0, 1.0);
    
    // Clarity: Based on spectral energy distribution (simplified)
    final clarity = (userSamples.where((v) => v.abs() > 0.1).length / (userSamples.isEmpty ? 1 : userSamples.length)).clamp(0.4, 1.0);

    // 4. Generate Feedback
    String feedback = _generateFeedback(overallMatch);

    return PronunciationScore(
      overallScore: overallMatch * 100,
      accuracy: accuracy,
      fluency: fluency,
      clarity: clarity,
      nativeWaveform: nativeSamples,
      studentWaveform: userSamples,
      feedback: feedback,
    );
  }

  /// Compatibility method for existing waveform comparison, now upgraded to MFCC.
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
