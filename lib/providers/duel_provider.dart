import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_models.dart';
import '../models/quest.dart';
import '../services/duel_service.dart';
import '../services/auth_service.dart';
import 'quest_provider.dart';
import 'student_provider.dart';

enum DuelPhase { idle, searching, matchFound, battling, results }

class DuelSessionState {
  final DuelPhase phase;
  final String? matchId;
  final DuelMatch? match;
  final bool isLoading;
  final String? error;
  final String? myId;
  final String? opponentId;
  final String opponentName;
  final bool isHost;
  final double playerHp;
  final double opponentHp;
  final int currentQuestionIndex;
  final int secondsLeft;
  final bool isPlayerWinning;
  final bool showPlayerDamageEffect;
  final bool showOpponentDamageEffect;
  final bool answerLocked;
  final bool rewardsAwarded;
  final bool resultsRecorded;
  final List<DuelQuestion> battleQuestions;
  final int uiRound;
  final DateTime? uiRoundStartedAt;

  DuelSessionState({
    this.phase = DuelPhase.idle,
    this.matchId,
    this.match,
    this.isLoading = false,
    this.error,
    this.myId,
    this.opponentId,
    this.opponentName = 'Ancestral Guardian',
    this.isHost = false,
    this.playerHp = 1.0,
    this.opponentHp = 1.0,
    this.currentQuestionIndex = 0,
    this.secondsLeft = DuelSyncConfig.secondsPerRound,
    this.isPlayerWinning = true,
    this.showPlayerDamageEffect = false,
    this.showOpponentDamageEffect = false,
    this.answerLocked = false,
    this.rewardsAwarded = false,
    this.resultsRecorded = false,
    this.battleQuestions = const [],
    this.uiRound = 0,
    this.uiRoundStartedAt,
  });

  DuelSessionState copyWith({
    DuelPhase? phase,
    String? matchId,
    DuelMatch? match,
    bool? isLoading,
    String? error,
    String? myId,
    String? opponentId,
    String? opponentName,
    bool? isHost,
    double? playerHp,
    double? opponentHp,
    int? currentQuestionIndex,
    int? secondsLeft,
    bool? isPlayerWinning,
    bool? showPlayerDamageEffect,
    bool? showOpponentDamageEffect,
    bool? answerLocked,
    bool? rewardsAwarded,
    bool? resultsRecorded,
    List<DuelQuestion>? battleQuestions,
    int? uiRound,
    DateTime? uiRoundStartedAt,
  }) {
    return DuelSessionState(
      phase: phase ?? this.phase,
      matchId: matchId ?? this.matchId,
      match: match ?? this.match,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      myId: myId ?? this.myId,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      isHost: isHost ?? this.isHost,
      playerHp: playerHp ?? this.playerHp,
      opponentHp: opponentHp ?? this.opponentHp,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      isPlayerWinning: isPlayerWinning ?? this.isPlayerWinning,
      showPlayerDamageEffect: showPlayerDamageEffect ?? this.showPlayerDamageEffect,
      showOpponentDamageEffect: showOpponentDamageEffect ?? this.showOpponentDamageEffect,
      answerLocked: answerLocked ?? this.answerLocked,
      rewardsAwarded: rewardsAwarded ?? this.rewardsAwarded,
      resultsRecorded: resultsRecorded ?? this.resultsRecorded,
      battleQuestions: battleQuestions ?? this.battleQuestions,
      uiRound: uiRound ?? this.uiRound,
      uiRoundStartedAt: uiRoundStartedAt ?? this.uiRoundStartedAt,
    );
  }
}

class DuelSessionNotifier extends Notifier<DuelSessionState> {
  StreamSubscription<DuelMatch?>? _subscription;
  Timer? _roundTimer;
  Timer? _heartbeatTimer;

  @override
  DuelSessionState build() {
    ref.onDispose(() {
      _cancelTimersAndSubscriptions();
    });
    return DuelSessionState();
  }

