import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Thrown when audio bytes cannot be interpreted as PCM audio.
class WavDecodeException implements Exception {
  final String message;
  const WavDecodeException(this.message);

  @override
  String toString() => 'WavDecodeException: $message';
}

class WavDecodeResult {
  final List<double> pcmSamples; // Normalized -1.0 to 1.0 mono PCM at 16,000 Hz
  final int sampleRate;
  final int channels;
  final double durationSeconds;

  WavDecodeResult({
    required this.pcmSamples,
    required this.sampleRate,
    required this.channels,
    required this.durationSeconds,
  });
}

class SignalAnalysisResult {
  final bool isEmptyOrInvalid;
  final double peakAmplitude;
  final double rms;
  final bool isSilent;
  final bool isQuiet;
  final bool isClipped;
  final bool isHighNoise;
  final bool isExcessivePause;
  final bool hasNoSpeech;

  SignalAnalysisResult({
    required this.isEmptyOrInvalid,
    required this.peakAmplitude,
    required this.rms,
    required this.isSilent,
    required this.isQuiet,
    this.isClipped = false,
    this.isHighNoise = false,
    this.isExcessivePause = false,
    this.hasNoSpeech = false,
  });
}

class WavDecoder {
  static const int targetSampleRate = 16000;
  static const int minimumComparisonSamples = targetSampleRate * 35 ~/ 100;
  static const double targetRmsLinear = 0.10; // -20 dBFS
  static const double peakCeilingLinear = 0.8912509; // -1 dBFS
  static const double maxGainLinear = 31.6227766; // 30 dB

  /// Candidate silent peak threshold (-40 dBFS linear = 0.008)
  static const double candidateSilentPeakThreshold = 0.008;

  /// Candidate silent RMS threshold (-52 dBFS linear = 0.0025)
  static const double candidateSilentRmsThreshold = 0.0025;

  /// Candidate quiet peak threshold (-26 dBFS linear = 0.050)
  static const double candidateQuietPeakThreshold = 0.050;

