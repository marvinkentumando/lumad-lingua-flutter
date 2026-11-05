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

    test('WavDecoder.analyzeSignal identifies empty or non-finite PCM as empty/invalid', () {
      final emptyResult = WavDecoder.analyzeSignal([]);
      expect(emptyResult.isEmptyOrInvalid, isTrue);
      expect(emptyResult.isSilent, isTrue);

      final nonFiniteResult = WavDecoder.analyzeSignal([0.1, double.nan, 0.2]);
      expect(nonFiniteResult.isEmptyOrInvalid, isTrue);
      expect(nonFiniteResult.isSilent, isTrue);
    });

    test('WavDecoder.analyzeSignal identifies all-zero and near-silent PCM as silent', () {
      final zeroResult = WavDecoder.analyzeSignal(List.filled(1600, 0.0));
      expect(zeroResult.isEmptyOrInvalid, isFalse);
      expect(zeroResult.isSilent, isTrue);
      expect(zeroResult.peakAmplitude, equals(0.0));

      // Near silent samples (< 0.01 peak and < 0.002 RMS)
      final nearSilentPcm = List.generate(1600, (i) => 0.002 * (i % 2 == 0 ? 1 : -1));
      final nearSilentResult = WavDecoder.analyzeSignal(nearSilentPcm);
      expect(nearSilentResult.isSilent, isTrue);
    });

    test('WavDecoder.analyzeSignal identifies quiet vs ordinary audio correctly', () {
      // Quiet speech (peak 0.03, above 0.01 silent threshold but below 0.05 quiet threshold)
      final quietPcm = List.generate(1600, (i) => 0.03 * math.sin(i * 0.1));
      final quietResult = WavDecoder.analyzeSignal(quietPcm);
      expect(quietResult.isSilent, isFalse);
      expect(quietResult.isQuiet, isTrue);

      // Ordinary speech (peak 0.3)
      final normalPcm = List.generate(1600, (i) => 0.3 * math.sin(i * 0.1));
      final normalResult = WavDecoder.analyzeSignal(normalPcm);
      expect(normalResult.isSilent, isFalse);
      expect(normalResult.isQuiet, isFalse);
    });

    test('Rejects compressed containers instead of wrapping them as PCM', () {
      final webm = Uint8List.fromList([
        0x1A, 0x45, 0xDF, 0xA3, 0x9F, 0x42, 0x86, 0x81, 0x01, 0x42, 0x82, 0x84,
        0x77, 0x65, 0x62, 0x6D,
      ]);
      expect(
        () => WavDecoder.ensureWavBytes(webm),
        throwsA(isA<WavDecodeException>()),
      );
      expect(
        () => WavDecoder.decodeAudioBytes(webm),
        throwsA(isA<WavDecodeException>()),
      );

      final m4a = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20,
        0x00, 0x00, 0x00, 0x00,
      ]);
      expect(
        () => WavDecoder.decodeAudioBytes(m4a),
        throwsA(isA<WavDecodeException>()),
      );
    });

    test('Decodes IEEE float 32-bit WAV samples (format code 3)', () {
      final floatSamples = List.generate(1600, (i) => 0.4 * math.sin(2 * math.pi * 440 * i / 16000));
      final bd = ByteData(44 + floatSamples.length * 4);

      void writeAscii(int offset, String text) {
        for (int i = 0; i < text.length; i++) {
          bd.setUint8(offset + i, text.codeUnitAt(i));
        }
      }

      final dataSize = floatSamples.length * 4;
      writeAscii(0, 'RIFF');
      bd.setUint32(4, 36 + dataSize, Endian.little);
      writeAscii(8, 'WAVE');
      writeAscii(12, 'fmt ');
      bd.setUint32(16, 16, Endian.little);
      bd.setUint16(20, 3, Endian.little); // IEEE float
      bd.setUint16(22, 1, Endian.little);
      bd.setUint32(24, 16000, Endian.little);
      bd.setUint32(28, 16000 * 4, Endian.little);
      bd.setUint16(32, 4, Endian.little);
      bd.setUint16(34, 32, Endian.little);
      writeAscii(36, 'data');
      bd.setUint32(40, dataSize, Endian.little);
      for (int i = 0; i < floatSamples.length; i++) {
        bd.setFloat32(44 + i * 4, floatSamples[i], Endian.little);
      }

      final result = WavDecoder.decodeAudioBytes(bd.buffer.asUint8List());
      expect(result.pcmSamples.length, equals(floatSamples.length));
      for (int i = 0; i < 200; i++) {
        expect(result.pcmSamples[i], closeTo(floatSamples[i], 1e-6));
      }
    });

    test('Windowed-sinc resampling preserves duration and amplitude of a 48 kHz tone', () {
      final tone48k = List.generate(48000, (i) => math.sin(2 * math.pi * 1000 * i / 48000));
      final resampled = WavDecoder.resampleToTargetRate(tone48k, 48000);

      expect(resampled.length, equals(16000));
      final peak = resampled.map((s) => s.abs()).reduce(math.max);
      expect(peak, greaterThan(0.9));
      expect(peak, lessThan(1.1));
    });

    test('Learner and reference preparation share the same loudness target', () {
      final cleanTone = List.generate(8000, (i) => 0.3 * math.sin(2 * math.pi * 220 * i / 16000));

      final learner = WavDecoder.prepareLearnerPcm(cleanTone);
      final reference = WavDecoder.prepareReferencePcm(cleanTone);

      double rmsOf(List<double> samples) {
        final sum = samples.fold<double>(0.0, (acc, s) => acc + s * s);
        return math.sqrt(sum / samples.length);
      }

      expect(rmsOf(learner), closeTo(WavDecoder.targetRmsLinear, 0.01));
      expect(rmsOf(reference), closeTo(WavDecoder.targetRmsLinear, 0.01));
    });

    test('Noise gate no longer treats the opening phoneme as the noise floor', () {
      // Speech starting at sample 0 (no leading silence) over a faint noise bed.
      final samples = List.generate(16000, (i) {
        final envelope = i < 4800 ? 0.30 : 0.0;
        return envelope * math.sin(2 * math.pi * 220 * i / 16000) + 0.0008 * math.sin(i * 0.7);
      });

      final processed = WavDecoder.prepareLearnerPcm(samples);
      final openingRms = math.sqrt(
        processed.take(800).fold<double>(0.0, (acc, s) => acc + s * s) / 800,
      );
      final overallRms = math.sqrt(
        processed.fold<double>(0.0, (acc, s) => acc + s * s) / processed.length,
      );

      // The onset must survive instead of being gated down to near silence.
      expect(openingRms, greaterThan(overallRms * 0.7));
    });
  });
}