  void _cancelTimersAndSubscriptions() {
    _subscription?.cancel();
    _subscription = null;
    _roundTimer?.cancel();
    _roundTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Re-attaches to an existing active or waiting match for the user if present.
  Future<void> checkAndRestoreActiveSession() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    // Do not override if already in active searching/battling state in memory
    if (state.phase == DuelPhase.battling || state.phase == DuelPhase.searching) {
      return;
    }

    try {
      final duelService = ref.read(duelServiceProvider);
      final activeMatch = await duelService.findActiveMatchForUser(user.uid);
      if (activeMatch != null && activeMatch.status != DuelStatus.finished && activeMatch.status != DuelStatus.cancelled) {
        state = state.copyWith(
          myId: user.uid,
          matchId: activeMatch.id,
          match: activeMatch,
        );
        _listenToMatch(activeMatch.id);
      }
    } catch (e) {
      debugPrint('Error restoring active session: $e');
    }
  }

  Future<void> startMatchmaking({
    required Map<String, dynamic> userProfile,
    List<DuelQuestion>? questions,
  }) async {
    _cancelTimersAndSubscriptions();

    state = DuelSessionState(
      phase: DuelPhase.searching,
      isLoading: true,
    );

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      state = state.copyWith(phase: DuelPhase.idle, isLoading: false);
      return;
    }

    final myId = user.uid;
    state = state.copyWith(myId: myId);

