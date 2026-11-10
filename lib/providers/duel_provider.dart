import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_models.dart';
import '../models/quest.dart';
import '../services/duel_service.dart';
import '../services/auth_service.dart';
import 'quest_provider.dart';
import 'student_provider.dart';

enum DuelPhase { idle, searching, introduction, countdown, battling, results, rematchPending }

class DuelSessionState {
  final DuelPhase phase;
  final String? matchId;
  final DuelMatch? match;
  final bool isLoading;
  final String? error;
  final String? myId;
  final String? opponentId;
  final String opponentName;
  final String opponentAvatar;
  final String myName;
  final String myAvatar;
  final bool isHost;
  final double playerHp;
  final double opponentHp;
  final int currentQuestionIndex;
  final int secondsLeft;
  final int countdownSecondsLeft;
  final int matchmakingSecondsLeft;
  final bool matchmakingTimedOut;
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
    this.opponentAvatar = '👤',
    this.myName = 'Warrior',
    this.myAvatar = '👤',
    this.isHost = false,
    this.playerHp = 100.0,
    this.opponentHp = 100.0,
    this.currentQuestionIndex = 0,
    this.secondsLeft = DuelSyncConfig.secondsPerRound,
    this.countdownSecondsLeft = 10,
    this.matchmakingSecondsLeft = DuelSyncConfig.matchmakingTimeoutSeconds,
    this.matchmakingTimedOut = false,
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
    String? opponentAvatar,
    String? myName,
    String? myAvatar,
    bool? isHost,
    double? playerHp,
    double? opponentHp,
    int? currentQuestionIndex,
    int? secondsLeft,
    int? countdownSecondsLeft,
    int? matchmakingSecondsLeft,
    bool? matchmakingTimedOut,
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
      opponentAvatar: opponentAvatar ?? this.opponentAvatar,
      myName: myName ?? this.myName,
      myAvatar: myAvatar ?? this.myAvatar,
      isHost: isHost ?? this.isHost,
      playerHp: playerHp ?? this.playerHp,
      opponentHp: opponentHp ?? this.opponentHp,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      countdownSecondsLeft: countdownSecondsLeft ?? this.countdownSecondsLeft,
      matchmakingSecondsLeft:
          matchmakingSecondsLeft ?? this.matchmakingSecondsLeft,
      matchmakingTimedOut: matchmakingTimedOut ?? this.matchmakingTimedOut,
      isPlayerWinning: isPlayerWinning ?? this.isPlayerWinning,
      showPlayerDamageEffect:
          showPlayerDamageEffect ?? this.showPlayerDamageEffect,
      showOpponentDamageEffect:
          showOpponentDamageEffect ?? this.showOpponentDamageEffect,
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
  Timer? _matchmakingTimer;
  Timer? _countdownTimer;
  String? _matchmakingMatchId;
  int _matchmakingAttempt = 0;

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
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> checkAndRestoreActiveSession() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    if (state.phase == DuelPhase.battling || state.phase == DuelPhase.introduction || state.phase == DuelPhase.countdown) {
      return;
    }
    if (state.phase == DuelPhase.searching) {
      final oldMatchId = state.matchId;
      ++_matchmakingAttempt;
      _cancelTimersAndSubscriptions();
      _matchmakingMatchId = null;
      state = DuelSessionState();
      if (oldMatchId != null) {
        ref.read(duelServiceProvider).cancelMatch(oldMatchId).catchError((e) {
          debugPrint('Could not clean up previous waiting match: $e');
        });
      }
    }

