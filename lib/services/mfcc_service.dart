import 'dart:math';

/// Result of a dynamic-time-warping alignment between two feature sequences.
class DtwAlignment {
  /// Accumulated local cost divided by the total step weight of the optimal
  /// path, i.e. the mean frame-level cost along the alignment.
  final double meanLocalCost;

  /// Maximum local frame-to-frame distance encountered along the optimal path.
  /// Used for local phonetic frame substitution & mismatch detection.
  final double maxLocalCost;

  /// Raw accumulated cost of the optimal path.
  final double totalCost;

  /// Sum of the step weights along the path; used as the normalization term.
  final int pathWeight;

  /// Number of matched frame pairs along the path.
  final int pathLength;

  const DtwAlignment({
    required this.meanLocalCost,
    this.maxLocalCost = 0.0,
    required this.totalCost,
    required this.pathWeight,
    required this.pathLength,
  });

  bool get isUsable => meanLocalCost.isFinite && pathWeight > 0;
}

/// Custom frame-to-frame cost, used by the cosine-similarity candidate.
typedef FrameCostFunction = double Function(List<double> a, List<double> b);

/// Normalization applied to the 39-D frame matrix.
enum MfccNormalization {
  /// No normalization.
  none,

  /// Cepstral mean normalization: subtract each channel's mean over the clip.
  /// Removes channel/gain differences while keeping the spectral envelope.
  cepstralMean,

  /// Mean and variance normalization. Variance scaling removes the spectral
  /// envelope that distinguishes words from each other.
  cepstralMeanVariance,
}

/// A service to extract Mel-Frequency Cepstral Coefficients (MFCC) from audio samples.
/// This implementation provides a pure Dart way to analyze audio spectral features
/// using the approved recommended_v1 configuration:
/// - Sample rate: 16,000 Hz
/// - Frame length: 25 ms (400 samples)
/// - Frame hop: 10 ms (160 samples)
/// - Mel filterbanks: 23
/// - MFCC coefficients: 13 static
/// - Frequency range: 20 Hz to 8,000 Hz (Nyquist)
/// - Pre-emphasis: 0.97
/// - Window function: Hamming
/// - Delta features: Delta (width 2) + Delta-Delta (width 2)
/// - Feature normalization: CMN (Cepstral Mean Normalization)
/// Total output feature dimension per frame: 39 (13 static + 13 delta + 13 delta-delta).
///
/// Mean-only normalization is deliberate. Dividing by each channel's variance
/// (CMVN) scales away the spectral envelope that carries vowel identity, so a
/// different word by the same speaker ends up as close as another native take of
/// the right word. CMN removes channel/gain while keeping that envelope.
class MFCCService {
  static const int sampleRate = 16000;
  static const int frameSize = 400; // 25 ms at 16,000 Hz
  static const int frameStride = 160; // 10 ms at 16,000 Hz
  static const int numFilters = 23; // 23 Mel filters
  static const int numCepstral = 13; // 13 MFCC coefficients
  static const double fMinHz = 20.0; // 20 Hz minimum frequency
  static const double preEmphasisAlpha = 0.97;
  static const int deltaWidth = 2; // Delta width = 2

  /// Sakoe-Chiba band (as a fraction of the sequence length) around the
  /// diagonal. The band stops the alignment from compressing one clip into a
  /// tiny span of the other, which used to produce inflated scores.
  static const double defaultBandRatio = 0.25;

  /// Slope-constrained step pattern (di, dj, weight). Plain {1,0}/{0,1} steps are
  /// deliberately absent: without a slope bound, DTW can map many reference
  /// frames onto one learner frame and report a near-perfect match for the wrong
  /// word. Max length ratio is 3:1 in either direction.
  static const List<List<int>> _dtwSteps = [
    [1, 1, 2],
    [1, 2, 3],
    [2, 1, 3],
    [1, 3, 4],
    [3, 1, 4],
  ];

