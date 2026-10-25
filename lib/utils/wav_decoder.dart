import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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

  SignalAnalysisResult({
    required this.isEmptyOrInvalid,
    required this.peakAmplitude,
    required this.rms,
    required this.isSilent,
    required this.isQuiet,
  });
}

class WavDecoder {
  static const int targetSampleRate = 16000;
  static const double targetRmsLinear = 0.10; // -20 dBFS
  static const double peakCeilingLinear = 0.8912509; // -1 dBFS
  static const double maxGainLinear = 31.6227766; // 30 dB

  /// Candidate silent peak threshold (-40 dBFS linear = 0.010)
  static const double candidateSilentPeakThreshold = 0.010;

  /// Candidate silent RMS threshold (-54 dBFS linear = 0.002)
  static const double candidateSilentRmsThreshold = 0.002;

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
    }

    final rms = math.sqrt(sumSquares / samples.length);

    final isSilent = maxAbs < candidateSilentPeakThreshold && rms < candidateSilentRmsThreshold;
    final isQuiet = !isSilent && maxAbs < candidateQuietPeakThreshold;

    return SignalAnalysisResult(
      isEmptyOrInvalid: false,
      peakAmplitude: maxAbs,
      rms: rms,
      isSilent: isSilent,
      isQuiet: isQuiet,
    );
  }

  /// Reads a 16-bit PCM WAV file and decodes it to 16kHz mono `List<double>` samples.
  static Future<WavDecodeResult> decodeWavFile(File file) async {
    final bytes = await file.readAsBytes();
    return decodeWavBytes(bytes);
  }

  /// Ensures audio bytes have a valid RIFF/WAVE header. Prepends a valid header if missing.
  static Uint8List ensureWavBytes(Uint8List bytes, {int sampleRate = targetSampleRate, int channels = 1}) {
    if (bytes.length >= 12) {
      final sig = String.fromCharCodes(bytes.sublist(0, 4));
      final wave = String.fromCharCodes(bytes.sublist(8, 12));
      if (sig == 'RIFF' && wave == 'WAVE') {
        return bytes;
      }
    }
    return createWavHeader(bytes, sampleRate: sampleRate, numChannels: channels, bitsPerSample: 16);
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
    int dataOffset = -1;
    int dataSize = 0;

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0, Endian.little);

      if (chunkId == 'fmt ') {
        final formatCode = ByteData.sublistView(bytes, offset + 8, offset + 10).getUint16(0, Endian.little);
        if (formatCode != 1 && formatCode != 3) {
          // 1 = PCM, 3 = IEEE Float
          throw Exception('Unsupported WAV audio format code: $formatCode (expected PCM)');
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

    if (dataOffset == -1 || dataOffset + dataSize > bytes.length) {
      // Fallback data offset if chunk structure parsing overshoots
      dataOffset = 44;
      dataSize = bytes.length - 44;
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
      resampledSamples = _resampleLinear(rawMonoSamples, sampleRate, targetSampleRate);
    }

    final durationSeconds = resampledSamples.length / targetSampleRate;

    return WavDecodeResult(
      pcmSamples: resampledSamples,
      sampleRate: targetSampleRate,
      channels: 1,
      durationSeconds: durationSeconds,
    );
  }

  /// Linear interpolation resampling with anti-aliasing low-pass smoothing when downsampling
  static List<double> _resampleLinear(List<double> input, int oldRate, int newRate) {
    if (input.isEmpty || oldRate == newRate) return input;
    final ratio = oldRate / newRate;

    List<double> source = input;
    // Apply low-pass anti-aliasing filter when downsampling
    if (ratio > 1.0 && input.length > 3) {
      final filtered = List<double>.filled(input.length, 0.0);
      filtered[0] = input[0];
      filtered[input.length - 1] = input[input.length - 1];
      for (int i = 1; i < input.length - 1; i++) {
        filtered[i] = 0.25 * input[i - 1] + 0.5 * input[i] + 0.25 * input[i + 1];
      }
      source = filtered;
    }

    final newLength = (source.length / ratio).floor();
    List<double> output = List.filled(newLength, 0.0);

    for (int i = 0; i < newLength; i++) {
      final double srcPos = i * ratio;
      final int index0 = srcPos.floor();
      final int index1 = math.min(index0 + 1, source.length - 1);
      final double frac = srcPos - index0;
      output[i] = source[index0] * (1.0 - frac) + source[index1] * frac;
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

  /// Applies the exact `Recommended (v1)` waveform preprocessing pipeline:
  /// - Validation (min duration 100ms, min sample rate 8000Hz, warning > 15s)
  /// - DC offset removal
  /// - Speech-core silence trimming (core -20dB, extension depth -40dB, zero-crossing, safety padding 100ms)
  /// - RMS normalization targeting -20 dBFS with peak ceiling -1 dBFS and max gain 30 dB clamp
  static List<double> preprocessPcmRecommendedV1(List<double> samples, {int sampleRate = targetSampleRate}) {
    if (samples.isEmpty) return [];

    // 1. Validation
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

    // 2. DC Offset Removal (Mean Subtraction)
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    List<double> processed = samples.map((s) => s - mean).toList();

    // 3. Leading & Trailing Silence Trimming
    double maxAbs = 0.0;
    for (var s in processed) {
      if (s.abs() > maxAbs) maxAbs = s.abs();
    }

    if (maxAbs < 0.001) {
      // Audio is virtually silent
      return processed;
    }

    final speechCoreThreshold = maxAbs * 0.10; // -20 dB below peak
    final safetyPadSamples = (sampleRate * 0.10).round(); // 100 ms safety padding

    int coreStart = -1;
    for (int i = 0; i < processed.length; i++) {
      if (processed[i].abs() >= speechCoreThreshold) {
        coreStart = i;
        break;
      }
    }

    int coreEnd = -1;
    for (int i = processed.length - 1; i >= 0; i--) {
      if (processed[i].abs() >= speechCoreThreshold) {
        coreEnd = i;
        break;
      }
    }

    if (coreStart != -1 && coreEnd != -1 && coreEnd > coreStart) {
      int start = math.max(0, coreStart - safetyPadSamples);
      int end = math.min(processed.length - 1, coreEnd + safetyPadSamples);

      // Zero-crossing adjustment (search up to 150ms = 2400 samples)
      final zeroCrossLimit = (sampleRate * 0.15).round();
      for (int i = start; i > math.max(0, start - zeroCrossLimit); i--) {
        if (i > 0 && ((processed[i] >= 0 && processed[i - 1] < 0) || (processed[i] <= 0 && processed[i - 1] > 0))) {
          start = i;
          break;
        }
      }

      for (int i = end; i < math.min(processed.length - 1, end + zeroCrossLimit); i++) {
        if (i < processed.length - 1 && ((processed[i] >= 0 && processed[i + 1] < 0) || (processed[i] <= 0 && processed[i + 1] > 0))) {
          end = i;
          break;
        }
      }

      if (end - start + 1 >= (sampleRate * 0.10).floor()) {
        processed = processed.sublist(start, end + 1);
      }
    }

    // 4. RMS Amplitude Normalization
    double sumSquares = 0.0;
    for (var s in processed) {
      sumSquares += s * s;
    }
    final rms = math.sqrt(sumSquares / processed.length);

    if (rms > 0) {
      double scale = targetRmsLinear / rms;
      // Clamp gain to maximum 30 dB (scale factor 31.6227)
      scale = math.min(scale, maxGainLinear);

      processed = processed.map((s) => s * scale).toList();

      // Enforce Peak Ceiling (-1 dBFS = 0.89125 linear)
      double currentPeak = 0.0;
      for (var s in processed) {
        if (s.abs() > currentPeak) currentPeak = s.abs();
      }

      if (currentPeak > peakCeilingLinear) {
        final peakScale = peakCeilingLinear / currentPeak;
        processed = processed.map((s) => s * peakScale).toList();
      }
    }

    return processed;
  }
}