    try {
      final duelService = ref.read(duelServiceProvider);
      final activeMatch = await duelService.findActiveMatchForUser(user.uid);
      if (activeMatch != null && activeMatch.status != DuelStatus.finished && activeMatch.status != DuelStatus.cancelled) {
        state = state.copyWith(
          myId: user.uid,
          matchId: activeMatch.id,
          match: activeMatch,
          isLoading: false,
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
    final attempt = ++_matchmakingAttempt;
    _matchmakingMatchId = null;

    state = DuelSessionState(
      phase: DuelPhase.searching,
      isLoading: true,
      myName: userProfile['username'] ?? 'Warrior',
      myAvatar: userProfile['avatar'] ?? '👤',
      matchmakingSecondsLeft: DuelSyncConfig.matchmakingTimeoutSeconds,
      matchmakingTimedOut: false,
    );
    _startMatchmakingTimer(attempt);

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      state = state.copyWith(
        phase: DuelPhase.idle,
        isLoading: false,
        error: 'Sign in before entering the arena.',
      );
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

      if (attempt != _matchmakingAttempt || state.matchmakingTimedOut) {
        await duelService.cancelMatch(matchId);
        return;
      }
      _matchmakingMatchId = matchId;
      state = state.copyWith(matchId: matchId, isLoading: false);
      _listenToMatch(matchId);
    } catch (e) {
      if (attempt != _matchmakingAttempt || state.matchmakingTimedOut) return;
      debugPrint('[DuelMatchmaking] stage=provider_start_failed error=$e');
      _matchmakingTimer?.cancel();
      _matchmakingTimer = null;
      state = state.copyWith(
        phase: DuelPhase.idle,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _startMatchmakingTimer(int attempt) {
    _matchmakingTimer?.cancel();
    _matchmakingTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (attempt != _matchmakingAttempt ||
          state.phase != DuelPhase.searching) {
        timer.cancel();
        return;
      }
      final next = state.matchmakingSecondsLeft - 1;
      if (next > 0) {
        state = state.copyWith(matchmakingSecondsLeft: next);
        return;
      }
      timer.cancel();
      _matchmakingTimer = null;
      await _onMatchmakingTimeout(attempt);
    });
  }

  Future<void> _onMatchmakingTimeout(int attempt) async {
    if (attempt != _matchmakingAttempt || state.phase != DuelPhase.searching) {
      return;
    }
    _subscription?.cancel();
    _subscription = null;
    final matchId = _matchmakingMatchId;
    if (matchId != null) {
      try {
        await ref.read(duelServiceProvider).cancelMatch(matchId);
      } catch (e) {
        debugPrint('Timeout cancelMatch failed: $e');
      }
    }
    if (attempt != _matchmakingAttempt) return;
    state = DuelSessionState(
      phase: DuelPhase.idle,
      matchmakingTimedOut: true,
      error:
          'No opponent found within ${DuelSyncConfig.matchmakingTimeoutSeconds}s. Try again when another learner is online.',
    );
  }

  void _listenToMatch(String matchId) {
    _subscription?.cancel();
    _subscription = ref
        .read(duelServiceProvider)
        .streamMatch(matchId)
        .listen(_onMatchUpdate, onError: (e) {
      debugPrint('Match stream error in provider: $e');
      _matchmakingTimer?.cancel();
      _matchmakingTimer = null;
      state = state.copyWith(
        phase: DuelPhase.idle,
        isLoading: false,
        error: e.toString(),
      );
    });
  }

  void _onMatchUpdate(DuelMatch? match) {
    if (match == null) {
      if (state.phase == DuelPhase.battling ||
          state.phase == DuelPhase.searching ||
          state.phase == DuelPhase.introduction ||
          state.phase == DuelPhase.countdown) {
        _finishLocally(
            won: state.playerHp >= state.opponentHp, opponentGone: true);
      }
      return;
    }

    state = state.copyWith(match: match);

    switch (match.status) {
      case DuelStatus.waiting:
        _matchmakingMatchId = match.id;
        if (state.phase != DuelPhase.searching) {
          state = state.copyWith(phase: DuelPhase.searching);
          final attempt = ++_matchmakingAttempt;
          _startMatchmakingTimer(attempt);
        }
        break;

      case DuelStatus.introduction:
      case DuelStatus.countdown:
      case DuelStatus.active:
        _matchmakingTimer?.cancel();
        _matchmakingTimer = null;
        if (state.phase == DuelPhase.searching ||
            state.phase == DuelPhase.idle) {
          _onIntroductionStart(match);
        } else if (state.phase == DuelPhase.introduction || state.phase == DuelPhase.countdown || state.phase == DuelPhase.battling) {
          _onBattleUpdate(match);
        }
        break;

      case DuelStatus.rematchPending:
        state = state.copyWith(phase: DuelPhase.rematchPending);
        break;

      case DuelStatus.finished:
      case DuelStatus.cancelled:
        if (match.status == DuelStatus.cancelled &&
            state.phase == DuelPhase.searching) {
          _matchmakingTimer?.cancel();
          _matchmakingTimer = null;
          _subscription?.cancel();
          _subscription = null;
          state = DuelSessionState(
            error: 'This waiting lobby closed before an opponent joined.',
          );
          break;
        }
        if (state.phase != DuelPhase.results) {
          final myId = state.myId ??
              ref.read(authServiceProvider).currentUser?.uid ??
              '';
          final won = match.winnerId != null
              ? match.winnerId == myId
              : state.playerHp >= state.opponentHp;
          _finishLocally(
              won: won, cancelled: match.status == DuelStatus.cancelled);
        }
        break;
    }
  }

  void _onIntroductionStart(DuelMatch match) {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    final myId =
        state.myId ?? ref.read(authServiceProvider).currentUser?.uid ?? '';
    final isPlayer1 = match.player1Id == myId;
    final opponentId = isPlayer1 ? match.player2Id : match.player1Id;
    final opponentName =
        (isPlayer1 ? match.player2Name : match.player1Name) ?? 'Warrior';
    final opponentAvatar =
        (isPlayer1 ? match.player2Avatar : match.player1Avatar) ?? '👤';
    final myName = isPlayer1 ? match.player1Name : (match.player2Name ?? 'Warrior');
    final myAvatar = isPlayer1 ? match.player1Avatar : (match.player2Avatar ?? '👤');
    final pHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    final oHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    state = state.copyWith(
      phase: DuelPhase.introduction,
      myId: myId,
      isHost: isPlayer1,
      opponentId: opponentId,
      opponentName: opponentName,
      opponentAvatar: opponentAvatar,
      myName: myName,
      myAvatar: myAvatar,
      battleQuestions: match.questions,
      playerHp: pHp,
      opponentHp: oHp,
      currentQuestionIndex: 0,
      uiRound: 0,
      uiRoundStartedAt: match.battleStartedAt,
      countdownSecondsLeft: 10,
    );

    _startHeartbeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (state.phase == DuelPhase.introduction) {
        state = state.copyWith(phase: DuelPhase.countdown);
        _startCountdownTimer();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    state = state.copyWith(countdownSecondsLeft: 10);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSecondsLeft > 1) {
        state = state.copyWith(countdownSecondsLeft: state.countdownSecondsLeft - 1);
      } else {
        timer.cancel();
        _countdownTimer = null;
        if (state.phase == DuelPhase.countdown) {
          state = state.copyWith(phase: DuelPhase.battling);
          _startTimer(DuelSyncConfig.secondsPerRound);
        }
      }
    });
  }

