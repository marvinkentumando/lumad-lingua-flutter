import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';

class WordOfDayService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DictionaryEntry?> getWordOfDay() {
    return _db.collection('global_stats').doc('word_of_day').snapshots().asyncMap((
      doc,
    ) async {
      try {
        final now = DateTime.now();

        if (!doc.exists) {
          debugPrint('WOTD: Document does not exist. Picking new word...');
          return await _pickNewWord();
        }

        final data = doc.data()!;
        final lastPickedTs = data['lastPicked'] as Timestamp?;
        final wordId = data['wordId'] as String?;

        // If the timestamp is null, it's likely a local optimistic update.
        // If we already have a wordId, we can try to show it instead of re-picking.
        if (lastPickedTs == null) {
          if (wordId != null) {
            return await _fetchWord(wordId);
          }
          return await _pickNewWord();
        }

        final lastPicked = lastPickedTs.toDate();

        // If it's a new day, pick a new word
        if (lastPicked.day != now.day ||
            lastPicked.month != now.month ||
            lastPicked.year != now.year) {
          // Only pick if we aren't currently waiting for a write to complete
          if (doc.metadata.hasPendingWrites) {
            return wordId != null ? await _fetchWord(wordId) : null;
          }

          debugPrint('WOTD: New day detected. Picking new word...');
          return await _pickNewWord();
        }

        // Otherwise, return the current one
        if (wordId == null) return await _pickNewWord();
        return await _fetchWord(wordId);
      } catch (e) {
        debugPrint('WOTD Error in stream: $e');
        return null;
      }
    });
  }

  Future<DictionaryEntry?> _fetchWord(String wordId) async {
    final wordDoc = await _db.collection('words').doc(wordId).get();
    if (!wordDoc.exists) return await _pickNewWord();
    return DictionaryEntry.fromFirestore(wordDoc.data()!, wordDoc.id);
  }

  Future<DictionaryEntry?> _pickNewWord() async {
    try {
      // 1. Pick a random document by starting at a random ID and wrapping around
      // This is the most scalable way to get a random document in Firestore
      final randomId = _db.collection('words').doc().id;
      
      var approvedWords = await _db
          .collection('words')
          .where('status', isEqualTo: 'approved')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: randomId)
          .limit(1)
          .get();

      // If no words are found after the random ID, wrap around and start from the beginning
      if (approvedWords.docs.isEmpty) {
        approvedWords = await _db
            .collection('words')
            .where('status', isEqualTo: 'approved')
            .where(FieldPath.documentId, isLessThan: randomId)
            .limit(1)
            .get();
      }

      if (approvedWords.docs.isEmpty) {
        debugPrint('WOTD: No approved words found in database.');
        return null;
      }

      final selectedDoc = approvedWords.docs.first;
      final entry = DictionaryEntry.fromFirestore(
        selectedDoc.data(),
        selectedDoc.id,
      );

      // 2. Update global stats (ignoring if someone else beat us to it)
      await _db.runTransaction((transaction) async {
        final docRef = _db.collection('global_stats').doc('word_of_day');
        final doc = await transaction.get(docRef);
        final now = DateTime.now();

        if (doc.exists) {
          final data = doc.data()!;
          final lastPickedTs = data['lastPicked'] as Timestamp?;
          if (lastPickedTs != null) {
            final lastPicked = lastPickedTs.toDate();
            if (lastPicked.day == now.day &&
                lastPicked.month == now.month &&
                lastPicked.year == now.year) {
              return; // Already updated today
            }
          }
        }

        transaction.set(docRef, {
          'wordId': selectedDoc.id,
          'lastPicked': FieldValue.serverTimestamp(),
          'term': entry.indigenousWord,
        });
      });

      return entry;
    } catch (e) {
      debugPrint('WOTD: Error picking new word: $e');
      return null;
    }
  }
}

final wordOfDayServiceProvider = Provider((ref) => WordOfDayService());

final wordOfDayStreamProvider = StreamProvider<DictionaryEntry?>((ref) {
  return ref.watch(wordOfDayServiceProvider).getWordOfDay();
});