  /// Analyzes raw 16kHz mono PCM samples to evaluate peak amplitude, RMS, and signal validity.
  static SignalAnalysisResult analyzeSignal(List<double> samples) {
    if (samples.isEmpty) {
      return SignalAnalysisResult(
        isEmptyOrInvalid: true,
        peakAmplitude: 0.0,
        rms: 0.0,
        isSilent: true,
        isQuiet: false,
      );
    }

    double maxAbs = 0.0;
    double sumSquares = 0.0;
    int clippedCount = 0;

    for (var s in samples) {
      if (!s.isFinite) {
        return SignalAnalysisResult(
          isEmptyOrInvalid: true,
          peakAmplitude: 0.0,
          rms: 0.0,
          isSilent: true,
          isQuiet: false,
        );
      }
      final absVal = s.abs();
      if (absVal > maxAbs) maxAbs = absVal;
      sumSquares += absVal * absVal;

      if (absVal >= 0.995) clippedCount++;
    }

    final rms = math.sqrt(sumSquares / samples.length);

    final isSilent = maxAbs < candidateSilentPeakThreshold && rms < candidateSilentRmsThreshold;
    final isQuiet = !isSilent && maxAbs < candidateQuietPeakThreshold;

    // 1. Audio Clipping & Distortion (>1% of samples at max ceiling)
    final isClipped = (clippedCount / samples.length) >= 0.01;

    // 2. High Background Noise / Low Signal-to-Noise Ratio (SNR < 6dB).
    // The noise floor is estimated from a low percentile of the whole clip's
    // 20 ms frame energies. Using a fixed leading window (the previous
    // behaviour) treated the first phoneme as noise whenever the learner
    // started speaking immediately, which rejected valid recordings.
    final frameRmsValues = _frameRmsValues(samples, 320);
    final noiseFloorRms = _percentile(frameRmsValues, 0.20);
    final speechFrameRms = math.max(_percentile(frameRmsValues, 0.90), noiseFloorRms);
    final snrDb = noiseFloorRms > 0
        ? 20.0 * (math.log(speechFrameRms / noiseFloorRms) / math.ln10)
        : 60.0;
    final isHighNoise = !isSilent && noiseFloorRms > 0.035 && snrDb < 6.0;

    // 3. Excessive Internal Pauses / Hesitation (>1.5s silent gap between speech)
    bool isExcessivePause = false;
    const frameSize = 320; // 20ms frame
    final numFrames = samples.length ~/ frameSize;
    int firstActiveFrame = -1;
    int lastActiveFrame = -1;

    List<bool> frameActive = List.filled(numFrames, false);
    for (int f = 0; f < numFrames; f++) {
      double framePower = 0.0;
      for (int i = f * frameSize; i < (f + 1) * frameSize; i++) {
        framePower += samples[i] * samples[i];
      }
      final frameRms = math.sqrt(framePower / frameSize);
      if (frameRms >= candidateSilentRmsThreshold * 2) {
        frameActive[f] = true;
        if (firstActiveFrame == -1) firstActiveFrame = f;
        lastActiveFrame = f;
      }
    }

    if (firstActiveFrame != -1 && lastActiveFrame > firstActiveFrame) {
      int maxConsecutiveSilentFrames = 0;
      int currentSilentCount = 0;
      for (int f = firstActiveFrame; f <= lastActiveFrame; f++) {
        if (!frameActive[f]) {
          currentSilentCount++;
          if (currentSilentCount > maxConsecutiveSilentFrames) {
            maxConsecutiveSilentFrames = currentSilentCount;
          }
        } else {
          currentSilentCount = 0;
        }
      }
      // 75 frames of 20ms = 1.5 seconds
      if (maxConsecutiveSilentFrames >= 75) {
        isExcessivePause = true;
      }
    }

    // 4. Speech Presence Verification (VAD). Rejects stationary noise and, more
    // strongly than before, modulated/non-stationary noise that carries energy but
    // lacks the spectral structure of speech (taps, TV/music bursts, rustle).
    // Checks are intentionally conservative to keep breathy/fricative onsets.
    bool hasNoSpeech = false;
    if (!isSilent) {
      final speechThreshold = math.max(candidateSilentRmsThreshold * 2.5, noiseFloorRms * 2.2);
      int activeSpeechFrames = 0;
      for (int f = 0; f < numFrames; f++) {
        double framePower = 0.0;
        for (int i = f * frameSize; i < (f + 1) * frameSize; i++) {
          framePower += samples[i] * samples[i];
        }
        final frameRms = math.sqrt(framePower / frameSize);
        if (frameRms >= speechThreshold) {
          activeSpeechFrames++;
        }
      }

      final activeSpeechSec = (activeSpeechFrames * frameSize) / targetSampleRate;
      final peakToNoiseRatio = noiseFloorRms > 0 ? (maxAbs / noiseFloorRms) : 10.0;

      int activeFrameCount = 0;
      double activeFrameRmsSum = 0.0;
      double activeFrameRmsSquaredSum = 0.0;
      double activeZeroCrossings = 0.0;
      int activeZeroCrossingFrames = 0;
      // Speech-likeness via spectral flatness: speech has harmonic/formant peaks
      // (low flatness); broadband noise is spectrally flat (high flatness).
      int speechLikeFrames = 0;
      int contiguousSpeechLike = 0;
      int maxContiguousSpeechLike = 0;
      double speechLikeFlatnessSum = 0.0;

      for (int f = 0; f < numFrames; f++) {
        if (!frameActive[f]) {
          contiguousSpeechLike = 0;
          continue;
        }
        final start = f * frameSize;
        double framePower = 0.0;
        int crossings = 0;
        for (int i = start; i < start + frameSize; i++) {
          framePower += samples[i] * samples[i];
          if (i < start + frameSize - 1 &&
              ((samples[i] >= 0 && samples[i + 1] < 0) ||
                  (samples[i] < 0 && samples[i + 1] >= 0))) {
            crossings++;
          }
        }
        final frameRms = math.sqrt(framePower / frameSize);
        activeFrameCount++;
        activeFrameRmsSum += frameRms;
        activeFrameRmsSquaredSum += frameRms * frameRms;
        activeZeroCrossings += crossings / frameSize;
        activeZeroCrossingFrames++;

        final flatness = _spectralFlatness(samples, start, frameSize);
        // A frame is speech-like if it is not broadband-flat noise. Unvoiced
        // fricatives can be flatter, so the threshold is permissive and we
        // require evidence in aggregate, not on every frame.
        final speechLike = frameRms >= speechThreshold * 0.60 && flatness < 0.72;
        if (speechLike) {
          speechLikeFrames++;
          speechLikeFlatnessSum += flatness;
          contiguousSpeechLike++;
          if (contiguousSpeechLike > maxContiguousSpeechLike) {
            maxContiguousSpeechLike = contiguousSpeechLike;
          }
        } else {
          contiguousSpeechLike = 0;
        }
      }

      final meanActiveRms = activeFrameRmsSum / math.max(1, activeFrameCount);
      final activeRmsVariance = math.max(
        0.0,
        activeFrameRmsSquaredSum / math.max(1, activeFrameCount) - meanActiveRms * meanActiveRms,
      );
      final activeRmsCv = meanActiveRms > 0 ? math.sqrt(activeRmsVariance) / meanActiveRms : 0.0;
      final meanActiveZcr = activeZeroCrossings / math.max(1, activeZeroCrossingFrames);
      final likelyStationaryNoise = activeSpeechSec > 0.4 && activeRmsCv < 0.08 && meanActiveZcr > 0.22;

      final speechLikeSec = (speechLikeFrames * frameSize) / targetSampleRate;
      final maxContiguousSpeechLikeSec = (maxContiguousSpeechLike * frameSize) / targetSampleRate;
      final meanSpeechLikeFlatness = speechLikeFrames > 0 ? speechLikeFlatnessSum / speechLikeFrames : 1.0;
      // Modulated noise: enough energy overall but too few/too scattered
      // speech-like frames, or the "speech-like" frames are still rather flat.
      final likelyModulatedNoise = activeFrameCount >= 10 &&
          speechLikeSec < 0.10 &&
          activeSpeechSec > 0.18;
      final weakSpeechEvidence = activeFrameCount >= 15 &&
          maxContiguousSpeechLikeSec < 0.08 &&
          meanSpeechLikeFlatness > 0.58;

      if (activeSpeechSec < 0.12 ||
          peakToNoiseRatio < 2.0 ||
          likelyStationaryNoise ||
          likelyModulatedNoise ||
          weakSpeechEvidence) {
        hasNoSpeech = true;
      }
    }

    return SignalAnalysisResult(
      isEmptyOrInvalid: false,
      peakAmplitude: maxAbs,
      rms: rms,
      isSilent: isSilent,
      isQuiet: isQuiet,
      isClipped: isClipped,
      isHighNoise: isHighNoise,
      isExcessivePause: isExcessivePause,
      hasNoSpeech: hasNoSpeech,
    );
  }