  void _onBattleUpdate(DuelMatch match) {
    final myId =
        state.myId ?? ref.read(authServiceProvider).currentUser?.uid ?? '';
    final isPlayer1 = match.player1Id == myId;

    final newPlayerHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    final newOpponentHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    final remote = !match.hasPendingWrites;
    final showPlayerDamage =
        remote && newPlayerHp < state.playerHp && !state.showPlayerDamageEffect;
    final showOpponentDamage = remote &&
        newOpponentHp < state.opponentHp &&
        !state.showOpponentDamageEffect;

    int newUiRound = state.uiRound;
    DateTime? newUiRoundStartedAt = state.uiRoundStartedAt;
    int newQuestionIndex = state.currentQuestionIndex;
    bool newAnswerLocked = state.answerLocked;

    if (state.uiRound != match.currentRound && match.roundStartedAt != null) {
      newUiRound = match.currentRound;
      newUiRoundStartedAt = match.roundStartedAt;
      if (match.currentRound < state.battleQuestions.length &&
          state.answerLocked) {
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
    if (state.phase == DuelPhase.results || state.phase == DuelPhase.idle || state.phase == DuelPhase.searching) {
      return;
    }
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
    final isCorrect = !isTimeout && selectedIndex == q.correctIndex;

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
          await duelService.applyDamage(
              matchId, opponentId, DuelMatch.damagePerHit);
        } else {
          await duelService.applyDamage(matchId, myId, DuelMatch.damagePerHit);
        }
      } catch (e) {
        debugPrint('Damage submit failed in provider: $e');
      }

      try {
        final authoritative =
            await duelService.advanceRound(matchId, state.currentQuestionIndex);
        state = state.copyWith(
          uiRound: authoritative.round,
          uiRoundStartedAt: authoritative.roundStartedAt,
        );
      } catch (e) {
        debugPrint('Round advance failed in provider: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    final lastQuestion =
        state.currentQuestionIndex >= state.battleQuestions.length - 1;

    if (lastQuestion || state.playerHp <= 0 || state.opponentHp <= 0) {
      final won = state.playerHp >= state.opponentHp;
      _finishLocally(won: won);
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
    _countdownTimer?.cancel();

    state = state.copyWith(
      phase: DuelPhase.results,
      isPlayerWinning: won,
    );

    _awardVictoryRewards(won);
    _recordResultsAndHistory(won);

    final matchId = state.matchId;
    if (matchId != null && !opponentGone && !cancelled) {
      Future.delayed(const Duration(seconds: 15), () {
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

  Future<void> requestRematch() async {
    final matchId = state.matchId;
    final userId = state.myId ?? ref.read(authServiceProvider).currentUser?.uid;
    if (matchId != null && userId != null) {
      state = state.copyWith(phase: DuelPhase.rematchPending);
      await ref.read(duelServiceProvider).requestRematch(matchId, userId);
    }
  }

  void reset() {
    ++_matchmakingAttempt;
    _matchmakingMatchId = null;
    _cancelTimersAndSubscriptions();
    final timedOut = state.matchmakingTimedOut;
    state = DuelSessionState(matchmakingTimedOut: timedOut);
  }
}

final duelSessionProvider =
    NotifierProvider<DuelSessionNotifier, DuelSessionState>(() {
  return DuelSessionNotifier();
});
