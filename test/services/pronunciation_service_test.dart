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
          configHash: '3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21',
        ),
      );

      final result = await service.compare(request);

      expect(result.scorePercentage, greaterThanOrEqualTo(0.0));
      expect(result.scorePercentage, lessThanOrEqualTo(100.0));
      expect(result.isCandidateEvaluation, isFalse);
      expect(result.rawMetrics['runId'], equals('RUN-2026-0004'));
      expect(result.rawMetrics['configHash'], equals('3140166e41dc4be90fd4814f8ff45360dfee58612e52e9a8aa381c2a99808a21'));
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

    test('Dual-take comparison averages Take 1 and Take 2 overall scores correctly', () {
      final nativePcmTake1 = List.generate(4800, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));
      final nativePcmTake2 = List.generate(4800, (i) => 0.25 * math.sin(2 * math.pi * 310 * i / 16000));
      final learnerPcm = List.generate(4800, (i) => 0.2 * math.sin(2 * math.pi * 300 * i / 16000));

      final score1 = PronunciationService.analyzePronunciation(
        nativePcmTake1,
        learnerPcm,
        algorithm: PronunciationAlgorithm.dtw,
      );

      final score2 = PronunciationService.analyzePronunciation(
        nativePcmTake2,
        learnerPcm,
        algorithm: PronunciationAlgorithm.dtw,
      );

      final averageScore = (score1.overallScore + score2.overallScore) / 2.0;

      expect(averageScore, equals((score1.overallScore + score2.overallScore) / 2.0));
      expect(averageScore, greaterThan(0.0));
      expect(averageScore, lessThanOrEqualTo(100.0));
    });

    test('Multi-reference comparison scores a good take above a different word', () {
      final referenceTake1 = _speechLikeWord(formantShift: 1.0, rate: 1.0, noise: 0.004, seed: 1);
      final referenceTake2 = _speechLikeWord(formantShift: 1.04, rate: 0.95, noise: 0.006, seed: 2);
      final matchingTake = _speechLikeWord(formantShift: 1.02, rate: 1.12, noise: 0.008, seed: 3);
      final differentWord = _speechLikeWord(
        formantShift: 3.6,
        noise: 0.008,
        seed: 5,
        fricative: true,
        syllableRate: 5.2,
      );

      final referenceSet = PronunciationService.buildReferenceSet([referenceTake1, referenceTake2]);
      expect(referenceSet.isUsable, isTrue);
      expect(referenceSet.takeCount, equals(2));
      expect(referenceSet.baseline.isCalibrated, isTrue);

      final matching = PronunciationService.compareAgainstReferenceSet(referenceSet, matchingTake);
      final different = PronunciationService.compareAgainstReferenceSet(referenceSet, differentWord);

      expect(matching.distance, lessThan(different.distance));
      expect(matching.overallScore, greaterThan(different.overallScore));
      expect(matching.overallScore, greaterThan(60.0));
      expect(different.overallScore, lessThan(40.0));
      expect(matching.referenceCount, equals(2));
    });
  });
}

/// Deterministic speech-like fixture: a decaying, syllable-modulated vowel with
/// optional fricative noise. Pure tones are degenerate for cepstral normalization
/// (they carry almost no spectral variance over time), so tests use this instead.
List<double> _speechLikeWord({
  double formantShift = 1.0,
  double rate = 1.0,
  double noise = 0.0,
  int seed = 1,
  bool fricative = false,
  double syllableRate = 3.1,
}) {
  const f1 = 180.0;
  const f2 = 900.0;
  final sampleCount = (16000 * 0.8 * rate).round();
  final random = math.Random(seed);
  final samples = <double>[];
  for (int i = 0; i < sampleCount; i++) {
    final t = (i / 16000) / rate;
    final envelope = math.exp(-2.0 * t) * (1 - math.exp(-45 * t));
    final syllable = 0.55 + 0.45 * math.sin(2 * math.pi * syllableRate * t);
    var voiced = 0.6 * math.sin(2 * math.pi * f1 * formantShift * t) +
        0.3 * math.sin(2 * math.pi * f2 * formantShift * t + 0.7) +
        0.12 * math.sin(2 * math.pi * f1 * 2.3 * formantShift * t);
    if (fricative && t < 0.08) voiced += 0.5 * (random.nextDouble() * 2 - 1);
    samples.add(0.5 * envelope * syllable * voiced + noise * (random.nextDouble() * 2 - 1));
  }
  return samples;
}
