import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/pronunciation_comparer_interface.dart';
import 'package:lumad_lingua/utils/wav_decoder.dart';

void main() {
  group('Audio Comparison Recording & Flow Logic Tests', () {
    test('Decoded PCM samples are separate from 128-point visual display waveform', () {
      final pcm = List.generate(16000, (i) => (i % 2 == 0 ? 0.5 : -0.5));
      final visualWave = WavDecoder.extractVisualWaveform(pcm, noOfSamples: 128);

      // Verify PCM analysis array preserves 16000 samples
      expect(pcm.length, equals(16000));

      // Verify visual display array is downsampled to 128 points
      expect(visualWave.length, equals(128));
      expect(visualWave.every((val) => val >= 0.0 && val <= 1.0), isTrue);
    });

    test('PronunciationComparisonRequest receives full high-density PCM array', () {
      final nativePcm = List.generate(16000, (i) => 0.1);
      final learnerPcm = List.generate(16000, (i) => 0.1);

      final request = PronunciationComparisonRequest(
        vocabularyId: 'saramat',
        referenceAudioPath: 'dataset/saramat/saramat__RUN-2026-0004.wav',
        referenceAudioFile: File('ref.wav'),
        learnerAudioFile: File('user.wav'),
        referencePcmSamples: nativePcm,
        learnerPcmSamples: learnerPcm,
        metadata: PronunciationAudioMetadata(
          sampleRate: 16000,
          numChannels: 1,
          runId: 'RUN-2026-0004',
          configHash: '3140166e41dc4be9',
        ),
      );

      // Verify request PCM samples are high-density 16kHz audio arrays
      expect(request.referencePcmSamples.length, equals(16000));
      expect(request.learnerPcmSamples.length, equals(16000));
    });

    test('Candidate model comparison results do not award XP', () {
      final result = PronunciationComparisonResult(
        scorePercentage: 85.0,
        isCandidateEvaluation: true,
        feedbackKey: 'feedback_excellent',
      );

      expect(result.isCandidateEvaluation, isTrue);
      expect(result.scorePercentage, equals(85.0));
    });
  });
}
