import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';
import '../services/firebase_service.dart';
import 'saved_words_provider.dart';

enum DictionarySort { alphabetical, reverseAlphabetical, newest, oldest }

class DictionaryFilter {
  final String query;
  final String category;
  final DictionarySort sort;

  DictionaryFilter({
    this.query = '',
    this.category = 'ALL',
    this.sort = DictionarySort.alphabetical,
  });

  DictionaryFilter copyWith({
    String? query,
    String? category,
    DictionarySort? sort,
  }) {
    return DictionaryFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      sort: sort ?? this.sort,
    );
  }
}

final dictionaryFilterProvider = StateProvider<DictionaryFilter>((ref) => DictionaryFilter());

final filteredDictionaryProvider = Provider<AsyncValue<List<DictionaryEntry>>>((ref) {
  final dictionaryAsync = ref.watch(dictionaryStreamProvider);
  final filter = ref.watch(dictionaryFilterProvider);
  final savedIds = ref.watch(savedWordsProvider);

  return dictionaryAsync.whenData((entries) {
    var items = entries;

    // 1. Filter by category (e.g. SAVED)
    if (filter.category == 'SAVED') {
      items = items.where((e) => savedIds.contains(e.id)).toList();
    }

    // 2. Filter by search query with basic optimization (lowercase only once)
    if (filter.query.isNotEmpty) {
      final q = filter.query.toLowerCase();
      items = items.where((e) {
        // indigenousWord and translation are likely short, but contains is still O(m*n)
        return e.indigenousWord.toLowerCase().contains(q) ||
               e.translation.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Apply Sorting
    final sorted = List<DictionaryEntry>.from(items);
    switch (filter.sort) {
      case DictionarySort.alphabetical:
        sorted.sort((a, b) => a.indigenousWord.toLowerCase().compareTo(b.indigenousWord.toLowerCase()));
        break;
      case DictionarySort.reverseAlphabetical:
        sorted.sort((a, b) => b.indigenousWord.toLowerCase().compareTo(a.indigenousWord.toLowerCase()));
        break;
      case DictionarySort.newest:
        sorted.sort((a, b) => (b.validatedAt ?? DateTime(0)).compareTo(a.validatedAt ?? DateTime(0)));
        break;
      case DictionarySort.oldest:
        sorted.sort((a, b) => (a.validatedAt ?? DateTime(0)).compareTo(b.validatedAt ?? DateTime(0)));
        break;
    }

    return sorted;
  });
});
