import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';
import '../services/word_of_day_service.dart';

/// Provides the Word of the Day, synced globally via Firestore.
/// This is a StreamProvider to handle real-time updates and loading states.
final wordOfTheDayProvider = StreamProvider<DictionaryEntry?>((ref) {
  return ref.watch(wordOfDayServiceProvider).getWordOfDay();
});


