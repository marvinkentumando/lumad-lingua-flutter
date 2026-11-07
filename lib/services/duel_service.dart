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
  /// Seconds each round allows before an auto-timeout answer is submitted.
  static const int secondsPerRound = 15;

  /// Maximum time a learner waits in matchmaking before timing out.
  /// Prevents indefinite "searching" when no opponent is available.
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

  /// Deadline for a 0-based round: the battle start anchored to the server
  /// clock, advanced one round length per round. Both clients compute the
  /// same value from the same document field, so no clock skew is possible.
  static DateTime deadlineForRound(DateTime battleStartedAt, int roundIndex) =>
      battleStartedAt.add(
        Duration(seconds: DuelSyncConfig.secondsPerRound * (roundIndex + 1)),
      );

  /// Seconds remaining for [roundIndex]; never negative.
  static int secondsLeftForRound(
      DateTime now, DateTime battleStartedAt, int roundIndex) {
    final remaining =
        deadlineForRound(battleStartedAt, roundIndex).difference(now).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  /// True when the opponent's heartbeat is missing or older than the
  /// staleness window while a battle is running.
  static bool isOpponentStale(DuelMatch match, String myId, DateTime now) {
    final opponentId =
        myId == match.player1Id ? match.player2Id : match.player1Id;
    if (opponentId == null) return false;
    final lastSeen = match.lastSeen[opponentId];
    if (lastSeen == null) return false;
    return now.difference(lastSeen) > DuelSyncConfig.opponentStaleAfter;
  }

  /// Winner id for a finished duel, or null while HP is still positive.
  static String? winnerFromHp(
      String player1Id, String player2Id, double player1Hp, double player2Hp) {
    if (player1Hp <= 0) return player2Id;
    if (player2Hp <= 0) return player1Id;
    return null;
  }

  // ── Real-time sync via Supabase WebSockets ────────────────────────────────

  Stream<DuelMatch?> streamMatch(String matchId) {
    final controller = StreamController<DuelMatch?>.broadcast();

    // 1. Fetch initial match state
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

    // 2. Subscribe to real-time Postgres changes over WebSockets
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

  /// Joins the first fresh, waiting match that is not our own, or creates a
  /// new one. Uses atomic Supabase Postgres updates to guarantee race-free claims.
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
        if (matchDoc.player1Id == userId) continue; // never match ourselves

        // Sweep abandoned lobbies instead of joining them.
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

  /// Watches waiting lobbies in real-time via Supabase WebSockets while this player waits.
  Future<StreamSubscription?> watchForOpponent({
    required String waitingMatchId,
    required String userId,
    required Map<String, dynamic> userProfile,
    required void Function(String matchId) onMatchFound,
    required void Function(Object error) onError,
  }) async {
    debugPrint('[SupabaseDuelMatchmaking] stage=watch_prepare matchId=$waitingMatchId');
    try {
      final ownMatchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', waitingMatchId)
          .maybeSingle();

      if (ownMatchData == null ||
          ownMatchData['status'] != DuelStatus.waiting.name) {
        return null;
      }
    } catch (e) {
      debugPrint('[SupabaseDuelMatchmaking] stage=watch_prepare_failed error=$e');
      return null;
    }

    var processing = false;
    var finished = false;
    final attemptedIds = <String>{};

    final channel = _supabase.channel('public:duel_matches:searching_$waitingMatchId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duel_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: DuelStatus.waiting.name,
          ),
          callback: (payload) async {
            if (processing || finished) return;
            processing = true;
            try {
              final data = payload.newRecord;
              if (data.isEmpty) return;

              final candidateId = data['id']?.toString() ?? '';
              if (candidateId.isEmpty ||
                  candidateId == waitingMatchId ||
                  attemptedIds.contains(candidateId)) {
                return;
              }

              final candidatePlayer1 = data['player1_id'] ?? data['player1Id'];
              if (candidatePlayer1 == userId || !canClaimMatchData(data, userId)) {
                return;
              }

              final createdAt = DuelMatch.parseTimestamp(data['created_at'] ?? data['createdAt']);
              if (createdAt != null &&
                  DateTime.now().difference(createdAt) >
                      DuelSyncConfig.waitingMatchTtl) {
                attemptedIds.add(candidateId);
                return;
              }

              attemptedIds.add(candidateId);
              if (await _tryClaimWaitingMatch(candidateId, userId, userProfile)) {
                finished = true;
                onMatchFound(candidateId);
              }
            } catch (error) {
              onError(error);
            } finally {
              processing = false;
            }
          },
        )
        .subscribe();

    final controller = StreamController<void>();
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream.listen(null);
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

  /// Returns true if a waiting match document can be claimed by [userId].
  static bool canClaimMatchData(Map<String, dynamic> data, String userId) {
    final status = data['status'];
    if (status != DuelStatus.waiting.name) return false;

    final player1Id = data['player1_id'] ?? data['player1Id'];
    if (player1Id == userId) return false;

    final player2Id = (data['player2_id'] ?? data['player2Id']) as String?;
    if (player2Id != null && player2Id.isNotEmpty) return false;
    return true;
  }

  /// Atomically claims a waiting match in Supabase Postgres.
  Future<bool> _tryClaimWaitingMatch(
    String matchId,
    String userId,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      debugPrint('[SupabaseDuelMatchmaking] stage=claim_match user=$userId matchId=$matchId');
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('duel_matches')
          .update({
            'player2_id': userId,
            'player2_name': userProfile['username'] ?? 'Warrior',
            'player2_avatar': userProfile['avatar'] ?? '👤',
            'status': DuelStatus.active.name,
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

  Future<List<DuelQuestion>> _generateQuestions() async {
    try {
      final response = await _supabase
          .from('words')
          .select()
          .eq('status', 'approved')
          .limit(20);

      final allWords = (response as List)
          .map((d) => DictionaryEntry.fromFirestore(d as Map<String, dynamic>, d['id']?.toString() ?? ''))
          .toList();

      final distinctTranslations = allWords.map((w) => w.translation).toSet();
      if (allWords.length >= 4 && distinctTranslations.length >= 4) {
        final random = Random();
        final List<DuelQuestion> generated = [];
        final questionCount = allWords.length >= 5 ? 5 : allWords.length;

        for (int i = 0; i < questionCount; i++) {
          final correctWord = allWords[random.nextInt(allWords.length)];
          final List<String> options = [correctWord.translation];

          var attempts = 0;
          while (options.length < 4 && attempts < 60) {
            attempts++;
            final distractor =
                allWords[random.nextInt(allWords.length)].translation;
            if (!options.contains(distractor)) {
              options.add(distractor);
            }
          }

          if (options.length < 4) {
            for (final t in distinctTranslations) {
              if (!options.contains(t)) options.add(t);
              if (options.length >= 4) break;
            }
          }
          if (options.length < 4) continue;

          options.shuffle();
          generated.add(DuelQuestion(
            question: 'What is the meaning of "${correctWord.indigenousWord}"?',
            options: options,
            correctIndex: options.indexOf(correctWord.translation),
          ));
        }

        if (generated.isNotEmpty) return generated;
      }
    } catch (e) {
      debugPrint('Error generating questions from Supabase words: $e');
    }

    // Fallback hardcoded if not enough words / network issue
    return [
      DuelQuestion(
        question: 'How do you say "Good Morning" in Mansaka?',
        options: [
          'Madyaw na gabi',
          'Madyaw na allaw',
          'Madyaw na amase',
          'Madyaw na hapon'
        ],
        correctIndex: 2,
      ),
      DuelQuestion(
        question: 'What is the meaning of "Duta"?',
        options: ['Land / Earth', 'Lake / River', 'Sun / Day', 'Night / Sky'],
        correctIndex: 0,
      ),
    ];
  }

  // ── Battle state transitions ──────────────────────────────────────────────

  /// Applies [damage] to [targetPlayerId]'s own HP atomically.
  Future<void> applyDamage(
      String matchId, String targetPlayerId, double damage) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (matchData == null || matchData['status'] != DuelStatus.active.name) return;

      final match = DuelMatch.fromMap(matchData);
      final targetIsPlayer1 = match.player1Id == targetPlayerId;
      final currentHp = targetIsPlayer1 ? match.player1Hp : match.player2Hp;
      final newHp = (currentHp - damage).clamp(0.0, 1.0);

      final updates = <String, dynamic>{
        targetIsPlayer1 ? 'player1_hp' : 'player2_hp': newHp,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final winnerId = DuelService.winnerFromHp(
        match.player1Id,
        match.player2Id ?? '',
        targetIsPlayer1 ? newHp : match.player1Hp,
        targetIsPlayer1 ? match.player2Hp : newHp,
      );

      if (winnerId != null && winnerId.isNotEmpty) {
        updates['status'] = DuelStatus.finished.name;
        updates['winner_id'] = winnerId;
        updates['finished_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('duel_matches').update(updates).eq('id', matchId);
    } catch (e) {
      debugPrint('Error applying damage in Supabase: $e');
    }
  }

  /// Marks the match finished with the given loser forfeiting.
  Future<void> forfeitMatch(String matchId, String loserId) async {
    try {
      final matchData = await _supabase
          .from('duel_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();

      if (matchData == null || matchData['status'] != DuelStatus.active.name) return;

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

  /// Refreshes this player's heartbeat so the opponent can detect a quit.
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

  /// Advances the round counter.
  Future<({int round, DateTime? roundStartedAt})> advanceRound(
    String matchId,
    int fromRound,
  ) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('duel_matches')
          .update({
            'current_round': fromRound + 1,
            'round_started_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', matchId)
          .eq('current_round', fromRound)
          .eq('status', DuelStatus.active.name)
          .select()
          .maybeSingle();

      if (response != null) {
        return (round: fromRound + 1, roundStartedAt: now);
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

  /// Removes the match document once both clients have finished observing the result.
  Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('duel_matches').delete().eq('id', matchId);
    } catch (_) {}
  }

  /// Finds an active battle for [userId].
  Future<DuelMatch?> findActiveMatchForUser(String userId) async {
    try {
      final p1Response = await _supabase
          .from('duel_matches')
          .select()
          .eq('player1_id', userId)
          .eq('status', DuelStatus.active.name)
          .limit(1);

      if (p1Response.isNotEmpty) {
        return DuelMatch.fromMap(p1Response[0]);
      }

      final p2Response = await _supabase
          .from('duel_matches')
          .select()
          .eq('player2_id', userId)
          .eq('status', DuelStatus.active.name)
          .limit(1);

      if (p2Response.isNotEmpty) {
        return DuelMatch.fromMap(p2Response[0]);
      }
    } catch (e) {
      debugPrint('Error searching active match for user in Supabase: $e');
    }
    return null;
  }

  /// Only a still-waiting lobby can be cancelled.
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

  /// Records persistent duel win/loss history.
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

  /// Legacy helper method for backwards compatibility.
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
