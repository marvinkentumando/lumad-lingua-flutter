import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/mfcc_service.dart';
import 'package:lumad_lingua/services/pronunciation_service.dart';
import 'package:lumad_lingua/utils/wav_decoder.dart';

void main() {
  group('MFCCService Unit Tests - Approved recommended_v1 Configuration', () {
    test('Verifies correct MFCC parameter constant definitions', () {
      expect(MFCCService.sampleRate, equals(16000));
      expect(MFCCService.frameSize, equals(400)); // 25 ms @ 16 kHz
      expect(MFCCService.frameStride, equals(160)); // 10 ms @ 16 kHz
      expect(MFCCService.numFilters, equals(23)); // 23 Mel filters
      expect(MFCCService.numCepstral, equals(13)); // 13 static MFCCs
      expect(MFCCService.fMinHz, equals(20.0)); // 20 Hz fmin
      expect(MFCCService.preEmphasisAlpha, equals(0.97));
      expect(MFCCService.deltaWidth, equals(2)); // Delta width 2
    });

    test('Frame calculation produces expected frame count for 1 second of 16kHz audio', () {
      // 16,000 samples = 1 second
      // Frame size 400, frame stride 160
      // Number of frames = floor((16000 - 400) / 160) + 1 = 15600 / 160 + 1 = 97 + 1 = 98
      final samples = List.generate(16000, (i) => math.sin(2 * math.pi * 440 * i / 16000));
      final mfccMatrix = MFCCService.extractMFCC(samples);

      expect(mfccMatrix.length, equals(98));
    });

    test('Output feature matrix dimension is 39 (13 static + 13 delta + 13 delta-delta)', () {
      final samples = List.generate(3200, (i) => 0.1 * math.sin(2 * math.pi * 440 * i / 16000));
      final mfccMatrix = MFCCService.extractMFCC(samples);

      expect(mfccMatrix, isNotEmpty);
      for (final frameVector in mfccMatrix) {
        expect(frameVector.length, equals(39));
      }
    });

    test('CMN centers each feature channel on zero while keeping its variance', () {
      final samples = List.generate(4800, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));
      final mfccMatrix = MFCCService.extractMFCC(samples);

      expect(mfccMatrix.length, greaterThan(1));
      final numFrames = mfccMatrix.length;
      final numFeatures = mfccMatrix[0].length; // 39

      for (int d = 0; d < numFeatures; d++) {
        double sum = 0.0;
        for (int t = 0; t < numFrames; t++) {
          sum += mfccMatrix[t][d];
        }
        final mean = sum / numFrames;
        expect(mean.abs(), lessThan(1e-5), reason: 'Feature channel $d mean should be ~0');
      }

      // Variance is intentionally preserved: scaling it away erases the spectral
      // envelope that separates words from each other.
      double varianceOfChannel0 = 0.0;
      for (int t = 0; t < numFrames; t++) {
        varianceOfChannel0 += mfccMatrix[t][0] * mfccMatrix[t][0];
      }
      varianceOfChannel0 /= numFrames;
      expect(varianceOfChannel0, isNot(closeTo(1.0, 1e-3)));
    });

    test('Handles short audio safely without throwing exceptions or generating non-finite values', () {
      // Very short audio: 300 samples (< 400 sample frame size)
      final shortSamples = List.generate(300, (i) => 0.1 * math.sin(i * 0.1));
      final resultShort = MFCCService.extractMFCC(shortSamples);
      expect(resultShort, isEmpty);

      // Exactly 1 frame: 400 samples
      final singleFrameSamples = List.generate(400, (i) => 0.1 * math.sin(i * 0.1));
      final resultSingle = MFCCService.extractMFCC(singleFrameSamples);
      expect(resultSingle.length, equals(1));
      expect(resultSingle[0].length, equals(39));
      expect(resultSingle[0].every((val) => val.isFinite), isTrue);
    });

    test('Sanitizes non-finite values and handles empty input safely', () {
      expect(MFCCService.extractMFCC([]), isEmpty);

      final invalidSamples = [0.1, double.nan, double.infinity, -0.2, 0.5];
      // 5 samples is less than 400, so returns [] safely without crashing
      expect(MFCCService.extractMFCC(invalidSamples), isEmpty);
    });

    test('Learner and reference audio undergo identical preprocessing and feature extraction', () {
      final nativeRaw = List.generate(3200, (i) => 0.2 * math.sin(2 * math.pi * 440 * i / 16000));
      final userRaw = List.generate(3200, (i) => 0.2 * math.sin(2 * math.pi * 440 * i / 16000));

      final nativePreprocessed = WavDecoder.preprocessPcmRecommendedV1(nativeRaw);
      final userPreprocessed = WavDecoder.preprocessPcmRecommendedV1(userRaw);

      final nativeFeatures = MFCCService.extractMFCC(nativePreprocessed);
      final userFeatures = MFCCService.extractMFCC(userPreprocessed);

      expect(nativeFeatures.length, equals(userFeatures.length));
      expect(nativeFeatures[0].length, equals(39));
      expect(userFeatures[0].length, equals(39));

      // Features should be identical for identical inputs
      for (int i = 0; i < nativeFeatures.length; i++) {
        for (int d = 0; d < 39; d++) {
          expect(nativeFeatures[i][d], closeTo(userFeatures[i][d], 1e-6));
        }
      }
    });

    test('Feature matrices are fully compatible with calculateMFCCDistance and DTW comparison', () {
      final s = List.generate(3200, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));
      final t = List.generate(3200, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));

      final mfccS = MFCCService.extractMFCC(s);
      final mfccT = MFCCService.extractMFCC(t);

      final dtwDistance = MFCCService.calculateMFCCDistance(mfccS, mfccT);
      expect(dtwDistance, equals(0.0));

      final score = PronunciationService.analyzePronunciation(s, t);
      expect(score.overallScore, closeTo(100.0, 1e-3));
    });
  });
}