  /// Extracts MFCC features (static + delta + delta-delta) from audio samples.
  /// Expects normalized PCM samples (-1.0 to 1.0).
  /// Returns a matrix of shape [T x 39] where T is the number of frames.
  static List<List<double>> extractMFCC(
    List<double> samples, {
    MfccNormalization normalization = MfccNormalization.cepstralMean,
  }) {
    if (samples.isEmpty) return [];

    // Sanitize input samples (replace non-finite values with 0.0)
    final sanitized = samples.map((s) => s.isFinite ? s : 0.0).toList();

    // 1. Pre-emphasis (alpha = 0.97)
    final preEmphasized = _preEmphasis(sanitized, preEmphasisAlpha);

    // 2. Framing (frameSize = 400, frameStride = 160)
    final frames = _createFrames(preEmphasized);
    if (frames.isEmpty) return [];

    List<List<double>> staticMFCCs = [];

    for (var frame in frames) {
      // 3. Windowing (Hamming)
      final windowedFrame = _applyHammingWindow(frame);

      // 4. Power Spectrum (FFT / DFT)
      final powerSpectrum = _calculatePowerSpectrum(windowedFrame);

      // 5. Filter Banks (23 Mel filters, 20 Hz to 8000 Hz)
      final filterBanks = _applyMelFilterBanks(powerSpectrum);

      // 6. Log Filter Banks
      final logFilterBanks = filterBanks.map((e) => log(max(e, 1e-10))).toList();

      // 7. DCT (Discrete Cosine Transform)
      final cepstralCoefficients = _applyDCT(logFilterBanks);

      // Take only the first numCepstral coefficients (13)
      staticMFCCs.add(cepstralCoefficients.take(numCepstral).toList());
    }

    if (staticMFCCs.isEmpty) return [];

    // 8. Compute Delta features (delta width = 2)
    final delta1 = _computeDeltas(staticMFCCs, deltaWidth);

    // 9. Compute Delta-Delta (Acceleration) features (delta width = 2)
    final delta2 = _computeDeltas(delta1, deltaWidth);

    // 10. Concatenate static (13), delta (13), and delta-delta (13) -> 39 features/frame
    List<List<double>> combinedFeatures = [];
    for (int t = 0; t < staticMFCCs.length; t++) {
      combinedFeatures.add([
        ...staticMFCCs[t],
        ...delta1[t],
        ...delta2[t],
      ]);
    }

    // 11. Apply the requested cepstral normalization
    switch (normalization) {
      case MfccNormalization.none:
        return combinedFeatures;
      case MfccNormalization.cepstralMean:
        return _applyCMN(combinedFeatures);
      case MfccNormalization.cepstralMeanVariance:
        return _applyCMVN(combinedFeatures);
    }
  }

  static List<double> _preEmphasis(List<double> samples, double alpha) {
    if (samples.isEmpty) return [];
    List<double> result = List.filled(samples.length, 0.0);
    result[0] = samples[0];
    for (int i = 1; i < samples.length; i++) {
      result[i] = samples[i] - alpha * samples[i - 1];
    }
    return result;
  }

  static List<List<double>> _createFrames(List<double> samples) {
    List<List<double>> frames = [];
    for (int i = 0; i <= samples.length - frameSize; i += frameStride) {
      frames.add(samples.sublist(i, i + frameSize));
    }
    return frames;
  }

  static List<double> _applyHammingWindow(List<double> frame) {
    final length = frame.length;
    if (length <= 1) return List.from(frame);
    return List.generate(length, (i) {
      double multiplier = 0.54 - 0.46 * cos(2 * pi * i / (length - 1));
      return frame[i] * multiplier;
    });
  }

  static List<double> _calculatePowerSpectrum(List<double> frame) {
    int n = frame.length;
    int spectrumSize = n ~/ 2 + 1;
    List<double> powerSpectrum = List.filled(spectrumSize, 0.0);

    for (int k = 0; k < spectrumSize; k++) {
      double real = 0.0;
      double imag = 0.0;
      for (int t = 0; t < n; t++) {
        double angle = 2 * pi * k * t / n;
        real += frame[t] * cos(angle);
        imag -= frame[t] * sin(angle);
      }
      powerSpectrum[k] = (real * real + imag * imag) / n;
    }
    return powerSpectrum;
  }

