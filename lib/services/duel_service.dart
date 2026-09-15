import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_models.dart';
import '../models/dictionary_entry.dart';
import 'auth_service.dart';

final duelServiceProvider = Provider((ref) => DuelService(ref));

class DuelService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DuelService(this._ref);

  Stream<DuelMatch?> streamMatch(String matchId) {
    return _db
        .collection('duel_matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? DuelMatch.fromFirestore(doc) : null);
  }

  Future<String> findOrCreateMatch(Map<String, dynamic> userProfile) async {
    final userId = _ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    // 1. Look for waiting matches
    final waitingMatches = await _db
        .collection('duel_matches')
        .where('status', isEqualTo: DuelStatus.waiting.name)
        .where('player1Id', isNotEqualTo: userId)
        .limit(1)
        .get();

    if (waitingMatches.docs.isNotEmpty) {
      final matchDoc = waitingMatches.docs.first;
      await matchDoc.reference.update({
        'player2Id': userId,
        'player2Name': userProfile['username'] ?? 'Warrior',
        'player2Avatar': userProfile['avatar'] ?? '👤',
        'status': DuelStatus.active.name,
      });
      return matchDoc.id;
    }

    // 2. Create new match
    final questions = await _generateQuestions();
    final newMatch = DuelMatch(
      id: '',
      player1Id: userId,
      player1Name: userProfile['username'] ?? 'Warrior',
      player1Avatar: userProfile['avatar'] ?? '👤',
      status: DuelStatus.waiting,
      questions: questions,
      createdAt: DateTime.now(),
    );

    final docRef = await _db.collection('duel_matches').add(newMatch.toFirestore());
    return docRef.id;
  }

  Future<List<DuelQuestion>> _generateQuestions() async {
    // Fetch 15 random approved words to build questions
    final wordsSnap = await _db
        .collection('words')
        .where('status', isEqualTo: 'approved')
        .limit(20)
        .get();

    final allWords = wordsSnap.docs
        .map((d) => DictionaryEntry.fromFirestore(d.data(), d.id))
        .toList();

    if (allWords.length < 4) {
      // Fallback hardcoded if not enough words
      return [
        DuelQuestion(
          question: 'How do you say "Good Morning" in Mansaka?',
          options: ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
          correctIndex: 2,
        ),
      ];
    }

    final random = Random();
    final List<DuelQuestion> generated = [];

    for (int i = 0; i < 5; i++) {
      final correctWord = allWords[random.nextInt(allWords.length)];
      final List<String> options = [correctWord.translation];
      
      // Add 3 unique distractors
      while (options.length < 4) {
        final distractor = allWords[random.nextInt(allWords.length)].translation;
        if (!options.contains(distractor)) {
          options.add(distractor);
        }
      }
      
      options.shuffle();
      generated.add(DuelQuestion(
        question: 'What is the meaning of "${correctWord.indigenousWord}"?',
        options: options,
        correctIndex: options.indexOf(correctWord.translation),
      ));
    }

    return generated;
  }

  Future<void> submitDamage(String matchId, String playerId, double damage) async {
    final matchRef = _db.collection('duel_matches').doc(matchId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final isPlayer1 = data['player1Id'] == playerId;
      
      if (isPlayer1) {
        final currentHp = (data['player2Hp'] as num? ?? 1.0).toDouble();
        final newHp = (currentHp - damage).clamp(0.0, 1.0);
        transaction.update(matchRef, {'player2Hp': newHp});
        
        if (newHp <= 0) {
          transaction.update(matchRef, {
            'status': DuelStatus.finished.name,
            'winnerId': playerId,
          });
        }
      } else {
        final currentHp = (data['player1Hp'] as num? ?? 1.0).toDouble();
        final newHp = (currentHp - damage).clamp(0.0, 1.0);
        transaction.update(matchRef, {'player1Hp': newHp});

        if (newHp <= 0) {
          transaction.update(matchRef, {
            'status': DuelStatus.finished.name,
            'winnerId': playerId,
          });
        }
      }
    });
  }

  Future<void> cancelMatch(String matchId) async {
    await _db.collection('duel_matches').doc(matchId).update({
      'status': DuelStatus.cancelled.name,
    });
  }
}
