import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/services/pronunciation_service.dart';
import 'package:lumad_lingua/services/pronunciation_comparer_interface.dart';

void main() {
  group('PronunciationService & Interface Unit Tests', () {
    test('PronunciationService implements IPronunciationComparer contract', () async {
      final service = PronunciationService();
      expect(service, isA<IPronunciationComparer>());

      final nativePcm = List.generate(3200, (i) => 0.1 * math.sin(2 * math.pi * 440 * i / 16000));
      final learnerPcm = List.generate(3200, (i) => 0.1 * math.sin(2 * math.pi * 440 * i / 16000));

      final request = PronunciationComparisonRequest(
        vocabularyId: 'test_item',
        referenceAudioPath: 'dataset/test/ref.wav',
        referenceAudioFile: File('fake_ref.wav'),
        learnerAudioFile: File('fake_user.wav'),
        referencePcmSamples: nativePcm,
        learnerPcmSamples: learnerPcm,
        metadata: PronunciationAudioMetadata(
          sampleRate: 16000,
          numChannels: 1,
          runId: 'RUN-2026-0004',
          configHash: '3140166e41dc4be9',
        ),
      );

      final result = await service.compare(request);

      expect(result.scorePercentage, greaterThanOrEqualTo(0.0));
      expect(result.scorePercentage, lessThanOrEqualTo(100.0));
      expect(result.isCandidateEvaluation, isTrue);
      expect(result.rawMetrics['runId'], equals('RUN-2026-0004'));
      expect(result.rawMetrics['configHash'], equals('3140166e41dc4be9'));
    });

    test('Identical 16kHz audio signals produce high comparison similarity', () {
      final nativePcm = List.generate(4800, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));
      final learnerPcm = List.generate(4800, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));

      final score = PronunciationService.analyzePronunciation(
        nativePcm,
        learnerPcm,
        algorithm: PronunciationAlgorithm.dtw,
      );

      expect(score.overallScore, greaterThan(70.0));
    });
  });
}