  static List<double> _applyMelFilterBanks(List<double> powerSpectrum) {
    double lowMel = _hzToMel(fMinHz);
    double highMel = _hzToMel(sampleRate / 2);

    List<double> melPoints = List.generate(numFilters + 2, (i) {
      return _melToHz(lowMel + i * (highMel - lowMel) / (numFilters + 1));
    });

    List<int> binPoints = melPoints.map((hz) => ((frameSize + 1) * hz / sampleRate).floor()).toList();

    List<double> filterBanks = List.filled(numFilters, 0.0);
    for (int i = 1; i <= numFilters; i++) {
      for (int j = binPoints[i - 1]; j < binPoints[i]; j++) {
        filterBanks[i - 1] += powerSpectrum[j] * (j - binPoints[i - 1]) / (binPoints[i] - binPoints[i - 1]);
      }
      for (int j = binPoints[i]; j < binPoints[i + 1]; j++) {
        filterBanks[i - 1] += powerSpectrum[j] * (binPoints[i + 1] - j) / (binPoints[i + 1] - binPoints[i]);
      }
    }
    return filterBanks;
  }

  static double _hzToMel(double hz) => 2595 * log10(1 + hz / 700);
  static double _melToHz(double mel) => 700 * (pow(10, mel / 2595) - 1);
  static double log10(num x) => log(x) / ln10;