  /// Spectral flatness (Wiener entropy) of one frame: geometric mean / arithmetic
  /// mean of the power spectrum in [0, 1]. Values near 1 indicate noise-like flat
  /// spectra; speech (harmonic/formant structure) is lower. Uses a 256-point
  /// radix-2 FFT over the frame (or a prefix of it).
  static double _spectralFlatness(List<double> samples, int start, int frameSize) {
    const n = 256;
    final real = List<double>.filled(n, 0.0);
    final imag = List<double>.filled(n, 0.0);
    final count = math.min(frameSize, n);
    if (start + count > samples.length || count <= 0) return 1.0;
    for (int i = 0; i < count; i++) {
      // Hann window reduces leakage so flatness reflects structure, not edges.
      final w = 0.5 - 0.5 * math.cos(2 * math.pi * i / math.max(1, count - 1));
      real[i] = samples[start + i] * w;
    }
    _fftInPlace(real, imag);

    final bins = n ~/ 2;
    const epsilon = 1e-12;
    double logSum = 0.0;
    double linearSum = 0.0;
    int used = 0;
    for (int k = 1; k < bins; k++) {
      // skip DC; focus on speech band up to ~Nyquist of interest
      final power = real[k] * real[k] + imag[k] * imag[k] + epsilon;
      logSum += math.log(power);
      linearSum += power;
      used++;
    }
    if (used == 0 || linearSum <= 0) return 1.0;
    final geometric = math.exp(logSum / used);
    final arithmetic = linearSum / used;
    final flatness = geometric / (arithmetic + epsilon);
    return flatness.isFinite ? flatness.clamp(0.0, 1.0) : 1.0;
  }