    try {
      final duelService = ref.read(duelServiceProvider);
      final matchId = await duelService.findOrCreateMatch(
        userProfile: userProfile,
        questions: questions,
      );

      state = state.copyWith(matchId: matchId, isLoading: false);
      _listenToMatch(matchId);
    } catch (e) {
      debugPrint('Matchmaking error in provider: $e');
      state = state.copyWith(phase: DuelPhase.idle, isLoading: false, error: e.toString());
    }
  }

  void _listenToMatch(String matchId) {
    _subscription?.cancel();
    _subscription = ref
        .read(duelServiceProvider)
        .streamMatch(matchId)
        .listen(_onMatchUpdate, onError: (e) {
      debugPrint('Match stream error in provider: $e');
    });
  }

  void _onMatchUpdate(DuelMatch? match) {
    if (match == null) {
      if (state.phase == DuelPhase.battling || state.phase == DuelPhase.searching) {
        _finishLocally(won: state.playerHp >= state.opponentHp, opponentGone: true);
      }
      return;
    }

    state = state.copyWith(match: match);

    switch (match.status) {
      case DuelStatus.waiting:
        if (state.phase != DuelPhase.searching) {
          state = state.copyWith(phase: DuelPhase.searching);
        }
        break;

      case DuelStatus.active:
        if (state.phase == DuelPhase.searching || state.phase == DuelPhase.idle) {
          _onBattleStart(match);
        } else if (state.phase == DuelPhase.battling || state.phase == DuelPhase.matchFound) {
          _onBattleUpdate(match);
        }
        break;

      case DuelStatus.finished:
      case DuelStatus.cancelled:
        if (state.phase == DuelPhase.battling || state.phase == DuelPhase.searching || state.phase == DuelPhase.matchFound) {
          final myId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid ?? '';
          final won = match.winnerId != null
              ? match.winnerId == myId
              : state.playerHp >= state.opponentHp;
          _finishLocally(won: won, cancelled: match.status == DuelStatus.cancelled);
        }
        break;
    }
  }

  void _onBattleStart(DuelMatch match) {
    final myId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid ?? '';
    final isPlayer1 = match.player1Id == myId;
    final opponentId = isPlayer1 ? match.player2Id : match.player1Id;
    final opponentName = (isPlayer1 ? match.player2Name : match.player1Name) ?? 'Warrior';
    final pHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    final oHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    _roundTimer?.cancel();

    state = state.copyWith(
      phase: DuelPhase.matchFound,
      myId: myId,
      isHost: isPlayer1,
      opponentId: opponentId,
      opponentName: opponentName,
      battleQuestions: match.questions,
      playerHp: pHp,
      opponentHp: oHp,
      currentQuestionIndex: 0,
      uiRound: 0,
      uiRoundStartedAt: match.battleStartedAt,
      secondsLeft: DuelSyncConfig.secondsPerRound,
    );

    _startHeartbeat();

    // Transition to battling in 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (state.phase == DuelPhase.matchFound) {
        state = state.copyWith(phase: DuelPhase.battling);
        _startTimer(DuelSyncConfig.secondsPerRound);
      }
    });
  }

  void _onBattleUpdate(DuelMatch match) {
    final myId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid ?? '';
    final isPlayer1 = match.player1Id == myId;

    final newPlayerHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    final newOpponentHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    final remote = !match.hasPendingWrites;
    final showPlayerDamage = remote && newPlayerHp < state.playerHp && !state.showPlayerDamageEffect;
    final showOpponentDamage = remote && newOpponentHp < state.opponentHp && !state.showOpponentDamageEffect;

    int newUiRound = state.uiRound;
    DateTime? newUiRoundStartedAt = state.uiRoundStartedAt;
    int newQuestionIndex = state.currentQuestionIndex;
    bool newAnswerLocked = state.answerLocked;

    if (state.uiRound != match.currentRound && match.roundStartedAt != null) {
      newUiRound = match.currentRound;
      newUiRoundStartedAt = match.roundStartedAt;
      if (match.currentRound < state.battleQuestions.length && state.answerLocked) {
        newAnswerLocked = false;
        newQuestionIndex = match.currentRound;
        _roundTimer?.cancel();
        _startTimer(DuelSyncConfig.secondsPerRound);
      }
    }

    state = state.copyWith(
      playerHp: newPlayerHp,
      opponentHp: newOpponentHp,
      showPlayerDamageEffect: showPlayerDamage,
      showOpponentDamageEffect: showOpponentDamage,
      uiRound: newUiRound,
      uiRoundStartedAt: newUiRoundStartedAt,
      currentQuestionIndex: newQuestionIndex,
      answerLocked: newAnswerLocked,
    );

    _checkOpponentStaleness(match);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(DuelSyncConfig.heartbeatInterval, (_) {
      _sendHeartbeat();
    });
    _sendHeartbeat();
  }

  void _sendHeartbeat() {
    final matchId = state.matchId;
    final myId = state.myId;
    if (matchId == null || myId == null) return;
    if (state.phase != DuelPhase.battling && state.phase != DuelPhase.matchFound) return;
    ref.read(duelServiceProvider).heartbeat(matchId, myId);
  }

  void _checkOpponentStaleness(DuelMatch match) {
    final myId = state.myId;
    if (myId == null || state.phase != DuelPhase.battling) return;
    if (DuelService.isOpponentStale(match, myId, DateTime.now())) {
      final loser = match.opponentIdOf(myId);
      if (loser != null) {
        ref.read(duelServiceProvider).forfeitMatch(match.id, loser);
      }
    }
  }

  void _startTimer([int? initialSeconds]) {
    _roundTimer?.cancel();
    if (initialSeconds != null) {
      state = state.copyWith(secondsLeft: initialSeconds);
    }
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsLeft > 1) {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      } else {
        timer.cancel();
        submitAnswer(-1, isTimeout: true);
      }
    });
  }

  void resyncRoundClock() {
    final roundStart = state.uiRoundStartedAt;
    if (roundStart == null || state.phase != DuelPhase.battling) return;
    final seconds = DuelService.secondsLeftForRound(
      DateTime.now(),
      roundStart,
      state.uiRound,
    );
    state = state.copyWith(secondsLeft: seconds);
    if (seconds <= 0) {
      submitAnswer(-1, isTimeout: true);
    } else {
      _startTimer(seconds);
    }
    _sendHeartbeat();
  }

  Future<void> submitAnswer(int selectedIndex, {bool isTimeout = false}) async {
    if (state.answerLocked || state.phase != DuelPhase.battling) return;
    if (state.battleQuestions.isEmpty) return;

    state = state.copyWith(answerLocked: true);
    _roundTimer?.cancel();

    final duelService = ref.read(duelServiceProvider);
    final q = state.battleQuestions[state.currentQuestionIndex];
    final isCorrect = selectedIndex == q.correctIndex;

    if (isCorrect) {
      state = state.copyWith(showOpponentDamageEffect: true);
    } else {
      state = state.copyWith(showPlayerDamageEffect: true);
    }

    final matchId = state.matchId;
    final myId = state.myId;
    final opponentId = state.opponentId;

    if (matchId != null && myId != null && opponentId != null) {
      try {
        if (isCorrect) {
          await duelService.applyDamage(matchId, opponentId, DuelMatch.damagePerHit);
        } else {
          await duelService.applyDamage(matchId, myId, DuelMatch.damagePerHit);
        }
      } catch (e) {
        debugPrint('Damage submit failed in provider: $e');
      }

      try {
        final authoritative = await duelService.advanceRound(matchId, state.currentQuestionIndex);
        state = state.copyWith(
          uiRound: authoritative.round,
          uiRoundStartedAt: authoritative.roundStartedAt,
        );
      } catch (e) {
        debugPrint('Round advance failed in provider: $e');
      }
    }

    await Future.delayed(const Duration(seconds: 1));

    final outOfHp = state.playerHp <= 0 || state.opponentHp <= 0;
    final lastQuestion = state.currentQuestionIndex >= state.battleQuestions.length - 1;

    if (outOfHp || lastQuestion) {
      if (state.opponentHp <= 0 || (state.playerHp > state.opponentHp && lastQuestion)) {
        _finishLocally(won: true);
      } else {
        _finishLocally(won: false);
      }
      return;
    }

    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
      answerLocked: false,
    );
    _startTimer(DuelSyncConfig.secondsPerRound);
  }

  void _finishLocally({
    required bool won,
    bool opponentGone = false,
    bool cancelled = false,
  }) {
    if (state.phase == DuelPhase.results) return;

    _roundTimer?.cancel();
    _heartbeatTimer?.cancel();

    state = state.copyWith(
      phase: DuelPhase.results,
      isPlayerWinning: won,
    );

    _awardVictoryRewards(won);
    _recordResultsAndHistory(won);

    final matchId = state.matchId;
    if (matchId != null && !opponentGone && !cancelled) {
      Future.delayed(const Duration(seconds: 10), () {
        ref.read(duelServiceProvider).deleteMatch(matchId);
      });
    }
  }

  void _awardVictoryRewards(bool won) {
    if (state.rewardsAwarded) return;
    state = state.copyWith(rewardsAwarded: true);
    if (!won) return;

    ref.read(studentProvider.notifier).addXp(150);
    ref.read(studentProvider.notifier).addMistCrystals(25);
    ref.read(questActionProvider.notifier).updateProgress(QuestType.duel, 1);
  }

  void _recordResultsAndHistory(bool won) {
    if (state.resultsRecorded) return;
    state = state.copyWith(resultsRecorded: true);

    final myId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid;
    final match = state.match;

    if (myId != null && match != null) {
      ref.read(duelServiceProvider).recordDuelResultAndHistory(
            userId: myId,
            isWinner: won,
            match: match,
            xpEarned: won ? 150 : 0,
            mistCrystalsEarned: won ? 25 : 0,
          );
    }
  }

  Future<void> forfeit() async {
    final matchId = state.matchId;
    final userId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid;
    if (matchId != null && userId != null) {
      await ref.read(duelServiceProvider).forfeitMatch(matchId, userId);
    }
  }

  void clearDamageEffects() {
    state = state.copyWith(
      showPlayerDamageEffect: false,
      showOpponentDamageEffect: false,
    );
  }

  void startRematch({required Map<String, dynamic> userProfile}) {
    _cancelTimersAndSubscriptions();
    state = DuelSessionState();
    startMatchmaking(userProfile: userProfile);
  }

  void reset() {
    _cancelTimersAndSubscriptions();
    state = DuelSessionState();
  }
}

final duelSessionProvider = NotifierProvider<DuelSessionNotifier, DuelSessionState>(() {
  return DuelSessionNotifier();
});
