import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/srs_models.dart';

void main() {
  group('SRS Math & Mastery Levels', () {
    test('SRSProgress mastery level calculations', () {
      final newCard = SRSProgress(wordId: '1', level: 0, nextReview: DateTime.now());
      expect(newCard.mastery, equals(MasteryLevel.newCard));

      final learning = SRSProgress(wordId: '2', level: 2, nextReview: DateTime.now());
      expect(learning.mastery, equals(MasteryLevel.learning));

      final reviewing = SRSProgress(wordId: '3', level: 4, nextReview: DateTime.now());
      expect(reviewing.mastery, equals(MasteryLevel.reviewing));

      final mastered = SRSProgress(wordId: '4', level: 5, nextReview: DateTime.now());
      expect(mastered.mastery, equals(MasteryLevel.mastered));
    });

    test('SRSProgress copyWith functionality', () {
      final initial = SRSProgress(
        wordId: 'test_word',
        level: 1,
        nextReview: DateTime.now(),
        consecutiveCorrect: 1,
      );

      final updated = initial.copyWith(
        level: 2,
        consecutiveCorrect: 2,
      );

      expect(updated.wordId, equals('test_word'));
      expect(updated.level, equals(2));
      expect(updated.consecutiveCorrect, equals(2));
    });
  });
}
