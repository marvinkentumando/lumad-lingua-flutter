import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_button.dart';
import 'package:lumad_lingua/widgets/brand_background.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';
import 'package:lumad_lingua/widgets/crystal_burst_animation.dart';
import 'package:lumad_lingua/services/haptic_service.dart';
import 'package:lumad_lingua/services/duel_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/models/duel_models.dart';
import 'package:lumad_lingua/models/quest.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/providers/quest_provider.dart';
import 'package:lumad_lingua/providers/student_provider.dart';
import 'package:lumad_lingua/models/dictionary_entry.dart';
import 'package:lumad_lingua/utils/app_localization.dart';

enum DuelPhase { idle, searching, matchFound, battling, results }

class LinguaDuelScreen extends ConsumerStatefulWidget {
  const LinguaDuelScreen({super.key});

  @override
  ConsumerState<LinguaDuelScreen> createState() => _LinguaDuelScreenState();
}

class _LinguaDuelScreenState extends ConsumerState<LinguaDuelScreen>
    with WidgetsBindingObserver {
  DuelPhase _phase = DuelPhase.idle;
  double _playerHp = 1.0;
  double _opponentHp = 1.0;
  int _currentQuestionIndex = 0;
  bool _isPlayerWinning = true;
  String _opponentName = 'Ancestral Guardian';

  String? _matchId;
  bool _isHost = false;
  String? _myId;
  String? _opponentId;
  StreamSubscription<DuelMatch?>? _matchSubscription;
  Timer? _roundTimer;
  int _secondsLeft = DuelSyncConfig.secondsPerRound;
  bool _showPlayerDamageEffect = false;
  bool _showOpponentDamageEffect = false;
  List<DuelQuestion> _battleQuestions = [];

  Timer? _heartbeatTimer;
  bool _rewardsAwarded = false;
  bool _answerLocked = false;
  int _uiRound = 0;
  DateTime? _uiRoundStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the background: re-sync the countdown from the
    // document-anchored deadline instead of trusting the drifted local timer.
    if (state == AppLifecycleState.resumed) {
      _resyncRoundClock();
      _sendHeartbeat();
    }
  }

  void _resyncRoundClock() {
    final roundStart = _uiRoundStartedAt;
    if (roundStart == null || _phase != DuelPhase.battling) return;
    final seconds = DuelService.secondsLeftForRound(
      DateTime.now(),
      roundStart,
      _uiRound,
    );
    if (!mounted) return;
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) {
      _handleAnswer(-1, isTimeout: true);
    } else {
      _startTimer(seconds);
    }
  }

  // ── Matchmaking ───────────────────────────────────────────────────────────

  Future<void> _startMatchmaking() async {
    if (_phase != DuelPhase.idle) return;
    setState(() => _phase = DuelPhase.searching);
    HapticService.light();

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      setState(() => _phase = DuelPhase.idle);
      return;
    }
    _myId = user.uid;

    try {
      final duelService = ref.read(duelServiceProvider);
      final matchId = await duelService.findOrCreateMatch(
        userProfile: {
          'username': user.displayName,
          'avatar': '👤',
        },
        questions: _isHost ? _createBattleQuestions() : null,
      );

      if (!mounted) {
        await duelService.cancelMatch(matchId);
        return;
      }

      _matchId = matchId;
      _listenToMatch();
    } catch (e) {
      debugPrint("Matchmaking error: $e");
      if (mounted) setState(() => _phase = DuelPhase.idle);
    }
  }

  List<DuelQuestion> _createBattleQuestions() {
    final dictionary = ref.read(allWordsProvider).value ?? [];
    final l10n = ref.read(localizationProvider);

    List<DuelQuestion> questions = [];

    if (dictionary.length >= 4) {
      final sample = List<DictionaryEntry>.from(dictionary)..shuffle();
      for (int i = 0; i < 5 && i < sample.length; i++) {
        final entry = sample[i];

        final options = <String>[entry.translation];
        final distractors = dictionary.where((w) => w.id != entry.id).toList()
          ..shuffle();
        options.addAll(distractors.take(3).map((w) => w.translation));
        options.shuffle();

        questions.add(DuelQuestion(
          question: l10n.translate('duel_question_prefix',
              params: {'word': entry.indigenousWord}),
          options: options,
          correctIndex: options.indexOf(entry.translation),
        ));
      }
    }

    if (questions.isEmpty) {
      questions = [
        DuelQuestion(
          question: l10n.translate('duel_question_gm'),
          options: ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
          correctIndex: 2,
        ),
        DuelQuestion(
          question: l10n.translate('duel_question_land'),
          options: ['Duta', 'Danaw', 'Allaw', 'Gabi'],
          correctIndex: 0,
        ),
      ];
    }

    return questions;
  }

  // ── Real-time match sync ──────────────────────────────────────────────────

  void _listenToMatch() {
    if (_matchId == null || _myId == null) return;

    _matchSubscription?.cancel();
    _matchSubscription = ref
        .read(duelServiceProvider)
        .streamMatch(_matchId!)
        .listen(_onMatchUpdate, onError: (e) {
      debugPrint("Match stream error: $e");
    });
  }

  void _onMatchUpdate(DuelMatch? match) {
    if (!mounted) return;
    if (match == null) {
      // Document vanished (cleanup). End locally instead of hanging.
      if (_phase == DuelPhase.battling || _phase == DuelPhase.searching) {
        _finishLocally(won: _playerHp >= _opponentHp, opponentGone: true);
      }
      return;
    }

    switch (match.status) {
      case DuelStatus.waiting:
        // Still waiting for an opponent.
        break;

      case DuelStatus.active:
        if (_phase == DuelPhase.searching) _onBattleStart(match);
        if (_phase == DuelPhase.battling) _onBattleUpdate(match);

      case DuelStatus.finished:
      case DuelStatus.cancelled:
        if (_phase == DuelPhase.battling || _phase == DuelPhase.searching) {
          final won = match.winnerId != null
              ? match.winnerId == _myId
              : _playerHp >= _opponentHp;
          _finishLocally(won: won, cancelled: match.status == DuelStatus.cancelled);
        }
    }
  }

  void _onBattleStart(DuelMatch match) {
    final myId = _myId!;
    final isPlayer1 = match.player1Id == myId;
    _isHost = isPlayer1;
    _opponentId = isPlayer1 ? match.player2Id : match.player1Id;
    _opponentName = (isPlayer1 ? match.player2Name : match.player1Name) ?? 'Warrior';
    _battleQuestions = match.questions;
    _playerHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    _opponentHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    _roundTimer?.cancel();
    setState(() {
      _phase = DuelPhase.matchFound;
      _currentQuestionIndex = 0;
      _uiRound = 0;
      _uiRoundStartedAt = match.battleStartedAt;
      _secondsLeft = DuelSyncConfig.secondsPerRound;
    });
    HapticService.celebration();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _phase = DuelPhase.battling);
      _startHeartbeat();
      _startTimer(DuelSyncConfig.secondsPerRound);
    });
  }

  void _onBattleUpdate(DuelMatch match) {
    final myId = _myId!;
    final isPlayer1 = match.player1Id == myId;

    final newPlayerHp = isPlayer1 ? match.player1Hp : match.player2Hp;
    final newOpponentHp = isPlayer1 ? match.player2Hp : match.player1Hp;

    // Only remote writes (opponent's damage on me) get the hit flash; our own
    // echoed writes must not.
    final remote = !match.hasPendingWrites;

    final showPlayerDamage =
        remote && newPlayerHp < _playerHp && !_showPlayerDamageEffect;
    final showOpponentDamage =
        remote && newOpponentHp < _opponentHp && !_showOpponentDamageEffect;

    _playerHp = newPlayerHp;
    _opponentHp = newOpponentHp;

    // Round-clock reconciliation: adopt the document's authoritative round
    // clock whenever it moved (either client may open the next round first).
    if (_uiRound != match.currentRound && match.roundStartedAt != null) {
      _uiRound = match.currentRound;
      _uiRoundStartedAt = match.roundStartedAt;
      if (match.currentRound < _battleQuestions.length && _answerLocked) {
        _answerLocked = false;
        _currentQuestionIndex = match.currentRound;
        _roundTimer?.cancel();
        _startTimer(DuelSyncConfig.secondsPerRound);
      }
    }

    setState(() {
      _showPlayerDamageEffect = showPlayerDamage;
      _showOpponentDamageEffect = showOpponentDamage;
    });

    // A silent opponent (no heartbeat for a while) forfeits the duel so we
    // never wait on a ghost.
    _checkOpponentStaleness(match);
  }

  // ── Heartbeat / abandonment ───────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(DuelSyncConfig.heartbeatInterval, (_) {
      _sendHeartbeat();
    });
    _sendHeartbeat();
  }

  void _sendHeartbeat() {
    final matchId = _matchId;
    final myId = _myId;
    if (matchId == null || myId == null) return;
    if (_phase != DuelPhase.battling && _phase != DuelPhase.matchFound) return;
    ref.read(duelServiceProvider).heartbeat(matchId, myId);
  }

  void _checkOpponentStaleness(DuelMatch match) {
    final myId = _myId;
    if (myId == null || _phase != DuelPhase.battling) return;
    if (DuelService.isOpponentStale(match, myId, DateTime.now())) {
      final loser = match.opponentIdOf(myId);
      if (loser != null) {
        ref.read(duelServiceProvider).forfeitMatch(match.id, loser);
      }
    }
  }

  // ── Turn timer ────────────────────────────────────────────────────────────

  void _startTimer([int? initialSeconds]) {
    _roundTimer?.cancel();
    if (initialSeconds != null && mounted) {
      setState(() => _secondsLeft = initialSeconds);
    }
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _handleAnswer(-1, isTimeout: true);
      }
    });
  }

  // ── Answering ─────────────────────────────────────────────────────────────

  Future<void> _handleAnswer(int selectedIndex, {bool isTimeout = false}) async {
    if (_answerLocked || _phase != DuelPhase.battling) return;
    if (_battleQuestions.isEmpty) return;
    _answerLocked = true;
    _roundTimer?.cancel();

    final duelService = ref.read(duelServiceProvider);
    final q = _battleQuestions[_currentQuestionIndex];
    final isCorrect = selectedIndex == q.correctIndex;

    if (isCorrect) {
      HapticService.light();
      setState(() => _showOpponentDamageEffect = true);
    } else {
      HapticService.error();
      setState(() => _showPlayerDamageEffect = true);
    }

    // One atomic, target-scoped delta per round outcome. Both HP fields are
    // server-owned; clients never write absolute HP.
    final matchId = _matchId;
    final myId = _myId;
    if (matchId != null && myId != null && _opponentId != null) {
      try {
        if (isCorrect) {
          await duelService.applyDamage(
            matchId,
            _opponentId!,
            DuelMatch.damagePerHit,
          );
        } else {
          await duelService.applyDamage(
            matchId,
            myId,
            DuelMatch.damagePerHit,
          );
        }
      } catch (e) {
        debugPrint("Damage submit failed: $e");
      }

      // Advance the shared round clock. If the opponent advanced first we
      // adopt their (round, startedAt) instead of writing ours.
      try {
        final authoritative =
            await duelService.advanceRound(matchId, _currentQuestionIndex);
        _uiRound = authoritative.round;
        _uiRoundStartedAt = authoritative.roundStartedAt;
      } catch (e) {
        debugPrint("Round advance failed: $e");
      }
    }

    if (!mounted) return;
    setState(() {});

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final outOfHp = _playerHp <= 0 || _opponentHp <= 0;
    final lastQuestion = _currentQuestionIndex >= _battleQuestions.length - 1;

    if (outOfHp || lastQuestion) {
      // Final result comes from the document (status/winnerId) — both clients
      // converge on the same verdict, and rewards are granted exactly once.
      if (_opponentHp <= 0 || (_playerHp > _opponentHp && lastQuestion)) {
        _finishLocally(won: true);
      } else {
        _finishLocally(won: false);
      }
      return;
    }

    _currentQuestionIndex++;
    // We advanced the shared clock ourselves; unlock now. The document echo
    // unlocks too when the opponent won the race instead — both paths are
    // idempotent, so the lock can never stick.
    _answerLocked = false;
    _startTimer(DuelSyncConfig.secondsPerRound);
  }

  // ── Finishing ─────────────────────────────────────────────────────────────

  void _finishLocally({
    required bool won,
    bool opponentGone = false,
    bool cancelled = false,
  }) {
    if (_phase == DuelPhase.results) return;
    _roundTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isPlayerWinning = won;
    if (won) {
      HapticService.celebration();
    } else {
      HapticService.error();
    }
    _awardVictoryRewards(won);
    setState(() => _phase = DuelPhase.results);

    // Do NOT delete the match document here: the opponent's listener still
    // needs the final state. Cleanup is a delayed delete on both clients
    // (harmless if one side already did it) — but only for duels that ended
    // server-side, never for a vanished/cancelled doc.
    final matchId = _matchId;
    if (matchId != null && !opponentGone && !cancelled) {
      Future.delayed(const Duration(seconds: 10), () {
        ref.read(duelServiceProvider).deleteMatch(matchId);
      });
    }
  }

  void _awardVictoryRewards(bool won) {
    if (_rewardsAwarded) return;
    _rewardsAwarded = true;
    if (!won) return;
    ref.read(studentProvider.notifier).addXp(150);
    ref.read(studentProvider.notifier).addMistCrystals(25);
    ref.read(questActionProvider.notifier).updateProgress(QuestType.duel, 1);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roundTimer?.cancel();
    _heartbeatTimer?.cancel();
    _matchSubscription?.cancel();

    // Leaving while waiting: release the lobby so nobody joins a ghost.
    final matchId = _matchId;
    final phase = _phase;
    if (matchId != null && (phase == DuelPhase.searching || phase == DuelPhase.matchFound)) {
      ref.read(duelServiceProvider).cancelMatch(matchId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildCurrentPhase(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(AppLocalization l10n) {
    switch (_phase) {
      case DuelPhase.idle:
        return _buildIdle(l10n);
      case DuelPhase.searching:
        return _buildSearching(l10n);
      case DuelPhase.matchFound:
        return _buildMatchFound(l10n);
      case DuelPhase.battling:
        return _buildBattling(l10n);
      case DuelPhase.results:
        return _buildResults(l10n);
    }
  }

  Widget _buildIdle(AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrandCard(
          theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
          padding: const EdgeInsets.all(32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fort_rounded, size: 80, color: AppColors.gold500),
              const SizedBox(height: 24),
              Text(
                l10n.translate('lingua_duel'),
                style: AppTypography.displayBold.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 28,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('duel_desc'),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest700,
                ),
              ),
              const SizedBox(height: 32),
              BrandButton(
                text: l10n.translate('enter_arena'),
                onTap: _startMatchmaking,
                type: BrandButtonType.primary,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.translate('retreat'), style: TextStyle(color: isDark ? Colors.white60 : AppColors.forest600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearching(AppLocalization l10n) {
    return Center(
      key: const ValueKey('searching'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold500)
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds, curve: Curves.easeInOut),
          const SizedBox(height: 32),
          Text(
            l10n.translate('seeking_opponent'),
            style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('stirring_spirits'),
            style: AppTypography.body.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchFound(AppLocalization l10n) {
    return Center(
      key: const ValueKey('matchFound'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_rounded, size: 80, color: AppColors.gold500)
              .animate()
              .shake(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            l10n.translate('match_found'),
            style: AppTypography.displayBold.copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('prepare_combat'),
            style: AppTypography.body.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildBattling(AppLocalization l10n) {
    if (_battleQuestions.isEmpty) return const SizedBox.shrink();
    final q = _battleQuestions[_currentQuestionIndex];

    return Stack(
      key: const ValueKey('battling'),
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('you_label'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _playerHp.clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticGreen, borderRadius: BorderRadius.circular(6))),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.gold500, shape: BoxShape.circle),
                    child: Text(
                      '$_secondsLeft',
                      style: AppTypography.mono.copyWith(color: AppColors.forest900, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_opponentName.toUpperCase(), style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: _opponentHp.clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticRed, borderRadius: BorderRadius.circular(6))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BrandCard(
                theme: BrandCardTheme.gold,
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                child: Text(
                  q.question,
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ...List.generate(q.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BrandButton(
                        text: q.options[index],
                        onTap: _answerLocked ? null : () => _handleAnswer(index),
                        type: BrandButtonType.secondary,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
        if (_showPlayerDamageEffect)
          Positioned(
            left: 50,
            top: 100,
            child: CrystalBurstAnimation(onComplete: () {
              if (mounted) setState(() => _showPlayerDamageEffect = false);
            }),
          ),
        if (_showOpponentDamageEffect)
          Positioned(
            right: 50,
            top: 100,
            child: CrystalBurstAnimation(onComplete: () {
              if (mounted) setState(() => _showOpponentDamageEffect = false);
            }),
          ),
      ],
    );
  }

  Widget _buildResults(AppLocalization l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isPlayerWinning ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
          size: 100,
          color: AppColors.gold500,
        ).animate().scale(duration: 1.seconds, curve: Curves.bounceOut),
        const SizedBox(height: 24),
        Text(
          _isPlayerWinning ? l10n.translate('victory') : l10n.translate('defeat'),
          style: AppTypography.displayBold.copyWith(
            color: _isPlayerWinning ? AppColors.gold500 : AppColors.semanticRed,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPlayerWinning ? l10n.translate('victory_reward') : l10n.translate('defeat_desc'),
          style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: BrandButton(
            text: l10n.translate('leave_arena'),
            onTap: () => context.pop(),
            type: BrandButtonType.primary,
          ),
        ),
      ],
    );
  }
}
