import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/duel_models.dart';
import '../models/dictionary_entry.dart';
import 'auth_service.dart';

final duelServiceProvider = Provider((ref) => DuelService(ref));

/// Tunables for real-time duel sync. Kept as constants so tests can exercise
/// the math without network calls.
abstract final class DuelSyncConfig {
  /// Seconds each round allows before an auto-timeout answer is submitted (30s).
  static const int secondsPerRound = 30;

  /// Maximum time a learner waits in matchmaking before timing out.
  static const int matchmakingTimeoutSeconds = 30;

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

  DuelService(this._ref);

  SupabaseClient get _supabase => Supabase.instance.client;

  // ── Pure helpers (used by the screen + unit tests) ────────────────────────

  static DateTime deadlineForRound(DateTime battleStartedAt, int roundIndex) =>
      battleStartedAt.add(
        Duration(seconds: DuelSyncConfig.secondsPerRound * (roundIndex + 1)),
      );

  static int secondsLeftForRound(
      DateTime now, DateTime battleStartedAt, int roundIndex) {
    final remaining =
        deadlineForRound(battleStartedAt, roundIndex).difference(now).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  static bool isOpponentStale(DuelMatch match, String myId, DateTime now) {
    final opponentId =
        myId == match.player1Id ? match.player2Id : match.player1Id;
    if (opponentId == null) return false;
    final lastSeen = match.lastSeen[opponentId];
    if (lastSeen == null) return false;
    return now.difference(lastSeen) > DuelSyncConfig.opponentStaleAfter;
  }

  static String? winnerFromHp(
      String player1Id, String player2Id, double player1Hp, double player2Hp) {
    if (player1Hp <= 0) return player2Id;
    if (player2Hp <= 0) return player1Id;
    return null;
  }

  // ── Real-time sync via Supabase WebSockets ────────────────────────────────

  Stream<DuelMatch?> streamMatch(String matchId) {
    final controller = StreamController<DuelMatch?>.broadcast();

    _supabase
        .from('duel_matches')
        .select()
        .eq('id', matchId)
        .maybeSingle()
        .then((data) {
      if (data != null && !controller.isClosed) {
        controller.add(DuelMatch.fromMap(data));
      }
    }).catchError((e) {
      debugPrint('[SupabaseDuel] Stream initial fetch error: $e');
    });

    final channel = _supabase.channel('public:duel_matches:id=$matchId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duel_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              controller.add(DuelMatch.fromMap(record));
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              controller.add(null);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  // ── Matchmaking ───────────────────────────────────────────────────────────

  Future<String> findOrCreateMatch({
    required Map<String, dynamic> userProfile,
    List<DuelQuestion>? questions,
  }) async {
    final userId = _ref.read(authServiceProvider).currentUser?.uid ??
        _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    try {
      debugPrint('[SupabaseDuelMatchmaking] stage=query_waiting user=$userId');
      final response = await _supabase
          .from('duel_matches')
          .select()
          .eq('status', DuelStatus.waiting.name)
          .order('created_at', ascending: true)
          .limit(25);

      final candidates = (response as List)
          .map((data) => DuelMatch.fromMap(data as Map<String, dynamic>))
          .toList();
      debugPrint('[SupabaseDuelMatchmaking] stage=query_waiting_complete count=${candidates.length}');

      final now = DateTime.now();
      for (final matchDoc in candidates) {
        if (matchDoc.player1Id == userId) continue;

        if (now.difference(matchDoc.createdAt) > DuelSyncConfig.waitingMatchTtl) {
          await _supabase
              .from('duel_matches')
              .update({'status': DuelStatus.cancelled.name})
              .eq('id', matchDoc.id)
              .catchError((_) {});
          continue;
        }

        final claimed = await _tryClaimWaitingMatch(matchDoc.id, userId, userProfile);
        if (claimed) return matchDoc.id;
      }
    } catch (e) {
      debugPrint('[SupabaseDuelMatchmaking] stage=query_waiting_failed error=$e');
      rethrow;
    }

    debugPrint('[SupabaseDuelMatchmaking] stage=create_waiting user=$userId');
    try {
      final matchId = await _createMatch(userId, userProfile, questions);
      debugPrint('[SupabaseDuelMatchmaking] stage=create_waiting_complete matchId=$matchId');
      return matchId;
    } catch (e) {
      debugPrint('[SupabaseDuelMatchmaking] stage=create_waiting_failed error=$e');
      rethrow;
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

    final payload = {
      ...newMatch.toSupabase(),
      'last_seen': {
        userId: DateTime.now().toIso8601String(),
      },
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase.from('duel_matches').insert(payload).select().single();
    return response['id'].toString();
  }

  static bool canClaimMatchData(Map<String, dynamic> data, String userId) {
    final status = data['status'];
    if (status != DuelStatus.waiting.name) return false;

    final player1Id = data['player1_id'] ?? data['player1Id'];
    if (player1Id == userId) return false;

    final player2Id = (data['player2_id'] ?? data['player2Id']) as String?;
    if (player2Id != null && player2Id.isNotEmpty) return false;
    return true;
  }

  Future<bool> _tryClaimWaitingMatch(
    String matchId,
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      debugPrint('[SupabaseDuelMatchmaking] stage=claim_match user=$userId matchId=$matchId');
      final now = DateTime.now().toIso8601String();

      // Transition through introduction -> countdown -> active
      final response = await _supabase
          .from('duel_matches')
          .update({
            'player2_id': userId,
            'player2_name': userProfile['username'] ?? 'Warrior',
            'player2_avatar': userProfile['avatar'] ?? '👤',
            'status': DuelStatus.introduction.name,
            'battle_started_at': now,
            'updated_at': now,
          })
          .eq('id', matchId)
          .eq('status', DuelStatus.waiting.name)
          .select()
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('[SupabaseDuelMatchmaking] stage=claim_match_failed matchId=$matchId error=$e');
      return false;
    }
  }

  /// Dynamic 10-question generation from published public lessons and approved dictionary words.
  Future<List<DuelQuestion>> _generateQuestions() async {
    List<DuelQuestion> generated = [];
    try {
      // 1. Fetch published public lessons
      final lessonsRes = await _supabase
          .from('lessons')
          .select()
          .eq('status', 'PUBLISHED')
          .limit(20);

      for (var l in (lessonsRes as List)) {
        final lessonMap = Map<String, dynamic>.from(l as Map);
        final docEducatorId = lessonMap['educator_id'] ?? lessonMap['educatorId'];
        if (docEducatorId != null && docEducatorId.toString().isNotEmpty) {
          continue;
        }

        final tasks = lessonMap['tasks'] as List?;
        if (tasks != null) {
          for (var t in tasks) {
            final taskMap = Map<String, dynamic>.from(t);
            final questionText = taskMap['questionText'] ?? '';
            final options = List<String>.from(taskMap['options'] ?? []);
            final correctIndex = taskMap['correctAnswerIndex'] ?? 0;
            if (questionText.isNotEmpty && options.length >= 2) {
              generated.add(DuelQuestion(
                question: questionText,
                options: options,
                correctIndex: correctIndex,
                type: taskMap['type'] ?? 'multipleChoice',
              ));
            }
          }
        }
      }

      // 2. Fetch approved dictionary words for diverse question types (MCQ, Reverse Translation, Matching)
      final response = await _supabase
          .from('words')
          .select()
          .eq('status', 'approved')
          .limit(40);

      final allWords = (response as List)
          .map((d) => DictionaryEntry.fromFirestore(d as Map<String, dynamic>, d['id']?.toString() ?? ''))
          .toList();

      if (allWords.length >= 4) {
        final random = Random();
        for (int i = 0; i < 15 && generated.length < 10; i++) {
          final word = allWords[random.nextInt(allWords.length)];
          final typeChoice = random.nextInt(3);

          if (typeChoice == 0) {
            final options = [word.translation];
            while (options.length < 4) {
              final dist = allWords[random.nextInt(allWords.length)].translation;
              if (!options.contains(dist)) options.add(dist);
            }
            options.shuffle();
            generated.add(DuelQuestion(
              question: 'What is the English meaning of "${word.indigenousWord}"?',
              options: options,
              correctIndex: options.indexOf(word.translation),
              type: 'multipleChoice',
            ));
          } else if (typeChoice == 1) {
            final options = [word.indigenousWord];
            while (options.length < 4) {
              final dist = allWords[random.nextInt(allWords.length)].indigenousWord;
              if (!options.contains(dist)) options.add(dist);
            }
            options.shuffle();
            generated.add(DuelQuestion(
              question: 'How do you say "${word.translation}" in Mansaka?',
              options: options,
              correctIndex: options.indexOf(word.indigenousWord),
              type: 'reverseTranslation',
            ));
          } else {
            final options = [word.translation];
            while (options.length < 4) {
              final dist = allWords[random.nextInt(allWords.length)].translation;
              if (!options.contains(dist)) options.add(dist);
            }
            options.shuffle();
            generated.add(DuelQuestion(
              question: 'Select the correct translation for: "${word.translation}"',
              options: options,
              correctIndex: options.indexOf(word.translation),
              type: 'matchingType',
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating questions from published lessons and words: $e');
    }

    // Ensure exactly 10 questions
    while (generated.length < 10) {
      generated.add(DuelQuestion(
        question: 'How do you say "Good Morning" in Mansaka?',
        options: ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
        correctIndex: 2,
        type: 'multipleChoice',
      ));
      generated.add(DuelQuestion(
        question: 'What is the meaning of "Duta"?',
        options: ['Land / Earth', 'Lake / River', 'Sun / Day', 'Night / Sky'],
        correctIndex: 0,
        type: 'multipleChoice',
      ));
      generated.add(DuelQuestion(
        question: 'How do you say "Water" in Mansaka?',
        options: ['Tubig', 'Duta', 'Langit', 'Bulan'],
        correctIndex: 0,
        type: 'reverseTranslation',
      ));
    }

    if (generated.length > 10) {
      generated = generated.sublist(0, 10);
    }
    return generated;
  }

  Future<List<DuelHistoryItem>> fetchUserDuelHistory(String userId) async {
    try {
      final response = await _supabase
          .from('duel_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((d) => DuelHistoryItem.fromMap(d as Map<String, dynamic>, d['id']?.toString() ?? ''))
          .toList();
    } catch (e) {
      debugPrint('Error fetching duel history: $e');
      return [];
    }
  }

  // ── Battle state transitions ──────────────────────────────────────────────

  /// Applies damage (10 damage per correct answer) to [targetPlayerId]'s HP atomically.
  Future<void> applyDamage(
      String matchId, String targetPlayerId, double damage) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (matchData == null) return;
      final statusStr = matchData['status']?.toString();
      if (statusStr != DuelStatus.active.name && statusStr != DuelStatus.countdown.name) {
        return;
      }

      final match = DuelMatch.fromMap(matchData);
      final targetIsPlayer1 = match.player1Id == targetPlayerId;
      final currentHp = targetIsPlayer1 ? match.player1Hp : match.player2Hp;
      final newHp = (currentHp - damage).clamp(0.0, 100.0);

      final updates = <String, dynamic>{
        targetIsPlayer1 ? 'player1_hp' : 'player2_hp': newHp,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('duel_matches').update(updates).eq('id', matchId);
    } catch (e) {
      debugPrint('Error applying damage in Supabase: $e');
    }
  }

  Future<void> forfeitMatch(String matchId, String loserId) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (matchData == null) return;

      final match = DuelMatch.fromMap(matchData);
      final loserIsPlayer1 = match.player1Id == loserId;
      final winnerId = loserIsPlayer1 ? match.player2Id : match.player1Id;

      await _supabase.from('duel_matches').update({
        'status': DuelStatus.finished.name,
        if (winnerId != null) 'winner_id': winnerId,
        'finished_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);
    } catch (e) {
      debugPrint('Error forfeiting match in Supabase: $e');
    }
  }

  Future<void> heartbeat(String matchId, String playerId) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select('last_seen')
          .eq('id', matchId)
          .maybeSingle();

      final lastSeenMap = Map<String, dynamic>.from(matchData?['last_seen'] ?? {});
      lastSeenMap[playerId] = DateTime.now().toIso8601String();

      await _supabase
          .from('duel_matches')
          .update({'last_seen': lastSeenMap})
          .eq('id', matchId);
    } catch (_) {}
  }

  Future<({int round, DateTime? roundStartedAt})> advanceRound(
    String matchId,
    int fromRound,
  ) async {
    try {
      final now = DateTime.now();
      final nextRound = fromRound + 1;
      final updateData = <String, dynamic>{
        'current_round': nextRound,
        'round_started_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      if (nextRound >= 10) {
        updateData['status'] = DuelStatus.finished.name;
        updateData['finished_at'] = now.toIso8601String();
      }

      final response = await _supabase
          .from('duel_matches')
          .update(updateData)
          .eq('id', matchId)
          .eq('current_round', fromRound)
          .select()
          .maybeSingle();

      if (response != null) {
        return (round: nextRound, roundStartedAt: now);
      } else {
        final current = await _supabase
            .from('duel_matches')
            .select()
            .eq('id', matchId)
            .maybeSingle();
        if (current != null) {
          final m = DuelMatch.fromMap(current);
          return (round: m.currentRound, roundStartedAt: m.roundStartedAt);
        }
      }
    } catch (e) {
      debugPrint('Error advancing round in Supabase: $e');
    }
    return (round: fromRound, roundStartedAt: null);
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('duel_matches').delete().eq('id', matchId);
    } catch (_) {}
  }

  Future<DuelMatch?> findActiveMatchForUser(String userId) async {
    try {
      final p1Response = await _supabase
          .from('duel_matches')
          .select()
          .eq('player1_id', userId)
          .inFilter('status', [DuelStatus.active.name, DuelStatus.introduction.name, DuelStatus.countdown.name, DuelStatus.rematchPending.name])
          .limit(1);

      if (p1Response.isNotEmpty) {
        return DuelMatch.fromMap(p1Response[0]);
      }

      final p2Response = await _supabase
          .from('duel_matches')
          .select()
          .eq('player2_id', userId)
          .inFilter('status', [DuelStatus.active.name, DuelStatus.introduction.name, DuelStatus.countdown.name, DuelStatus.rematchPending.name])
          .limit(1);

      if (p2Response.isNotEmpty) {
        return DuelMatch.fromMap(p2Response[0]);
      }
    } catch (e) {
      debugPrint('Error searching active match for user in Supabase: $e');
    }
    return null;
  }

  Future<void> cancelMatch(String matchId) async {
    try {
      await _supabase
          .from('duel_matches')
          .update({
            'status': DuelStatus.cancelled.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .eq('status', DuelStatus.waiting.name);
    } catch (e) {
      debugPrint('Error cancelling match $matchId in Supabase: $e');
    }
  }

  /// Rematch coordination: request rematch for a player.
  Future<void> requestRematch(String matchId, String userId) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (matchData == null) return;
      final match = DuelMatch.fromMap(matchData);
      final isPlayer1 = match.player1Id == userId;

      final updates = <String, dynamic>{
        isPlayer1 ? 'player1_rematch' : 'player2_rematch': true,
        'status': DuelStatus.rematchPending.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final otherRematch = isPlayer1 ? match.player2Rematch : match.player1Rematch;
      if (otherRematch) {
        // Both want rematch! Reset match for new round
        final newQuestions = await _generateQuestions();
        updates['player1_hp'] = 100.0;
        updates['player2_hp'] = 100.0;
        updates['current_round'] = 0;
        updates['winner_id'] = null;
        updates['player1_rematch'] = false;
        updates['player2_rematch'] = false;
        updates['questions'] = newQuestions.map((q) => q.toMap()).toList();
        updates['status'] = DuelStatus.introduction.name;
        updates['battle_started_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('duel_matches').update(updates).eq('id', matchId);
    } catch (e) {
      debugPrint('Error requesting rematch: $e');
    }
  }

  Future<void> recordDuelResultAndHistory({
    required String userId,
    required bool isWinner,
    required DuelMatch match,
    int xpEarned = 0,
    int mistCrystalsEarned = 0,
  }) async {
    try {
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

      await _supabase.from('duel_history').upsert({
        'id': match.id,
        'user_id': userId,
        ...historyItem.toSupabase(),
      });
    } catch (e) {
      debugPrint('Error recording duel result and history in Supabase: $e');
    }
  }

  Future<void> recordDuelResult({
    required String userId,
    required bool isWinner,
  }) async {
    try {
      await recordDuelResultAndHistory(
        userId: userId,
        isWinner: isWinner,
        match: DuelMatch(
          id: 'legacy_${DateTime.now().millisecondsSinceEpoch}',
          player1Id: userId,
          player1Name: 'Warrior',
          player1Avatar: '👤',
          status: DuelStatus.finished,
          questions: [],
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }
}
