import 'dart:math';

enum PronunciationStrictness {
  /// Very forgiving, good for absolute beginners.
  easy(2.5),

  /// Balanced, the default setting.
  normal(5.0),

  /// Strict, requires high precision in rhythm and tone.
  hard(8.5);

  final double sensitivity;
  const PronunciationStrictness(this.sensitivity);
}

class PronunciationService {
  /// Compares two waveforms using Dynamic Time Warping (DTW)
  /// and returns a match score between 0.0 and 1.0.
  static double compareWaveforms(
    List<double> nativeWave,
    List<double> userWave, {
    PronunciationStrictness strictness = PronunciationStrictness.normal,
  }) {
    if (nativeWave.isEmpty || userWave.isEmpty) return 0.0;

    // 1. Normalize both waveforms to 0.0 - 1.0 range
    final normalizedNative = _normalize(nativeWave);
    final normalizedUser = _normalize(userWave);

    // 2. Perform Dynamic Time Warping
    // DTW calculates the "distance" between two time-series patterns.
    // A distance of 0 means they are identical.
    final distance = _calculateDTW(normalizedNative, normalizedUser);

    // 3. Convert distance to a percentage score
    // We normalize the distance by the length of the paths to make it comparable.
    final normalizedDistance = distance / (normalizedNative.length + normalizedUser.length);

    // 4. Map distance to score using the strictness multiplier
    // exp(-S * d) ensures that 0 distance is always 100%.
    // Higher sensitivity (S) makes the score drop faster as distance increases.
    final score = exp(-strictness.sensitivity * normalizedDistance);

    return score.clamp(0.0, 1.0);
  }

  static List<double> _normalize(List<double> wave) {
    if (wave.isEmpty) return [];

    double maxVal = wave.map((e) => e.abs()).reduce(max);
    if (maxVal == 0) return List.filled(wave.length, 0.0);

    return wave.map((e) => e.abs() / maxVal).toList();
  }

  static double _calculateDTW(List<double> s, List<double> t) {
    final n = s.length;
    final m = t.length;

    // Create a cost matrix
    List<List<double>> dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );

    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = (s[i - 1] - t[j - 1]).abs();
        dtw[i][j] = cost + _min3(
          dtw[i - 1][j],     // insertion
          dtw[i][j - 1],     // deletion
          dtw[i - 1][j - 1], // match
        );
      }
    }

    return dtw[n][m];
  }

  static double _min3(double a, double b, double c) {
    return min(a, min(b, c));
  }
}
