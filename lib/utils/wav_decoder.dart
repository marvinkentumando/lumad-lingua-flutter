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
  final bool isClipped;
  final bool isHighNoise;
  final bool isMultiSpeaker;
  final bool isExcessivePause;
  final bool isInterrupted;
  final bool hasNoSpeech;

  SignalAnalysisResult({
    required this.isEmptyOrInvalid,
    required this.peakAmplitude,
    required this.rms,
    required this.isSilent,
    required this.isQuiet,
    this.isClipped = false,
    this.isHighNoise = false,
    this.isMultiSpeaker = false,
    this.isExcessivePause = false,
    this.isInterrupted = false,
    this.hasNoSpeech = false,
  });
}

class WavDecoder {
  static const int targetSampleRate = 16000;
  static const int minimumComparisonSamples = targetSampleRate * 35 ~/ 100;
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
    int clippedCount = 0;
    int exactZeroCount = 0;

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
      if (absVal == 0.0) exactZeroCount++;
    }

    final rms = math.sqrt(sumSquares / samples.length);

    final isSilent = maxAbs < candidateSilentPeakThreshold && rms < candidateSilentRmsThreshold;
    final isQuiet = !isSilent && maxAbs < candidateQuietPeakThreshold;

    // 1. Audio Clipping & Distortion (>1% of samples at max ceiling)
    final isClipped = (clippedCount / samples.length) >= 0.01;

    // 2. High Background Noise / Low Signal-to-Noise Ratio (SNR < 6dB)
    final initialSamples = math.min(1600, samples.length ~/ 10);
    double noiseFloorPower = 0.0;
    for (int i = 0; i < initialSamples; i++) {
      noiseFloorPower += samples[i] * samples[i];
    }
    final noiseFloorRms = math.sqrt(noiseFloorPower / math.max(1, initialSamples));
    final isHighNoise = !isSilent && noiseFloorRms > 0.035 && (rms / noiseFloorRms) < 2.0;

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

    // 4. Multiple Speakers / Overlapping Voices
    bool isMultiSpeaker = false;
    if (firstActiveFrame != -1 && lastActiveFrame - firstActiveFrame >= 20) {
      List<double> zcrList = [];
      for (int f = firstActiveFrame; f <= lastActiveFrame; f++) {
        if (frameActive[f]) {
          int zcr = 0;
          final start = f * frameSize;
          for (int i = start; i < start + frameSize - 1; i++) {
            if ((samples[i] >= 0 && samples[i + 1] < 0) || (samples[i] < 0 && samples[i + 1] >= 0)) {
              zcr++;
            }
          }
          zcrList.add(zcr / frameSize);
        }
      }
      if (zcrList.length >= 10) {
        final meanZcr = zcrList.reduce((a, b) => a + b) / zcrList.length;
        double zcrVar = 0.0;
        for (var z in zcrList) {
          zcrVar += (z - meanZcr) * (z - meanZcr);
        }
        zcrVar /= zcrList.length;
        if (zcrVar > 0.035 && maxAbs > 0.50) {
          isMultiSpeaker = true;
        }
      }
    }

    // 5. Mid-Recording Hardware Interruption
    bool isInterrupted = false;
    if (lastActiveFrame != -1 && lastActiveFrame < numFrames - 10) {
      int zeroTrailCount = 0;
      for (int i = lastActiveFrame * frameSize; i < samples.length; i++) {
        if (samples[i] == 0.0) zeroTrailCount++;
      }
      if (exactZeroCount > 3200 && zeroTrailCount > 3200) {
        isInterrupted = true;
      }
    }

    // 6. Speech Presence Verification (VAD: Speech vs Pure Background Noise / Hiss)
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

      // Stationary broadband noise can have high peaks and active energy in
      // every frame. Treat a sustained, nearly constant, high-crossing signal
      // as noise instead of speech (while keeping short fricatives viable).
      int activeFrameCount = 0;
      double activeFrameRmsSum = 0.0;
      double activeFrameRmsSquaredSum = 0.0;
      double activeZeroCrossings = 0.0;
      int activeZeroCrossingFrames = 0;
      for (int f = 0; f < numFrames; f++) {
        if (!frameActive[f]) continue;
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
      }
      final meanActiveRms = activeFrameRmsSum / math.max(1, activeFrameCount);
      final activeRmsVariance = math.max(
        0.0,
        activeFrameRmsSquaredSum / math.max(1, activeFrameCount) - meanActiveRms * meanActiveRms,
      );
      final activeRmsCv = meanActiveRms > 0 ? math.sqrt(activeRmsVariance) / meanActiveRms : 0.0;
      final meanActiveZcr = activeZeroCrossings / math.max(1, activeZeroCrossingFrames);
      final likelyStationaryNoise = activeSpeechSec > 0.3 && activeRmsCv < 0.12 && meanActiveZcr > 0.18;

      if (activeSpeechSec < 0.20 || peakToNoiseRatio < 2.5 || likelyStationaryNoise) {
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
      isMultiSpeaker: isMultiSpeaker,
      isExcessivePause: isExcessivePause,
      isInterrupted: isInterrupted,
      hasNoSpeech: hasNoSpeech,
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

    // Detect WebM container signature (0x1A 0x45 0xDF 0xA3) from browser recordings
    if (bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3) {
      // Locate Cluster header (0x1F 0x43 0xB6 0x75) to skip EBML text headers ("webm", "opus")
      int clusterIndex = -1;
      for (int i = 0; i < bytes.length - 4; i++) {
        if (bytes[i] == 0x1F && bytes[i + 1] == 0x43 && bytes[i + 2] == 0xB6 && bytes[i + 3] == 0x75) {
          clusterIndex = i + 12;
          break;
        }
      }
      final audioPayload = (clusterIndex != -1 && clusterIndex < bytes.length)
          ? bytes.sublist(clusterIndex)
          : Uint8List(0);
      return createWavHeader(audioPayload, sampleRate: sampleRate, numChannels: channels, bitsPerSample: 16);
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

  /// Applies adaptive noise reduction (noise gating / spectral noise suppression)
  /// to remove stationary background noise before waveform preprocessing.
  static List<double> applyNoiseReduction(List<double> samples, {int sampleRate = targetSampleRate, double noiseMarginDb = 6.0}) {
    if (samples.length < 320) return samples;

    // Estimate background noise floor power from initial silent frames (first 100ms)
    final initialSamples = math.min(1600, samples.length ~/ 10);
    double noiseFloorPower = 0.0;
    for (int i = 0; i < initialSamples; i++) {
      noiseFloorPower += samples[i] * samples[i];
    }
    noiseFloorPower /= initialSamples;
    final noiseFloorRms = math.sqrt(noiseFloorPower);
    final noiseThreshold = noiseFloorRms * math.pow(10.0, noiseMarginDb / 20.0);

    if (noiseThreshold < 0.0001) return samples;

    final List<double> cleaned = List<double>.filled(samples.length, 0.0);
    const windowSize = 160; // 10ms frame
    for (int i = 0; i < samples.length; i += windowSize) {
      final end = math.min(i + windowSize, samples.length);
      double framePower = 0.0;
      for (int j = i; j < end; j++) {
        framePower += samples[j] * samples[j];
      }
      final frameRms = math.sqrt(framePower / (end - i));

      double gain = 1.0;
      if (frameRms < noiseThreshold) {
        gain = (frameRms / noiseThreshold).clamp(0.0, 1.0);
        gain = gain * gain;
      }

      for (int j = i; j < end; j++) {
        cleaned[j] = samples[j] * gain;
      }
    }
    return cleaned;
  }

  /// Applies the exact `Recommended (v1)` waveform preprocessing pipeline:
  /// - Validation (min duration 100ms, min sample rate 8000Hz, warning > 15s)
  /// - Noise cancellation / noise floor reduction
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

    // 1.5 Adaptive Noise Cancellation / Suppression
    final noiseReduced = applyNoiseReduction(samples, sampleRate: sampleRate);

    // 2. DC Offset Removal (Mean Subtraction)
    final mean = noiseReduced.reduce((a, b) => a + b) / noiseReduced.length;
    List<double> processed = noiseReduced.map((s) => s - mean).toList();

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
