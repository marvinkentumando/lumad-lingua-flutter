import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_models.dart';
import '../models/dictionary_entry.dart';
import 'auth_service.dart';

final duelServiceProvider = Provider((ref) => DuelService(ref));

/// Tunables for real-time duel sync. Kept as constants so tests can exercise
/// the math without touching Firestore.
abstract final class DuelSyncConfig {
  /// Seconds each round allows before an auto-timeout answer is submitted.
  static const int secondsPerRound = 15;

  /// A match is considered abandoned when a player's heartbeat is older
  /// than this while the battle is active.
  static const Duration opponentStaleAfter = Duration(seconds: 45);

  /// Waiting matches older than this are swept as cancelled during
  /// matchmaking so stale lobbies can never be joined.
  static const Duration waitingMatchTtl = Duration(seconds: 90);

  /// How often each battling client refreshes its heartbeat.
  static const Duration heartbeatInterval = Duration(seconds: 10);
}

class DuelService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DuelService(this._ref);

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('duel_matches');

  // ── Pure helpers (used by the screen + unit tests) ────────────────────────

  /// Deadline for a 0-based round: the battle start anchored to the server
  /// clock, advanced one round length per round. Both clients compute the
  /// same value from the same document field, so no clock skew is possible.
  static DateTime deadlineForRound(DateTime battleStartedAt, int roundIndex) =>
      battleStartedAt.add(
        Duration(seconds: DuelSyncConfig.secondsPerRound * (roundIndex + 1)),
      );

  /// Seconds remaining for [roundIndex]; never negative.
  static int secondsLeftForRound(DateTime now, DateTime battleStartedAt, int roundIndex) {
    final remaining =
        deadlineForRound(battleStartedAt, roundIndex).difference(now).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  /// True when the opponent's heartbeat is missing or older than the
  /// staleness window while a battle is running.
  static bool isOpponentStale(DuelMatch match, String myId, DateTime now) {
    final opponentId = myId == match.player1Id ? match.player2Id : match.player1Id;
    if (opponentId == null) return false;
    final lastSeen = match.lastSeen[opponentId];
    if (lastSeen == null) return false;
    return now.difference(lastSeen) > DuelSyncConfig.opponentStaleAfter;
  }

  /// Winner id for a finished duel, or null while HP is still positive.
  static String? winnerFromHp(String player1Id, String player2Id, double player1Hp, double player2Hp) {
    if (player1Hp <= 0) return player2Id;
    if (player2Hp <= 0) return player1Id;
    return null;
  }

  // ── Real-time sync ────────────────────────────────────────────────────────

  Stream<DuelMatch?> streamMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map(
          (doc) => doc.exists ? DuelMatch.fromFirestore(doc) : null,
        );
  }

  // ── Matchmaking ───────────────────────────────────────────────────────────

  /// Joins the first fresh, waiting match that is not our own, or creates a
  /// new one. The claim runs inside a transaction so two simultaneous
  /// joiners can never take the same lobby: the transaction re-verifies
  /// `status == waiting` at commit time.
  Future<String> findOrCreateMatch({
    required Map<String, dynamic> userProfile,
    List<DuelQuestion>? questions,
  }) async {
    final userId = _ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    try {
      final waitingMatches = await _matches
          .where('status', isEqualTo: DuelStatus.waiting.name)
          .orderBy('createdAt', descending: false)
          .limit(10)
          .get();

      final now = DateTime.now();
      for (final matchDoc in waitingMatches.docs) {
        final data = matchDoc.data();
        if (data['player1Id'] == userId) continue; // never match ourselves

        // Sweep abandoned lobbies instead of joining them.
        final createdAt = DuelMatch.parseTimestamp(data['createdAt']);
        if (createdAt != null &&
            now.difference(createdAt) > DuelSyncConfig.waitingMatchTtl) {
          await matchDoc.reference
              .update({'status': DuelStatus.cancelled.name})
              .catchError((_) {});
          continue;
        }

        final claimed = await _tryClaimWaitingMatch(matchDoc.reference, userId, userProfile);
        if (claimed) return matchDoc.id;
      }
    } on FirebaseException {
      // Composite index or rules issue: fall through to creating a match.
    }

    return _createMatch(userId, userProfile, questions);
  }

  Future<bool> _tryClaimWaitingMatch(
    DocumentReference<Map<String, dynamic>> matchRef,
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    var claimed = false;
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchRef);
        if (!snapshot.exists) return;
        final data = snapshot.data()!;
        // Re-verify inside the transaction: this is what makes the claim
        // race-free between two joiners.
        if (data['status'] != DuelStatus.waiting.name) return;
        if (data['player1Id'] == userId) return;

        transaction.update(matchRef, {
          'player2Id': userId,
          'player2Name': userProfile['username'] ?? 'Warrior',
          'player2Avatar': userProfile['avatar'] ?? '👤',
          'status': DuelStatus.active.name,
          'battleStartedAt': FieldValue.serverTimestamp(),
          'lastSeen.$userId': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        claimed = true;
      });
      return claimed;
    } on FirebaseException {
      return false;
    }
  }

  Future<String> _createMatch(
    String userId,
    Map<String, dynamic> userProfile,
    List<DuelQuestion>? questions,
  ) async {
    final generated = questions ?? await _generateQuestions();
    final newMatch = DuelMatch(
      id: '',
      player1Id: userId,
      player1Name: userProfile['username'] ?? 'Warrior',
      player1Avatar: userProfile['avatar'] ?? '👤',
      status: DuelStatus.waiting,
      questions: generated,
      createdAt: DateTime.now(),
    );

    final docRef = await _matches.add({
      ...newMatch.toFirestore(),
      'lastSeen.$userId': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<List<DuelQuestion>> _generateQuestions() async {
    // Fetch approved words to build questions. Keep the server filter simple
    // (status only) to avoid a composite-index requirement.
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

  // ── Battle state transitions ──────────────────────────────────────────────

  /// Applies [damage] to [targetPlayerId]'s own HP atomically. Clients send
  /// deltas — never absolute values — so simultaneous round answers cannot
  /// clobber each other, and this transaction — not the UI — decides the
  /// winner the moment a player's HP reaches zero.
  Future<void> applyDamage(String matchId, String targetPlayerId, double damage) async {
    final matchRef = _matches.doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      // Only live duels can take damage; finished/cancelled docs are frozen.
      if (data['status'] != DuelStatus.active.name) return;

      final targetIsPlayer1 = data['player1Id'] == targetPlayerId;
      final hpField = targetIsPlayer1 ? 'player1Hp' : 'player2Hp';
      final currentHp = (data[hpField] as num? ?? 1.0).toDouble();
      final newHp = (currentHp - damage).clamp(0.0, 1.0);

      final updates = <String, dynamic>{hpField: newHp};

      final winnerId = DuelService.winnerFromHp(
        (data['player1Id'] ?? '') as String,
        (data['player2Id'] ?? '') as String,
        targetIsPlayer1 ? newHp : (data['player1Hp'] as num? ?? 1.0).toDouble(),
        targetIsPlayer1 ? (data['player2Hp'] as num? ?? 1.0).toDouble() : newHp,
      );
      if (winnerId != null && winnerId.isNotEmpty) {
        updates.addAll({
          'status': DuelStatus.finished.name,
          'winnerId': winnerId,
          'finishedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(matchRef, updates);
    });
  }

  /// Marks the match finished with the given loser forfeiting. No-op unless
  /// the duel is still active, so a forfeit can never overturn a real result.
  Future<void> forfeitMatch(String matchId, String loserId) async {
    final matchRef = _matches.doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (data['status'] != DuelStatus.active.name) return;

      final loserIsPlayer1 = data['player1Id'] == loserId;
      final winnerId =
          (loserIsPlayer1 ? data['player2Id'] : data['player1Id']) as String?;

      transaction.update(matchRef, {
        'status': DuelStatus.finished.name,
        if (winnerId != null) 'winnerId': winnerId,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Refreshes this player's heartbeat so the opponent can detect a quit.
  Future<void> heartbeat(String matchId, String playerId) {
    return _matches.doc(matchId).update({
      'lastSeen.$playerId': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  /// Advances the round counter exactly once per round and returns the
  /// authoritative (round, roundStartedAt) pair. When both clients try to
  /// advance simultaneously the transaction guarantees a single increment;
  /// the losing client reads back the winner's server timestamp, so both
  /// converge on the same round clock.
  Future<({int round, DateTime? roundStartedAt})> advanceRound(
    String matchId,
    int fromRound,
  ) async {
    final matchRef = _matches.doc(matchId);
    var result = (round: fromRound, roundStartedAt: null as DateTime?);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;

      final currentRound = (data['currentRound'] as num? ?? 0).toInt();
      final roundStartedAt = DuelMatch.parseTimestamp(data['roundStartedAt']);

      if (data['status'] != DuelStatus.active.name || currentRound != fromRound) {
        // Someone else already opened the next round (or the duel ended):
        // adopt their clock instead of writing ours.
        result = (round: currentRound, roundStartedAt: roundStartedAt);
        return;
      }

      transaction.update(matchRef, {
        'currentRound': fromRound + 1,
        'roundStartedAt': FieldValue.serverTimestamp(),
      });
      // Local approximation until the authoritative snapshot arrives.
      result = (round: fromRound + 1, roundStartedAt: DateTime.now());
    });

    return result;
  }

  /// Removes the match document once both clients have had time to observe
  /// the final result, so finished duels don't accumulate forever.
  Future<void> deleteMatch(String matchId) async {
    try {
      await _matches.doc(matchId).delete();
    } on FirebaseException {
      // Already gone or denied; nothing to clean up.
    }
  }

  /// Finds any active or waiting match for [userId] so the session can be restored.
  Future<DuelMatch?> findActiveMatchForUser(String userId) async {
    try {
      // 1. Check if user is player1 in an active or waiting match
      final p1Snap = await _matches
          .where('player1Id', isEqualTo: userId)
          .where('status', whereIn: [DuelStatus.waiting.name, DuelStatus.active.name])
          .limit(1)
          .get();

      if (p1Snap.docs.isNotEmpty) {
        return DuelMatch.fromFirestore(p1Snap.docs.first);
      }

      // 2. Check if user is player2 in an active match
      final p2Snap = await _matches
          .where('player2Id', isEqualTo: userId)
          .where('status', isEqualTo: DuelStatus.active.name)
          .limit(1)
          .get();

      if (p2Snap.docs.isNotEmpty) {
        return DuelMatch.fromFirestore(p2Snap.docs.first);
      }
    } catch (e) {
      debugPrint('Error searching active match for user: $e');
    }
    return null;
  }

  /// Only a still-waiting lobby can be cancelled; active duels must finish
  /// through damage/forfeit so the opponent always sees a final state.
  Future<void> cancelMatch(String matchId) async {
    final matchRef = _matches.doc(matchId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) return;
      if (snapshot.data()!['status'] != DuelStatus.waiting.name) return;
      transaction.update(matchRef, {
        'status': DuelStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Records persistent duel win/loss history and saves a history document.
  /// Uses a transaction to guarantee idempotent execution.
  Future<void> recordDuelResultAndHistory({
    required String userId,
    required bool isWinner,
    required DuelMatch match,
    int xpEarned = 0,
    int mistCrystalsEarned = 0,
  }) async {
    try {
      final historyRef = _db
          .collection('users')
          .doc(userId)
          .collection('duel_history')
          .doc(match.id);

      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((tx) async {
        final historySnap = await tx.get(historyRef);
        // Idempotency check: if this match history already exists, skip
        if (historySnap.exists) return;

        final userSnap = await tx.get(userRef);
        final userData = userSnap.data() ?? {};
        final wins = (userData['duelWins'] ?? 0) as int;
        final losses = (userData['duelLosses'] ?? 0) as int;
        final streak = (userData['duelStreak'] ?? 0) as int;

        tx.update(userRef, {
          'duelWins': isWinner ? wins + 1 : wins,
          'duelLosses': isWinner ? losses : losses + 1,
          'duelStreak': isWinner ? streak + 1 : 0,
        });

        final isPlayer1 = match.player1Id == userId;
        final opponentId = (isPlayer1 ? match.player2Id : match.player1Id) ?? '';
        final opponentName = (isPlayer1 ? match.player2Name : match.player1Name) ?? 'Warrior';
        final opponentAvatar = (isPlayer1 ? match.player2Avatar : match.player1Avatar) ?? '👤';

        final historyItem = DuelHistoryItem(
          id: match.id,
          opponentId: opponentId,
          opponentName: opponentName,
          opponentAvatar: opponentAvatar,
          isWinner: isWinner,
          finalPlayerHp: isPlayer1 ? match.player1Hp : match.player2Hp,
          finalOpponentHp: isPlayer1 ? match.player2Hp : match.player1Hp,
          roundsPlayed: match.currentRound,
          xpEarned: xpEarned,
          mistCrystalsEarned: mistCrystalsEarned,
          timestamp: DateTime.now(),
        );

        tx.set(historyRef, historyItem.toMap());
      });
    } catch (e) {
      debugPrint('Error recording duel result and history: $e');
    }
  }

  /// Legacy helper method for backwards compatibility.
  Future<void> recordDuelResult({
    required String userId,
    required bool isWinner,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final wins = (data['duelWins'] ?? 0) as int;
      final losses = (data['duelLosses'] ?? 0) as int;
      final streak = (data['duelStreak'] ?? 0) as int;

      tx.update(userRef, {
        'duelWins': isWinner ? wins + 1 : wins,
        'duelLosses': isWinner ? losses : losses + 1,
        'duelStreak': isWinner ? streak + 1 : 0,
      });
    });
  }
}