  static List<double> _applyDCT(List<double> data) {
    int n = data.length;
    List<double> result = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0;
      for (int j = 0; j < n; j++) {
        sum += data[j] * cos(pi * i * (j + 0.5) / n);
      }
      result[i] = sum;
    }
    return result;
  }

  /// Computes delta coefficients for feature matrix with specified width (default = 2).
  static List<List<double>> _computeDeltas(List<List<double>> features, int width) {
    if (features.isEmpty) return [];

    final numFrames = features.length;
    final numFeatures = features[0].length;
    final deltas = List.generate(
      numFrames,
      (_) => List<double>.filled(numFeatures, 0.0),
    );

    double denominator = 0.0;
    for (int n = 1; n <= width; n++) {
      denominator += n * n;
    }
    denominator *= 2.0;

    for (int t = 0; t < numFrames; t++) {
      for (int d = 0; d < numFeatures; d++) {
        double sum = 0.0;
        for (int n = 1; n <= width; n++) {
          final posIndex = (t + n).clamp(0, numFrames - 1);
          final negIndex = (t - n).clamp(0, numFrames - 1);
          sum += n * (features[posIndex][d] - features[negIndex][d]);
        }
        final val = sum / denominator;
        deltas[t][d] = val.isFinite ? val : 0.0;
      }
    }

    return deltas;
  }

  /// Applies Cepstral Mean Normalization (CMN) across frames: each channel's
  /// mean over the clip is removed, its variance is preserved.
  static List<List<double>> _applyCMN(List<List<double>> featureMatrix) {
    if (featureMatrix.isEmpty) return [];

    final numFrames = featureMatrix.length;
    final numFeatures = featureMatrix[0].length;
    final normalized = List.generate(
      numFrames,
      (_) => List<double>.filled(numFeatures, 0.0),
    );

    for (int d = 0; d < numFeatures; d++) {
      double sum = 0.0;
      for (int t = 0; t < numFrames; t++) {
        sum += featureMatrix[t][d];
      }
      final mean = sum / numFrames;

      for (int t = 0; t < numFrames; t++) {
        final val = featureMatrix[t][d] - mean;
        normalized[t][d] = val.isFinite ? val : 0.0;
      }
    }

    return normalized;
  }

  /// Applies Cepstral Mean and Variance Normalization (CMVN) across frames.
  static List<List<double>> _applyCMVN(List<List<double>> featureMatrix) {
    if (featureMatrix.isEmpty) return [];

    final numFrames = featureMatrix.length;
    final numFeatures = featureMatrix[0].length;
    final normalized = List.generate(
      numFrames,
      (_) => List<double>.filled(numFeatures, 0.0),
    );

    const double epsilon = 1e-10;

    for (int d = 0; d < numFeatures; d++) {
      double sum = 0.0;
      for (int t = 0; t < numFrames; t++) {
        sum += featureMatrix[t][d];
      }
      final mean = sum / numFrames;

      double sumSqDiff = 0.0;
      for (int t = 0; t < numFrames; t++) {
        final diff = featureMatrix[t][d] - mean;
        sumSqDiff += diff * diff;
      }
      final variance = sumSqDiff / numFrames;
      final stdDev = sqrt(variance + epsilon);

      for (int t = 0; t < numFrames; t++) {
        final val = (featureMatrix[t][d] - mean) / stdDev;
        normalized[t][d] = val.isFinite ? val : 0.0;
      }
    }

    return normalized;
  }

  /// Banded, slope-constrained DTW alignment normalized by the path's total
  /// step weight (not by `n + m`).
  ///
  /// The previous `dtw[n][m] / (n + m)` divided by a path length that the real
  /// alignment never reaches, so mean frame cost was under-estimated, and it was
  /// under-estimated *more* for longer attempts - slow recordings were rewarded.
  static DtwAlignment align(
    List<List<double>> s,
    List<List<double>> t, {
    double bandRatio = defaultBandRatio,
    FrameCostFunction? frameCost,
  }) {
    final n = s.length;
    final m = t.length;
    if (n == 0 || m == 0) {
      return const DtwAlignment(
        meanLocalCost: double.infinity,
        totalCost: double.infinity,
        pathWeight: 0,
        pathLength: 0,
      );
    }

    final cost = List.generate(n + 1, (_) => List<double>.filled(m + 1, double.infinity));
    final weight = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    final pathLength = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    final maxFrameCost = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0.0));
    cost[0][0] = 0.0;

    for (int i = 1; i <= n; i++) {
      final progress = i / n;
      final jStart = max(1, ((progress - bandRatio) * m).ceil());
      final jEnd = min(m, ((progress + bandRatio) * m).floor());
      if (jStart > jEnd) continue;

      for (int j = jStart; j <= jEnd; j++) {
        final localCost = frameCost != null
            ? frameCost(s[i - 1], t[j - 1])
            : _euclideanDistance(s[i - 1], t[j - 1]);
        if (!localCost.isFinite) continue;

        var bestCost = double.infinity;
        var bestWeight = 0;
        var bestLength = 0;
        var bestMaxLocal = 0.0;

        for (final step in _dtwSteps) {
          final di = step[0];
          final dj = step[1];
          final stepWeight = step[2];
          final previousI = i - di;
          final previousJ = j - dj;
          if (previousI < 0 || previousJ < 0) continue;

          final previousCost = cost[previousI][previousJ];
          if (!previousCost.isFinite) continue;

          final candidate = previousCost + stepWeight * localCost;
          if (candidate < bestCost) {
            bestCost = candidate;
            bestWeight = weight[previousI][previousJ] + stepWeight;
            bestLength = pathLength[previousI][previousJ] + 1;
            bestMaxLocal = max(maxFrameCost[previousI][previousJ], localCost);
          }
        }

        if (!bestCost.isFinite || bestWeight == 0) continue;
        cost[i][j] = bestCost;
        weight[i][j] = bestWeight;
        pathLength[i][j] = bestLength;
        maxFrameCost[i][j] = bestMaxLocal;
      }
    }

    if (!cost[n][m].isFinite || weight[n][m] == 0) {
      return const DtwAlignment(
        meanLocalCost: double.infinity,
        maxLocalCost: double.infinity,
        totalCost: double.infinity,
        pathWeight: 0,
        pathLength: 0,
      );
    }

    return DtwAlignment(
      meanLocalCost: cost[n][m] / weight[n][m],
      maxLocalCost: maxFrameCost[n][m],
      totalCost: cost[n][m],
      pathWeight: weight[n][m],
      pathLength: pathLength[n][m],
    );
  }

  /// Calculates the path-normalized DTW distance between two MFCC feature sets.
  static double calculateMFCCDistance(List<List<double>> s, List<List<double>> t) {
    return align(s, t).meanLocalCost;
  }

  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }
}
