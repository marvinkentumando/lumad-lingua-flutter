import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/utils/wav_decoder.dart';

Uint8List createMockWavBytes({
  int sampleRate = 16000,
  int numChannels = 1,
  required List<double> pcmSamples,
}) {
  final numSampleFrames = pcmSamples.length ~/ numChannels;
  final subchunk2Size = numSampleFrames * numChannels * 2;
  final chunkSize = 36 + subchunk2Size;

  final bd = ByteData(44 + subchunk2Size);

  // RIFF header
  bd.setUint8(0, 0x52); // 'R'
  bd.setUint8(1, 0x49); // 'I'
  bd.setUint8(2, 0x46); // 'F'
  bd.setUint8(3, 0x46); // 'F'
  bd.setUint32(4, chunkSize, Endian.little);
  bd.setUint8(8, 0x57);  // 'W'
  bd.setUint8(9, 0x41);  // 'A'
  bd.setUint8(10, 0x56); // 'V'
  bd.setUint8(11, 0x45); // 'E'

  // fmt chunk
  bd.setUint8(12, 0x66); // 'f'
  bd.setUint8(13, 0x6d); // 'm'
  bd.setUint8(14, 0x74); // 't'
  bd.setUint8(15, 0x20); // ' '
  bd.setUint32(16, 16, Endian.little); // fmt chunkSize
  bd.setUint16(20, 1, Endian.little);  // AudioFormat = 1 (PCM)
  bd.setUint16(22, numChannels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  final byteRate = sampleRate * numChannels * 2;
  bd.setUint32(28, byteRate, Endian.little);
  bd.setUint16(32, numChannels * 2, Endian.little);
  bd.setUint16(34, 16, Endian.little); // bitsPerSample

  // data chunk
  bd.setUint8(36, 0x64); // 'd'
  bd.setUint8(37, 0x61); // 'a'
  bd.setUint8(38, 0x74); // 't'
  bd.setUint8(39, 0x61); // 'a'
  bd.setUint32(40, subchunk2Size, Endian.little);

  for (int i = 0; i < pcmSamples.length; i++) {
    final sampleVal = (pcmSamples[i].clamp(-1.0, 1.0) * 32767.0).round();
    bd.setInt16(44 + i * 2, sampleVal, Endian.little);
  }

  return bd.buffer.asUint8List();
}

void main() {
  group('WavDecoder Unit Tests', () {
    test('Decodes 16-bit PCM WAV bytes to 16kHz mono List<double>', () {
      final inputSamples = List.generate(1600, (i) => math.sin(2 * math.pi * 440 * i / 16000));
      final wavBytes = createMockWavBytes(sampleRate: 16000, pcmSamples: inputSamples);

      final result = WavDecoder.decodeWavBytes(wavBytes);

      expect(result.sampleRate, equals(16000));
      expect(result.channels, equals(1));
      expect(result.pcmSamples.length, equals(1600));
      expect((result.durationSeconds - 0.1).abs(), lessThan(0.01));
    });

    test('Extracts visual display waveform points separate from PCM audio data', () {
      final pcm = List.generate(3200, (i) => (i % 2 == 0) ? 0.8 : -0.8);
      final visualWave = WavDecoder.extractVisualWaveform(pcm, noOfSamples: 128);

      expect(visualWave.length, equals(128));
      expect(visualWave.every((val) => val >= 0.0 && val <= 1.0), isTrue);
    });

    test('Applies Recommended (v1) DC offset removal and RMS normalization', () {
      // Input with DC offset (+0.2)
      final rawPcm = List.generate(3200, (i) => 0.2 + 0.1 * math.sin(2 * math.pi * 440 * i / 16000));
      final processed = WavDecoder.preprocessPcmRecommendedV1(rawPcm);

      // Verify DC offset removed (mean ~ 0)
      final mean = processed.reduce((a, b) => a + b) / processed.length;
      expect(mean.abs(), lessThan(0.001));

      // Verify peak ceiling limit (-1 dBFS = ~0.89125)
      final maxPeak = processed.map((s) => s.abs()).reduce(math.max);
      expect(maxPeak, lessThanOrEqualTo(0.8912509 + 0.0001));
    });

    test('Throws exception when input sample rate is below 8000 Hz minimum requirement', () {
      final pcm = List.generate(1000, (i) => 0.1 * math.sin(i * 0.1));
      expect(
        () => WavDecoder.preprocessPcmRecommendedV1(pcm, sampleRate: 4000),
        throwsA(isA<Exception>()),
      );
    });

    test('Throws exception when speech duration is below 100 ms minimum requirement', () {
      final pcm = List.generate(500, (i) => 0.1 * math.sin(i * 0.1)); // 50ms at 16kHz
      expect(
        () => WavDecoder.preprocessPcmRecommendedV1(pcm, sampleRate: 16000),
        throwsA(isA<Exception>()),
      );
    });

    test('Resamples 48kHz PCM down to 16kHz with anti-aliasing smoothing', () {
      final input48k = List.generate(4800, (i) => math.sin(2 * math.pi * 440 * i / 48000));
      final wavBytes = createMockWavBytes(sampleRate: 48000, pcmSamples: input48k);

      final result = WavDecoder.decodeWavBytes(wavBytes);

      expect(result.sampleRate, equals(16000));
      expect(result.pcmSamples.length, equals(1600));
    });
  });
}
