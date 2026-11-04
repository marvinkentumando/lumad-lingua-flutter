import 'dart:math';

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
/// - Feature normalization: CMVN (Cepstral Mean and Variance Normalization)
/// Total output feature dimension per frame: 39 (13 static + 13 delta + 13 delta-delta).
class MFCCService {
  static const int sampleRate = 16000;
  static const int frameSize = 400; // 25 ms at 16,000 Hz
  static const int frameStride = 160; // 10 ms at 16,000 Hz
  static const int numFilters = 23; // 23 Mel filters
  static const int numCepstral = 13; // 13 MFCC coefficients
  static const double fMinHz = 20.0; // 20 Hz minimum frequency
  static const double preEmphasisAlpha = 0.97;
  static const int deltaWidth = 2; // Delta width = 2

  /// Extracts MFCC features (static + delta + delta-delta with CMVN) from audio samples.
  /// Expects normalized PCM samples (-1.0 to 1.0).
  /// Returns a matrix of shape [T x 39] where T is the number of frames.
  static List<List<double>> extractMFCC(List<double> samples, {bool normalize = true}) {
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

    // 11. Apply CMVN (Cepstral Mean and Variance Normalization)
    return normalize ? _applyCMVN(combinedFeatures) : combinedFeatures;
  }

  /// Normalizes reference and learner features together so clip-specific
  /// normalization cannot erase the acoustic differences between them.
  static List<List<double>> normalizeTogether(List<List<double>> first, List<List<double>> second) {
    if (first.isEmpty || second.isEmpty) return [];
    final combined = _applyCMVN([...first, ...second]);
    return combined;
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

  /// Calculates DTW distance between two MFCC feature sets.
  static double calculateMFCCDistance(List<List<double>> s, List<List<double>> t) {
    final n = s.length;
    final m = t.length;
    if (n == 0 || m == 0) return double.infinity;

    List<List<double>> dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );

    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = _euclideanDistance(s[i - 1], t[j - 1]);
        dtw[i][j] = cost + _min3(
          dtw[i - 1][j],
          dtw[i][j - 1],
          dtw[i - 1][j - 1],
        );
      }
    }

    return dtw[n][m] / (n + m);
  }

  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  static double _min3(double a, double b, double c) => min(a, min(b, c));
}
