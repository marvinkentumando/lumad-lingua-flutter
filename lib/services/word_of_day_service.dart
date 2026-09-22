import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dictionary_entry.dart';
import 'offline_service.dart';

class WordOfDayService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  WordOfDayService(this._ref);

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
        final isManual = data['isManual'] as bool? ?? false;

        // If it's a new day, pick a new word
        if (lastPicked.day != now.day ||
            lastPicked.month != now.month ||
            lastPicked.year != now.year) {

          // If it was manually set, we might want to keep it if it's still today
          // but if it's a new day, do we rotate?
          // The user said "override the automatic rotation".
          // Usually this means if an admin set it, it stays until they say otherwise or it expires.
          // Let's implement: if isManual is true, we don't auto-rotate.
          if (isManual) {
            debugPrint('WOTD: New day, but manual override is active. Keeping current word.');
            return wordId != null ? await _fetchWord(wordId) : await _pickNewWord();
          }

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
        debugPrint('WOTD Error in stream: $e. Attempting offline fallback...');
        return await _getOfflineFallback();
      }
    });
  }

  Future<DictionaryEntry?> _getOfflineFallback() async {
    try {
      return await _ref.read(offlineServiceProvider).getRandomCachedWord();
    } catch (e) {
      debugPrint('WOTD Offline fallback failed: $e');
      return null;
    }
  }

  Future<DictionaryEntry?> _fetchWord(String wordId) async {
    try {
      final wordDoc = await _db.collection('words').doc(wordId).get();
      if (!wordDoc.exists) return await _pickNewWord();
      return DictionaryEntry.fromFirestore(wordDoc.data()!, wordDoc.id);
    } catch (e) {
      debugPrint('WOTD: Fetch word failed ($wordId). Falling back to offline cache.');
      return await _getOfflineFallback();
    }
  }

  Future<DictionaryEntry?> _pickNewWord() async {
    try {
      // 1. Pick a random document by starting at a random ID and wrapping around
      // This is the most scalable way to get a random document in Firestore
      final randomId = _db.collection('words').doc().id;
      
      var approvedWords = await _db
          .collection('words')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: randomId)
          .limit(1)
          .get();

      // If no words are found after the random ID, wrap around and start from the beginning
      if (approvedWords.docs.isEmpty) {
        approvedWords = await _db
            .collection('words')
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
          'isManual': false,
        });
      });

      return entry;
    } catch (e) {
      debugPrint('WOTD: Error picking new word: $e. Falling back to offline cache.');
      return await _getOfflineFallback();
    }
  }

  Stream<Map<String, dynamic>?> getWordOfDayMetadata() {
    return _db.collection('global_stats').doc('word_of_day').snapshots().map((doc) => doc.data());
  }

  Future<void> forceNewWord() async {
    await _pickNewWord();
  }

  Future<void> setManualWord(String wordId) async {
    try {
      final wordDoc = await _db.collection('words').doc(wordId).get();
      if (!wordDoc.exists) throw Exception('Word not found');

      final entry = DictionaryEntry.fromFirestore(wordDoc.data()!, wordDoc.id);

      await _db.collection('global_stats').doc('word_of_day').set({
        'wordId': wordId,
        'lastPicked': FieldValue.serverTimestamp(),
        'term': entry.indigenousWord,
        'isManual': true,
      });
    } catch (e) {
      debugPrint('WOTD: Error setting manual word: $e');
      rethrow;
    }
  }

  Future<void> resumeAutomaticRotation() async {
    await _db.collection('global_stats').doc('word_of_day').update({
      'isManual': false,
    });
    // This will trigger a re-pick on the next getWordOfDay call if it's a new day,
    // or we can force it now:
    await _pickNewWord();
  }
}

final wordOfDayServiceProvider = Provider((ref) => WordOfDayService(ref));

final wordOfDayStreamProvider = StreamProvider<DictionaryEntry?>((ref) {
  return ref.watch(wordOfDayServiceProvider).getWordOfDay();
});

final wotdMetadataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(wordOfDayServiceProvider).getWordOfDayMetadata();
});



