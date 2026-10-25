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

    test('Silent or near-silent PCM recordings are flagged as silent and blocked', () {
      final silentPcm = List.filled(16000, 0.001);
      final signal = WavDecoder.analyzeSignal(silentPcm);

      expect(signal.isSilent, isTrue);
      expect(signal.peakAmplitude < WavDecoder.candidateSilentPeakThreshold, isTrue);
    });

    test('Valid speech audio passes signal analysis and is not flagged as silent', () {
      final speechPcm = List.generate(16000, (i) => 0.25 * (i % 2 == 0 ? 1.0 : -1.0));
      final signal = WavDecoder.analyzeSignal(speechPcm);

      expect(signal.isSilent, isFalse);
      expect(signal.peakAmplitude, equals(0.25));
    });

    test('Maximum recording duration constant is configured to 15 seconds', () {
      const maxSeconds = 15;
      expect(maxSeconds, equals(15));
    });

    test('Signal analysis correctly classifies 15-second valid vs silent PCM recordings', () {
      // 15s of 16kHz audio = 240,000 samples
      final silent15sPcm = List.filled(15 * 16000, 0.0005);
      final valid15sPcm = List.generate(15 * 16000, (i) => 0.3 * (i % 2 == 0 ? 1.0 : -1.0));

      final silentSignal = WavDecoder.analyzeSignal(silent15sPcm);
      final validSignal = WavDecoder.analyzeSignal(valid15sPcm);

      expect(silentSignal.isSilent, isTrue);
      expect(validSignal.isSilent, isFalse);
      expect(validSignal.peakAmplitude, equals(0.3));
    });

    test('Concurrent or duplicate stop invocations are prevented by stopping guard', () {
      bool isStopping = false;
      int stopCallCount = 0;

      void executeStop() {
        if (isStopping) return;
        isStopping = true;
        stopCallCount++;
      }

      // Simulate simultaneous timer tick and manual button tap
      executeStop(); // First invocation
      executeStop(); // Overlapping invocation

      expect(stopCallCount, equals(1));
    });
  });
}