  /// In-place radix-2 Cooley–Tukey FFT. [real] length must be a power of two.
  static void _fftInPlace(List<double> real, List<double> imag) {
    final n = real.length;
    // bit-reversal permutation
    int j = 0;
    for (int i = 1; i < n; i++) {
      int bit = n >> 1;
      while (j & bit != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final tr = real[i]; real[i] = real[j]; real[j] = tr;
        final ti = imag[i]; imag[i] = imag[j]; imag[j] = ti;
      }
    }
    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wlenR = math.cos(ang);
      final wlenI = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double wR = 1.0;
        double wI = 0.0;
        for (int k = 0; k < len ~/ 2; k++) {
          final uR = real[i + k];
          final uI = imag[i + k];
          final vR = real[i + k + len ~/ 2] * wR - imag[i + k + len ~/ 2] * wI;
          final vI = real[i + k + len ~/ 2] * wI + imag[i + k + len ~/ 2] * wR;
          real[i + k] = uR + vR;
          imag[i + k] = uI + vI;
          real[i + k + len ~/ 2] = uR - vR;
          imag[i + k + len ~/ 2] = uI - vI;
          final nextWR = wR * wlenR - wI * wlenI;
          wI = wR * wlenI + wI * wlenR;
          wR = nextWR;
        }
      }
    }
  }

  /// RMS energy of consecutive fixed-size frames.
  static List<double> _frameRmsValues(List<double> samples, int frameSize) {
    if (samples.isEmpty || frameSize <= 0) return const [];
    final values = <double>[];
    for (int i = 0; i + frameSize <= samples.length; i += frameSize) {
      double sum = 0.0;
      for (int j = i; j < i + frameSize; j++) {
        sum += samples[j] * samples[j];
      }
      values.add(math.sqrt(sum / frameSize));
    }
    return values;
  }

  /// Linear-interpolated percentile of [values] (0.0 - 1.0).
  static double _percentile(List<double> values, double fraction) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final position = (sorted.length - 1) * fraction.clamp(0.0, 1.0);
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    final weight = position - lower;
    return sorted[lower] * (1.0 - weight) + sorted[upper] * weight;
  }

  /// Reads a 16-bit PCM WAV file and decodes it to 16kHz mono `List<double>` samples.
  static Future<WavDecodeResult> decodeWavFile(File file) async {
    final bytes = await file.readAsBytes();
    return decodeWavBytes(bytes);
  }

  /// True when [bytes] already carries a RIFF/WAVE header.
  static bool isRiffWaveBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE';
  }

  /// True when [bytes] is a compressed container whose payload is not PCM
  /// (WebM/Matroska from browser recorders, Ogg/Opus, MP4/M4A, MP3).
  static bool isCompressedContainer(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // Matroska / WebM EBML signature
    if (bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3) {
      return true;
    }
    // Ogg / Opus / Vorbis
    if (String.fromCharCodes(bytes.sublist(0, 4)) == 'OggS') return true;
    // MP4 / M4A: 'ftyp' box type at offset 4
    if (String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') return true;
    // MP3 with an ID3 tag, or a raw MPEG audio frame sync word
    if (String.fromCharCodes(bytes.sublist(0, 3)) == 'ID3') return true;
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) return true;
    return false;
  }

  /// Ensures audio bytes have a valid RIFF/WAVE header.
  ///
  /// Only uncompressed PCM payloads may be wrapped. Compressed containers
  /// (WebM/Opus from a browser, M4A/AAC from mobile) must be decoded first -
  /// wrapping their bitstream in a PCM header produces noise, not audio, which
  /// silently turns every comparison into a meaningless score.
  static Uint8List ensureWavBytes(Uint8List bytes, {int sampleRate = targetSampleRate, int channels = 1}) {
    if (isRiffWaveBytes(bytes)) return bytes;
    if (isCompressedContainer(bytes)) {
      throw const WavDecodeException(
        'Compressed audio container detected. Decode it to PCM (for example with the '
        'Web Audio decoder) instead of wrapping it as raw 16-bit PCM.',
      );
    }
    return createWavHeader(bytes, sampleRate: sampleRate, numChannels: channels, bitsPerSample: 16);
  }

  /// Decodes any supported in-memory payload into 16 kHz mono PCM.
  ///
  /// WAV (PCM/float) is parsed directly and headerless 16-bit PCM is accepted as
  /// raw 16 kHz mono. Compressed containers are rejected with a
  /// [WavDecodeException]; platform decoders must convert those to PCM first.
  static WavDecodeResult decodeAudioBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const WavDecodeException('Audio payload is empty.');
    }
    if (isRiffWaveBytes(bytes)) return decodeWavBytes(bytes);
    if (isCompressedContainer(bytes)) {
      throw const WavDecodeException(
        'Compressed audio container detected. Platform decoding to PCM is required before comparison.',
      );
    }
    return decodeWavBytes(createWavHeader(bytes));
  }

  /// Creates a valid 44-byte RIFF/WAVE header for raw 16-bit PCM bytes at target sample rate.
  static Uint8List createWavHeader(
    Uint8List pcmBytes, {
    int sampleRate = targetSampleRate,
    int numChannels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmBytes.length;
    final chunkSize = 36 + dataSize;

    final header = ByteData(44);

    // 'RIFF'
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, chunkSize, Endian.little);
    // 'WAVE'
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // 'fmt '
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // 'data'
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final builder = BytesBuilder();
    builder.add(header.buffer.asUint8List());
    builder.add(pcmBytes);
    return builder.toBytes();
  }

  /// Decodes raw 16-bit PCM WAV bytes into 16kHz mono `List<double>` samples.
  static WavDecodeResult decodeWavBytes(Uint8List bytes) {
    if (bytes.length < 44) {
      throw Exception('Invalid WAV: file header is too short (${bytes.length} bytes)');
    }

    // Validate RIFF header
    final riffHeader = String.fromCharCodes(bytes.sublist(0, 4));
    if (riffHeader != 'RIFF') {
      throw Exception('Invalid WAV: missing RIFF header signature');
    }

    final waveHeader = String.fromCharCodes(bytes.sublist(8, 12));
    if (waveHeader != 'WAVE') {
      throw Exception('Invalid WAV: missing WAVE format signature');
    }

    // Locate 'fmt ' and 'data' chunks
    int offset = 12;
    int channels = 1;
    int sampleRate = targetSampleRate;
    int bitsPerSample = 16;
    int audioFormat = 1; // 1 = PCM, 3 = IEEE float
    int dataOffset = -1;
    int dataSize = 0;

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0, Endian.little);

      if (chunkId == 'fmt ') {
        audioFormat = ByteData.sublistView(bytes, offset + 8, offset + 10).getUint16(0, Endian.little);
        if (audioFormat != 1 && audioFormat != 3) {
          // 1 = PCM, 3 = IEEE Float
          throw Exception('Unsupported WAV audio format code: $audioFormat (expected PCM or IEEE float)');
        }
        channels = ByteData.sublistView(bytes, offset + 10, offset + 12).getUint16(0, Endian.little);
        sampleRate = ByteData.sublistView(bytes, offset + 12, offset + 16).getUint32(0, Endian.little);
        bitsPerSample = ByteData.sublistView(bytes, offset + 22, offset + 24).getUint16(0, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }
      offset += 8 + chunkSize;
    }

    if (dataOffset == -1) {
      // Fallback data offset if chunk structure parsing overshoots
      dataOffset = 44;
      dataSize = bytes.length - 44;
    } else if (dataOffset + dataSize > bytes.length) {
      // Some encoders write an oversized or streaming data chunk size.
      dataSize = bytes.length - dataOffset;
    }

    if (dataSize <= 0 || dataOffset < 0 || dataOffset >= bytes.length) {
      throw const WavDecodeException('WAV file contains no audio data samples.');
    }

    final ByteData bd = ByteData.sublistView(bytes, dataOffset, dataOffset + dataSize);
    List<double> rawMonoSamples = [];

    if (bitsPerSample == 16) {
      final totalSamples = dataSize ~/ 2;
      final numFrames = totalSamples ~/ channels;

      for (int i = 0; i < numFrames; i++) {
        double frameSum = 0.0;
        for (int ch = 0; ch < channels; ch++) {
          final sampleIndex = (i * channels + ch) * 2;
          if (sampleIndex + 2 <= bd.lengthInBytes) {
            final sampleInt16 = bd.getInt16(sampleIndex, Endian.little);
            frameSum += sampleInt16 / 32768.0;
          }
        }
        rawMonoSamples.add(frameSum / channels);
      }
    } else if (bitsPerSample == 32 && audioFormat == 3) {
      final totalSamples = dataSize ~/ 4;
      final numFrames = totalSamples ~/ channels;

      for (int i = 0; i < numFrames; i++) {
        double frameSum = 0.0;
        for (int ch = 0; ch < channels; ch++) {
          final sampleIndex = (i * channels + ch) * 4;
          if (sampleIndex + 4 <= bd.lengthInBytes) {
            frameSum += bd.getFloat32(sampleIndex, Endian.little);
          }
        }
        rawMonoSamples.add((frameSum / channels).clamp(-1.0, 1.0));
      }
    } else if (bitsPerSample == 24) {
      final totalSamples = dataSize ~/ 3;
      final numFrames = totalSamples ~/ channels;

      for (int i = 0; i < numFrames; i++) {
        double frameSum = 0.0;
        for (int ch = 0; ch < channels; ch++) {
          final sampleIndex = (i * channels + ch) * 3;
          if (sampleIndex + 3 <= bd.lengthInBytes) {
            final b0 = bd.getUint8(sampleIndex);
            final b1 = bd.getUint8(sampleIndex + 1);
            final b2 = bd.getUint8(sampleIndex + 2);
            var value = b0 | (b1 << 8) | (b2 << 16);
            if ((value & 0x800000) != 0) value -= 0x1000000;
            frameSum += value / 8388608.0;
          }
        }
        rawMonoSamples.add(frameSum / channels);
      }
    } else if (bitsPerSample == 32 && audioFormat == 1) {
      final totalSamples = dataSize ~/ 4;
      final numFrames = totalSamples ~/ channels;

      for (int i = 0; i < numFrames; i++) {
        double frameSum = 0.0;
        for (int ch = 0; ch < channels; ch++) {
          final sampleIndex = (i * channels + ch) * 4;
          if (sampleIndex + 4 <= bd.lengthInBytes) {
            frameSum += bd.getInt32(sampleIndex, Endian.little) / 2147483648.0;
          }
        }
        rawMonoSamples.add(frameSum / channels);
      }
    } else if (bitsPerSample == 8) {
      final totalSamples = dataSize;
      final numFrames = totalSamples ~/ channels;

      for (int i = 0; i < numFrames; i++) {
        double frameSum = 0.0;
        for (int ch = 0; ch < channels; ch++) {
          final sampleIndex = i * channels + ch;
          if (sampleIndex < bd.lengthInBytes) {
            final sampleUint8 = bd.getUint8(sampleIndex);
            frameSum += (sampleUint8 - 128) / 128.0;
          }
        }
        rawMonoSamples.add(frameSum / channels);
      }
    } else {
      throw Exception('Unsupported bits per sample: $bitsPerSample');
    }

    // Resample to 16,000 Hz if necessary
    List<double> resampledSamples = rawMonoSamples;
    if (sampleRate != targetSampleRate && rawMonoSamples.isNotEmpty) {
      resampledSamples = resampleToTargetRate(rawMonoSamples, sampleRate);
    }

    final durationSeconds = resampledSamples.length / targetSampleRate;

    return WavDecodeResult(
      pcmSamples: resampledSamples,
      sampleRate: targetSampleRate,
      channels: 1,
      durationSeconds: durationSeconds,
    );
  }

  /// Encodes 16kHz mono float PCM samples into 16-bit PCM WAV bytes
  static Uint8List encodePcmToWavBytes(List<double> pcmSamples, {int sampleRate = targetSampleRate}) {
    final numSamples = pcmSamples.length;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final ByteData bd = ByteData(44 + dataSize);
    
    // RIFF header
    bd.setUint8(0, 0x52); // 'R'
    bd.setUint8(1, 0x49); // 'I'
    bd.setUint8(2, 0x46); // 'F'
    bd.setUint8(3, 0x46); // 'F'
    bd.setUint32(4, fileSize, Endian.little);
    bd.setUint8(8, 0x57);  // 'W'
    bd.setUint8(9, 0x41);  // 'A'
    bd.setUint8(10, 0x56); // 'V'
    bd.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    bd.setUint8(12, 0x66); // 'f'
    bd.setUint8(13, 0x6D); // 'm'
    bd.setUint8(14, 0x74); // 't'
    bd.setUint8(15, 0x20); // ' '
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);

    // data subchunk
    bd.setUint8(36, 0x64); // 'd'
    bd.setUint8(37, 0x61); // 'a'
    bd.setUint8(38, 0x74); // 't'
    bd.setUint8(39, 0x61); // 'a'
    bd.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final sample = pcmSamples[i].clamp(-1.0, 1.0);
      final int intSample = (sample * 32767.0).round();
      bd.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return bd.buffer.asUint8List();
  }

  /// Resamples [samples] from [sourceRate] to 16 kHz with a windowed-sinc
  /// low-pass kernel.
  ///
  /// The previous 3-tap smoothing pass was not an anti-alias filter: 44.1/48 kHz
  /// recordings folded energy above 8 kHz back into the speech band and shifted
  /// the MFCCs. This kernel is band-limited and unity-gain.
  static List<double> resampleToTargetRate(List<double> samples, int sourceRate) {
    if (samples.isEmpty || sourceRate <= 0 || sourceRate == targetSampleRate) {
      return List<double>.from(samples);
    }
    return _resampleSinc(samples, sourceRate, targetSampleRate);
  }

  static List<double> _resampleSinc(List<double> input, int oldRate, int newRate) {
    final ratio = oldRate / newRate;
    final outputLength = (input.length / ratio).floor();
    if (outputLength <= 0) return const [];

    // Cutoff relative to the source Nyquist frequency; 0.95 keeps a transition
    // band so nothing aliases back into the passband.
    final cutoff = (ratio > 1.0 ? 1.0 / ratio : 1.0) * 0.95;
    final halfWidth = (8 * (ratio > 1.0 ? ratio : 1.0)).ceil().clamp(8, 32).toInt();
    final output = List<double>.filled(outputLength, 0.0);

    for (int i = 0; i < outputLength; i++) {
      final center = i * ratio;
      final centerIndex = center.floor();
      double accumulator = 0.0;
      double weightSum = 0.0;

      for (int tap = centerIndex - halfWidth + 1; tap <= centerIndex + halfWidth; tap++) {
        if (tap < 0 || tap >= input.length) continue;
        final offset = center - tap;
        final sincArgument = math.pi * cutoff * offset;
        final sinc = sincArgument.abs() < 1e-9 ? 1.0 : math.sin(sincArgument) / sincArgument;
        final windowPosition = (offset / halfWidth + 1.0) * 0.5;
        if (windowPosition <= 0.0 || windowPosition >= 1.0) continue;
        final window = 0.42 -
            0.5 * math.cos(2 * math.pi * windowPosition) +
            0.08 * math.cos(4 * math.pi * windowPosition);
        final coefficient = sinc * window * cutoff;
        accumulator += input[tap] * coefficient;
        weightSum += coefficient;
      }

      output[i] = weightSum.abs() > 1e-9 ? accumulator / weightSum : 0.0;
    }
    return output;
  }

  /// Extracts downsampled visual waveform points (128/256 values) strictly for UI rendering
  static List<double> extractVisualWaveform(List<double> pcmSamples, {int noOfSamples = 128}) {
    if (pcmSamples.isEmpty) return List.filled(noOfSamples, 0.0);

    final blockSize = pcmSamples.length ~/ noOfSamples;
    if (blockSize < 1) {
      return List.generate(noOfSamples, (i) => i < pcmSamples.length ? pcmSamples[i].abs() : 0.0);
    }

    List<double> displayWaveform = [];
    for (int i = 0; i < noOfSamples; i++) {
      double maxAbs = 0.0;
      final start = i * blockSize;
      final end = math.min(start + blockSize, pcmSamples.length);
      for (int j = start; j < end; j++) {
        final val = pcmSamples[j].abs();
        if (val > maxAbs) maxAbs = val;
      }
      displayWaveform.add(maxAbs.clamp(0.0, 1.0));
    }
    return displayWaveform;
  }

  /// Applies adaptive noise suppression to a learner recording.
  ///
  /// The noise floor is the 20th percentile of the clip's 10 ms frame energies,
  /// i.e. estimated from the quietest part of the whole clip instead of the
  /// first 100 ms (which is speech whenever the learner starts immediately).
  /// Attenuation is floored at [gainFloor] and smoothed between frames, so a
  /// mis-estimated floor can no longer erase the start of a word.
  static List<double> applyNoiseReduction(
    List<double> samples, {
    int sampleRate = targetSampleRate,
    double noiseMarginDb = 6.0,
    double gainFloor = 0.25,
  }) {
    if (samples.length < 320) return samples;

    const frameSize = 160; // 10 ms at 16 kHz
    final frameRms = _frameRmsValues(samples, frameSize);
    if (frameRms.isEmpty) return samples;

    final noiseFloor = _percentile(frameRms, 0.20);
    final noiseThreshold = noiseFloor * math.pow(10.0, noiseMarginDb / 20.0);

    // A clean recording needs no gating at all.
    if (noiseThreshold < 0.0008) return samples;

    final gains = List<double>.filled(frameRms.length, 1.0);
    for (int f = 0; f < frameRms.length; f++) {
      if (frameRms[f] < noiseThreshold) {
        final relative = frameRms[f] / noiseThreshold;
        gains[f] = math.max(gainFloor, relative * relative).toDouble();
      }
    }

    final cleaned = List<double>.filled(samples.length, 0.0);
    var previousGain = gains.first;
    for (int f = 0; f < gains.length; f++) {
      final gain = gains[f];
      final start = f * frameSize;
      for (int i = 0; i < frameSize; i++) {
        final blend = i / frameSize;
        cleaned[start + i] = samples[start + i] * (previousGain * (1.0 - blend) + gain * blend);
      }
      previousGain = gain;
    }
    for (int i = gains.length * frameSize; i < samples.length; i++) {
      cleaned[i] = samples[i] * previousGain;
    }
    return cleaned;
  }

  /// Validates duration/sample-rate preconditions shared by both preparation paths.
  static void _validatePreprocessingInput(List<double> samples, int sampleRate) {
    if (sampleRate < 8000) {
      throw Exception('Input sample rate $sampleRate Hz is below minimum requirement of 8000 Hz');
    }
    final durationSec = samples.length / sampleRate;
    if (durationSec < 0.10) {
      throw Exception('Audio duration (${durationSec.toStringAsFixed(2)}s) is below minimum speech duration requirement of 100 ms');
    }
    if (durationSec > 15.0) {
      debugPrint('WavDecoder Warning: Audio recording duration (${durationSec.toStringAsFixed(1)}s) exceeds recommended maximum of 15 seconds.');
    }
  }

  static List<double> _removeDcOffset(List<double> samples) {
    if (samples.isEmpty) return samples;
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    return samples.map((s) => s - mean).toList();
  }

  /// Trims leading/trailing non-speech using frame energy with symmetric padding.
  /// The rule is energy-based and idempotent, so running it over an
  /// already-trimmed reference changes nothing.
  static List<double> _trimToSpeechRegion(
    List<double> samples, {
    required int sampleRate,
  }) {
    const frameSize = 160; // 10 ms at 16 kHz
    if (samples.length < sampleRate ~/ 10) return samples;

    final frameRms = _frameRmsValues(samples, frameSize);
    if (frameRms.isEmpty) return samples;

    final peakFrameRms = frameRms.reduce(math.max);
    final noiseFloor = _percentile(frameRms, 0.15);
    final threshold = math.max(peakFrameRms * 0.06, noiseFloor * 2.0);

    int firstFrame = -1;
    int lastFrame = -1;
    for (int f = 0; f < frameRms.length; f++) {
      if (frameRms[f] >= threshold) {
        if (firstFrame == -1) firstFrame = f;
        lastFrame = f;
      }
    }
    if (firstFrame == -1) return samples;

    final padding = (sampleRate * 0.06).round();
    final start = math.max(0, firstFrame * frameSize - padding);
    final end = math.min(samples.length, (lastFrame + 1) * frameSize + padding);

    if (end - start < (sampleRate * 0.10).floor()) return samples;
    return samples.sublist(start, end);
  }

  /// Shared loudness target: -20 dBFS RMS, -1 dBFS peak ceiling, 30 dB max gain.
  static List<double> _normalizeLoudness(List<double> samples) {
    if (samples.isEmpty) return samples;

    double peak = 0.0;
    for (final s in samples) {
      final absValue = s.abs();
      if (absValue > peak) peak = absValue;
    }
    // Never amplify silence or a pure noise floor into full-scale "speech".
    if (peak < 0.001) return samples;

    double sumSquares = 0.0;
    for (final s in samples) {
      sumSquares += s * s;
    }
    final rms = math.sqrt(sumSquares / samples.length);
    if (rms <= 0) return samples;

    final scale = math.min(targetRmsLinear / rms, maxGainLinear);
    var processed = samples.map((s) => s * scale).toList();

    double scaledPeak = 0.0;
    for (final s in processed) {
      final absValue = s.abs();
      if (absValue > scaledPeak) scaledPeak = absValue;
    }
    if (scaledPeak > peakCeilingLinear) {
      final peakScale = peakCeilingLinear / scaledPeak;
      processed = processed.map((s) => s * peakScale).toList();
    }
    return processed;
  }

  /// Learner-side preprocessing: DC removal, speech-region trimming, then
  /// loudness normalization.
  ///
  /// No time-domain noise gate is applied on either side. Gating only the learner
  /// (the previous behaviour) meant that even a perfect repeat of the reference
  /// produced different features and could never score 100; the gate also
  /// distorted the amplitude envelope that the delta coefficients depend on.
  /// Stationary noise is handled by the recording check and by DTW itself.
  static List<double> prepareLearnerPcm(List<double> samples, {int sampleRate = targetSampleRate}) {
    if (samples.isEmpty) return [];
    _validatePreprocessingInput(samples, sampleRate);

    final centered = _removeDcOffset(samples);
    final trimmed = _trimToSpeechRegion(centered, sampleRate: sampleRate);
    return _normalizeLoudness(trimmed);
  }

  /// Reference-side preprocessing for the already-preprocessed Supabase takes.
  ///
  /// The stored references were denoised, trimmed and normalized when the
  /// dataset was built. The previous pipeline re-ran the learner gate over them
  /// with the first 100 ms of speech as the "noise floor", which attenuated the
  /// onset of the native word. Both sides now receive exactly the same DC
  /// removal, idempotent trimming and loudness target.
  static List<double> prepareReferencePcm(List<double> samples, {int sampleRate = targetSampleRate}) {
    if (samples.isEmpty) return [];
    _validatePreprocessingInput(samples, sampleRate);

    final centered = _removeDcOffset(samples);
    final trimmed = _trimToSpeechRegion(centered, sampleRate: sampleRate);
    return _normalizeLoudness(trimmed);
  }

  /// Backwards-compatible alias for the original learner preprocessing pipeline.
  static List<double> preprocessPcmRecommendedV1(List<double> samples, {int sampleRate = targetSampleRate}) {
    return prepareLearnerPcm(samples, sampleRate: sampleRate);
  }
}
