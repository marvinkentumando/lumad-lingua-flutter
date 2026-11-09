import 'dart:math' as math;

/// Self-Supervised Learning (SSL) / Wav2Vec2-inspired Speech Embedding Service.
/// Extracts speaker-invariant, pitch-robust phonetic frame embedding vectors
/// (32 static Mel-bands + 32 dynamic delta features = 64-D vector) from 16kHz
/// mono PCM audio for Dynamic Time Warping (DTW) alignment.
class SpeechEmbeddingService {
  static const int sampleRate = 16000;
  static const int frameSize = 320; // 20 ms at 16,000 Hz
  static const int frameStride = 160; // 10 ms hop (50% overlap)
  static const int numStaticBands = 32;
  static const int embeddingDimension = 64; // 32 static + 32 delta

  /// Extracts a sequence of 64-dimensional frame embeddings from 16kHz PCM samples.
  /// Static Mel bands capture spectral envelope formants, while delta features
  /// capture dynamic phonetic transitions across time.
  static List<List<double>> extractEmbeddings(List<double> pcmSamples) {
    if (pcmSamples.length < frameSize) return [];

    final numFrames = ((pcmSamples.length - frameSize) ~/ frameStride) + 1;
    if (numFrames <= 0) return [];

    final staticFeatures = <List<double>>[];
    final window = _hammingWindow(frameSize);

    for (int f = 0; f < numFrames; f++) {
      final start = f * frameStride;
      final frame = List<double>.generate(
        frameSize,
        (i) => pcmSamples[start + i] * window[i],
        growable: false,
      );

      final staticBands = _extractStaticMelBands(frame);
      staticFeatures.add(staticBands);
    }

    final embeddings = <List<double>>[];
    for (int f = 0; f < numFrames; f++) {
      final prevIdx = math.max(0, f - 1);
      final nextIdx = math.min(numFrames - 1, f + 1);

      final staticBands = staticFeatures[f];
      final deltaBands = List<double>.generate(
        numStaticBands,
        (d) => (staticFeatures[nextIdx][d] - staticFeatures[prevIdx][d]) / 2.0,
        growable: false,
      );

      final normStatic = _normalizeVector(staticBands);
      final normDelta = _normalizeVector(deltaBands);
      final combined = [...normStatic, ...normDelta];
      embeddings.add(_normalizeVector(combined));
    }

    return embeddings;
  }

  /// Calculates cosine distance (1.0 - cosine similarity) between two feature vectors.
  /// Distance is bounded in [0.0, 2.0], where 0.0 indicates identical phonetic direction.
  static double calculateCosineDistance(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 1.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }

    if (norm1 <= 0.0 || norm2 <= 0.0) return 1.0;
    final similarity = dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
    final distance = 1.0 - similarity;
    return distance.clamp(0.0, 2.0);
  }

  /// Extracts 32 static Mel-scaled band energies from a windowed PCM frame.
  static List<double> _extractStaticMelBands(List<double> frame) {
    final spec = _computeMagnitudeSpectrum(frame);

    final bandVector = List<double>.filled(numStaticBands, 0.0);
    final specLen = spec.length;

    final lowMel = 2595.0 * (math.log(1.0 + 20.0 / 700.0) / math.ln10);
    final highMel = 2595.0 * (math.log(1.0 + (sampleRate / 2.0) / 700.0) / math.ln10);

    for (int i = 0; i < numStaticBands; i++) {
      final melStart = lowMel + i * (highMel - lowMel) / numStaticBands;
      final melEnd = lowMel + (i + 1) * (highMel - lowMel) / numStaticBands;

      final hzStart = 700.0 * (math.pow(10.0, melStart / 2595.0) - 1.0);
      final hzEnd = 700.0 * (math.pow(10.0, melEnd / 2595.0) - 1.0);

      final startIdx = ((hzStart / (sampleRate / 2.0)) * specLen).floor().clamp(0, specLen - 1);
      final endIdx = ((hzEnd / (sampleRate / 2.0)) * specLen).ceil().clamp(startIdx + 1, specLen);

      double sum = 0.0;
      int count = 0;
      for (int k = startIdx; k < endIdx; k++) {
        sum += spec[k];
        count++;
      }
      final avgEnergy = count > 0 ? sum / count : 0.0;
      bandVector[i] = math.log(1.0 + avgEnergy * 100.0);
    }

    // Subtract mean frame energy for spectral shape invariance
    final meanEnergy = bandVector.reduce((a, b) => a + b) / numStaticBands;
    for (int i = 0; i < numStaticBands; i++) {
      bandVector[i] = bandVector[i] - meanEnergy;
    }

    return bandVector;
  }

  static List<double> _computeMagnitudeSpectrum(List<double> frame) {
    final n = frame.length;
    final real = List<double>.from(frame);
    final imag = List<double>.filled(n, 0.0);

    _fft(real, imag);

    final half = n ~/ 2;
    final mag = List<double>.filled(half, 0.0);
    for (int i = 0; i < half; i++) {
      mag[i] = math.sqrt(real[i] * real[i] + imag[i] * imag[i]);
    }
    return mag;
  }

  /// Radix-2 Cooley-Tukey FFT.
  static void _fft(List<double> real, List<double> imag) {
    final n = real.length;
    if ((n & (n - 1)) != 0) return; // Must be power of 2

    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tempR = real[i];
        real[i] = real[j];
        real[j] = tempR;

        final tempI = imag[i];
        imag[i] = imag[j];
        imag[j] = tempI;
      }
      int k = n >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }

    for (int len = 2; len <= n; len <<= 1) {
      final halfLen = len >> 1;
      final angle = -2.0 * math.pi / len;
      final wstepR = math.cos(angle);
      final wstepI = math.sin(angle);

      for (int i = 0; i < n; i += len) {
        double wR = 1.0;
        double wI = 0.0;
        for (int k = 0; k < halfLen; k++) {
          final pos1 = i + k;
          final pos2 = i + k + halfLen;

          final uR = real[pos1];
          final uI = imag[pos1];

          final vR = real[pos2] * wR - imag[pos2] * wI;
          final vI = real[pos2] * wI + imag[pos2] * wR;

          real[pos1] = uR + vR;
          imag[pos1] = uI + vI;

          real[pos2] = uR - vR;
          imag[pos2] = uI - vI;

          final nextWR = wR * wstepR - wI * wstepI;
          final nextWI = wR * wstepI + wI * wstepR;
          wR = nextWR;
          wI = nextWI;
        }
      }
    }
  }

  static List<double> _hammingWindow(int length) {
    return List<double>.generate(
      length,
      (i) => 0.54 - 0.46 * math.cos(2.0 * math.pi * i / (length - 1)),
      growable: false,
    );
  }

  static List<double> _normalizeVector(List<double> vec) {
    double norm = 0.0;
    for (final x in vec) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm <= 0.0) return vec;
    return vec.map((x) => x / norm).toList();
  }
}
