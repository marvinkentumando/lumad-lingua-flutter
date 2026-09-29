import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/models/dictionary_entry.dart';
import 'package:lumad_lingua/providers/dictionary_provider.dart';

void main() {
  group('DictionaryFilter Tests', () {
    test('Default filter values', () {
      final filter = DictionaryFilter();
      expect(filter.query, isEmpty);
      expect(filter.category, equals('ALL'));
      expect(filter.sort, equals(DictionarySort.alphabetical));
      expect(filter.partOfSpeech, isNull);
    });

    test('Filter copyWith updates query and partOfSpeech', () {
      final filter = DictionaryFilter();
      final updated = filter.copyWith(
        query: 'dagmay',
        partOfSpeech: PartOfSpeech.noun,
      );

      expect(updated.query, equals('dagmay'));
      expect(updated.partOfSpeech, equals(PartOfSpeech.noun));

      final cleared = updated.copyWith(clearPartOfSpeech: true);
      expect(cleared.partOfSpeech, isNull);
      expect(cleared.query, equals('dagmay'));
    });
  });
}
