import 'dart:math';

/// A service to extract Mel-Frequency Cepstral Coefficients (MFCC) from audio samples.
/// This implementation provides a pure Dart way to analyze audio spectral features.
class MFCCService {
  static const int sampleRate = 16000;
  static const int frameSize = 512;
  static const int frameStride = 256;
  static const int numFilters = 26;
  static const int numCepstral = 13;

  /// Extracts MFCC features from a list of audio samples.
  /// Expects normalized PCM samples (-1.0 to 1.0).
  static List<List<double>> extractMFCC(List<double> samples) {
    if (samples.isEmpty) return [];

    // 1. Pre-emphasis
    final preEmphasized = _preEmphasis(samples);

    // 2. Framing
    final frames = _createFrames(preEmphasized);

    List<List<double>> mfccFeatures = [];

    for (var frame in frames) {
      // 3. Windowing (Hamming)
      final windowedFrame = _applyHammingWindow(frame);

      // 4. Power Spectrum (simplified FFT-like approach for prototype if full FFT is not available)
      // In a real implementation, we'd use a real-to-complex FFT here.
      final powerSpectrum = _calculatePowerSpectrum(windowedFrame);

      // 5. Filter Banks
      final filterBanks = _applyMelFilterBanks(powerSpectrum);

      // 6. Log Filter Banks
      final logFilterBanks = filterBanks.map((e) => log(max(e, 1e-10))).toList();

      // 7. DCT (Discrete Cosine Transform)
      final cepstralCoefficients = _applyDCT(logFilterBanks);

      // Take only the first numCepstral coefficients (usually 13)
      mfccFeatures.add(cepstralCoefficients.take(numCepstral).toList());
    }

    return mfccFeatures;
  }

  static List<double> _preEmphasis(List<double> samples, [double alpha = 0.97]) {
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
    return List.generate(frame.length, (i) {
      double multiplier = 0.54 - 0.46 * cos(2 * pi * i / (frame.length - 1));
      return frame[i] * multiplier;
    });
  }

  /// Simplified Power Spectrum calculation using a basic DFT
  /// Note: For production, a fast FFT implementation is required.
  static List<double> _calculatePowerSpectrum(List<double> frame) {
    int n = frame.length;
    int spectrumSize = n ~/ 2 + 1;
    List<double> powerSpectrum = List.filled(spectrumSize, 0.0);

    // Naive DFT (Slow, but functional for demonstration)
    // Real-world: use an FFT library
    for (int k = 0; k < spectrumSize; k++) {
      double real = 0;
      double imag = 0;
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
    // This is a simplified Mel filter bank application
    // In a real implementation, we would pre-calculate the Mel filters.
    double lowMel = _hzToMel(300);
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
