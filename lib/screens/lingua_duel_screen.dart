import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_button.dart';
import 'package:lumad_lingua/widgets/brand_background.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';
import 'package:lumad_lingua/widgets/crystal_burst_animation.dart';
import 'package:lumad_lingua/services/haptic_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/models/duel_models.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/services/duel_service.dart';
import 'package:lumad_lingua/providers/duel_provider.dart';
import 'package:lumad_lingua/models/dictionary_entry.dart';
import 'package:lumad_lingua/utils/app_localization.dart';

class LinguaDuelScreen extends ConsumerStatefulWidget {
  const LinguaDuelScreen({super.key});

  @override
  ConsumerState<LinguaDuelScreen> createState() => _LinguaDuelScreenState();
}

class _LinguaDuelScreenState extends ConsumerState<LinguaDuelScreen>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivity,
      onError: (Object error) => debugPrint('Duel connectivity listener error: $error'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(duelSessionProvider.notifier).checkAndRestoreActiveSession();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      _updateConnectivity(await Connectivity().checkConnectivity());
    } catch (error) {
      debugPrint('Duel connectivity check failed: $error');
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (!mounted || online == _isOnline) return;
    setState(() => _isOnline = online);
    if (!online && ref.read(duelSessionProvider).phase == DuelPhase.searching) {
      ref.read(duelSessionProvider.notifier).reset();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(duelSessionProvider.notifier).resyncRoundClock();
    }
  }

  List<DuelQuestion> _createBattleQuestions() {
    final dictionary = ref.read(allWordsProvider).value ?? [];
    final l10n = ref.read(localizationProvider);

    List<DuelQuestion> questions = [];

    if (dictionary.length >= 4) {
      final sample = List<DictionaryEntry>.from(dictionary)..shuffle();
      for (int i = 0; i < 10 && i < sample.length; i++) {
        final entry = sample[i];
        final typeChoice = i % 3;

        if (typeChoice == 0) {
          final options = <String>[entry.translation];
          final distractors = dictionary.where((w) => w.id != entry.id).toList()..shuffle();
          options.addAll(distractors.take(3).map((w) => w.translation));
          options.shuffle();

          questions.add(DuelQuestion(
            question: l10n.translate('duel_question_prefix', params: {'word': entry.indigenousWord}),
            options: options,
            correctIndex: options.indexOf(entry.translation),
            type: 'multipleChoice',
          ));
        } else if (typeChoice == 1) {
          final options = <String>[entry.indigenousWord];
          final distractors = dictionary.where((w) => w.id != entry.id).toList()..shuffle();
          options.addAll(distractors.take(3).map((w) => w.indigenousWord));
          options.shuffle();

          questions.add(DuelQuestion(
            question: 'How do you say "${entry.translation}" in Mansaka?',
            options: options,
            correctIndex: options.indexOf(entry.indigenousWord),
            type: 'reverseTranslation',
          ));
        } else {
          final options = <String>[entry.translation];
          final distractors = dictionary.where((w) => w.id != entry.id).toList()..shuffle();
          options.addAll(distractors.take(3).map((w) => w.translation));
          options.shuffle();

          questions.add(DuelQuestion(
            question: 'Select the correct translation for: "${entry.translation}"',
            options: options,
            correctIndex: options.indexOf(entry.translation),
            type: 'matchingType',
          ));
        }
      }
    }

    while (questions.length < 10) {
      questions.add(DuelQuestion(
        question: 'How do you say "Good Morning" in Mansaka?',
        options: ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
        correctIndex: 2,
        type: 'multipleChoice',
      ));
      questions.add(DuelQuestion(
        question: 'What is the meaning of "Duta"?',
        options: ['Land / Earth', 'Lake / River', 'Sun / Day', 'Night / Sky'],
        correctIndex: 0,
        type: 'multipleChoice',
      ));
      questions.add(DuelQuestion(
        question: 'How do you say "Water" in Mansaka?',
        options: ['Tubig', 'Duta', 'Langit', 'Bulan'],
        correctIndex: 0,
        type: 'reverseTranslation',
      ));
    }

    if (questions.length > 10) {
      questions = questions.sublist(0, 10);
    }

    return questions;
  }

  void _startMatchmaking() {
    if (!_isOnline) return;
    HapticService.light();
    final user = ref.read(authServiceProvider).currentUser;

    final userProfile = {
      'username': user?.displayName ?? 'Warrior',
      'avatar': '👤',
    };

    final questions = _createBattleQuestions();

    ref.read(duelSessionProvider.notifier).startMatchmaking(
          userProfile: userProfile,
          questions: questions,
        );
  }

  Future<bool> _handlePop(BuildContext context, DuelSessionState sessionState) async {
    if (sessionState.phase == DuelPhase.battling || sessionState.phase == DuelPhase.introduction || sessionState.phase == DuelPhase.countdown) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.forest800,
          title: const Text('Forfeit Battle?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Leaving an active battle will count as a defeat. Are you sure you want to forfeit?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
              child: const Text('FORFEIT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(duelSessionProvider.notifier).forfeit();
        return true;
      }
      return false;
    } else if (sessionState.phase == DuelPhase.searching) {
      ref.read(duelSessionProvider.notifier).reset();
      return true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(duelSessionProvider);
    final l10n = ref.watch(localizationProvider);

    return PopScope(
      canPop: sessionState.phase != DuelPhase.battling && sessionState.phase != DuelPhase.introduction && sessionState.phase != DuelPhase.countdown && sessionState.phase != DuelPhase.searching,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePop(context, sessionState);
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        body: BrandBackground(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildCurrentPhase(sessionState, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showGameHistory(BuildContext context) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    HapticService.light();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.gold500),
            const SizedBox(width: 12),
            Text('Lingua Duel History', style: AppTypography.h3.copyWith(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<DuelHistoryItem>>(
            future: ref.read(duelServiceProvider).fetchUserDuelHistory(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold500));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No past duels recorded yet. Enter the arena and battle other learners!',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: Colors.white70),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.forest700,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isWinner ? AppColors.semanticGreen.withValues(alpha: 0.5) : AppColors.semanticRed.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(item.isWinner ? '🏆' : '💀', style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isWinner ? 'Victory vs ${item.opponentName}' : 'Defeat vs ${item.opponentName}',
                                style: AppTypography.label.copyWith(
                                  color: item.isWinner ? AppColors.semanticGreen : AppColors.semanticRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'HP: ${item.finalPlayerHp.toInt()} vs ${item.finalOpponentHp.toInt()} • XP: +${item.xpEarned} • Crystals: +${item.mistCrystalsEarned}',
                                style: AppTypography.caption.copyWith(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          BrandButton(
            text: 'CLOSE',
            onTap: () => Navigator.pop(ctx),
            type: BrandButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPhase(DuelSessionState sessionState, AppLocalization l10n) {
    switch (sessionState.phase) {
      case DuelPhase.idle:
        return _buildIdle(l10n);
      case DuelPhase.searching:
        return _buildSearching(l10n);
      case DuelPhase.introduction:
      case DuelPhase.countdown:
        return _buildIntroductionAndCountdown(sessionState, l10n);
      case DuelPhase.battling:
        return _buildBattling(sessionState, l10n);
      case DuelPhase.results:
        return _buildResults(sessionState, l10n);
      case DuelPhase.rematchPending:
        return _buildRematchPending(l10n);
    }
  }

  Widget _buildIdle(AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionState = ref.watch(duelSessionProvider);
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
              if (sessionState.matchmakingTimedOut) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.semanticRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom_rounded, color: AppColors.semanticRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No opponent found within ${DuelSyncConfig.matchmakingTimeoutSeconds}s. Try again when another learner is online.',
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white70 : AppColors.forest800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (sessionState.error != null && !sessionState.matchmakingTimedOut) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.semanticRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.semanticRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sessionState.error!,
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white70 : AppColors.forest800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.gold500 : AppColors.forest500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? AppColors.gold500 : AppColors.forest500).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: _isOnline ? AppColors.semanticGreen : AppColors.semanticRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isOnline
                            ? 'Lingua Duel requires an internet connection to find and play against other learners.'
                            : 'You are offline. Connect to the internet to use Lingua Duel.',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white70 : AppColors.forest800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BrandButton(
                text: l10n.translate('enter_arena'),
                onTap: _isOnline ? _startMatchmaking : null,
                type: BrandButtonType.primary,
              ),
              const SizedBox(height: 12),
              BrandButton(
                text: 'BATTLE HISTORY',
                onTap: () => _showGameHistory(context),
                type: BrandButtonType.secondary,
                icon: Icons.history_rounded,
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
    final sessionState = ref.watch(duelSessionProvider);
    return Center(
      key: const ValueKey('searching'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
            const SizedBox(height: 16),
            Text(
              'Searching… ${sessionState.matchmakingSecondsLeft}s remaining',
              style: AppTypography.label.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                HapticService.light();
                ref.read(duelSessionProvider.notifier).reset();
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                'CANCEL (${sessionState.matchmakingSecondsLeft}s)',
                style: AppTypography.label.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionAndCountdown(DuelSessionState sessionState, AppLocalization l10n) {
    final isCountdown = sessionState.phase == DuelPhase.countdown;

    return Center(
      key: const ValueKey('introduction'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚔️ LINGUA DUEL ARENA ⚔️',
              style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 3, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.forest700,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.semanticGreen, width: 3),
                      ),
                      child: Center(child: Text(sessionState.myAvatar, style: const TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sessionState.myName,
                      style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text('100 HP', style: AppTypography.caption.copyWith(color: AppColors.semanticGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'VS',
                    style: TextStyle(color: AppColors.gold500, fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.forest700,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.semanticRed, width: 3),
                      ),
                      child: Center(child: Text(sessionState.opponentAvatar, style: const TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sessionState.opponentName,
                      style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text('100 HP', style: AppTypography.caption.copyWith(color: AppColors.semanticRed, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            if (isCountdown) ...[
              Text(
                'BATTLE COMMENCING IN',
                style: AppTypography.label.copyWith(color: Colors.white60, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold500.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                  ],
                ),
                child: Text(
                  '${sessionState.countdownSecondsLeft}',
                  style: AppTypography.displayBold.copyWith(color: AppColors.forest900, fontSize: 42),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms),
            ] else ...[
              const CircularProgressIndicator(color: AppColors.gold500),
              const SizedBox(height: 16),
              Text(
                'Preparing 10 duel questions…',
                style: AppTypography.body.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattling(DuelSessionState sessionState, AppLocalization l10n) {
    if (sessionState.battleQuestions.isEmpty) return const SizedBox.shrink();
    final q = sessionState.battleQuestions[sessionState.currentQuestionIndex];

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
                        height: 14,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(7)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (sessionState.playerHp / 100.0).clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticGreen, borderRadius: BorderRadius.circular(7))),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${sessionState.playerHp.toInt()} / 100 HP', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.gold500, shape: BoxShape.circle),
                    child: Text(
                      '${sessionState.secondsLeft}',
                      style: AppTypography.mono.copyWith(color: AppColors.forest900, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sessionState.opponentName.toUpperCase(), style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(7)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: (sessionState.opponentHp / 100.0).clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticRed, borderRadius: BorderRadius.circular(7))),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${sessionState.opponentHp.toInt()} / 100 HP', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: LinearProgressIndicator(
                value: (sessionState.currentQuestionIndex + 1) / sessionState.battleQuestions.length,
                backgroundColor: Colors.white24,
                color: AppColors.gold500,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'QUESTION ${sessionState.currentQuestionIndex + 1} OF ${sessionState.battleQuestions.length}',
              style: AppTypography.mono.copyWith(color: AppColors.gold500, fontSize: 13, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ...List.generate(q.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BrandButton(
                        text: q.options[index],
                        onTap: sessionState.answerLocked
                            ? null
                            : () => ref.read(duelSessionProvider.notifier).submitAnswer(index),
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
        if (sessionState.showPlayerDamageEffect)
          Positioned(
            left: 50,
            top: 100,
            child: CrystalBurstAnimation(onComplete: () {
              ref.read(duelSessionProvider.notifier).clearDamageEffects();
            }),
          ),
        if (sessionState.showOpponentDamageEffect)
          Positioned(
            right: 50,
            top: 100,
            child: CrystalBurstAnimation(onComplete: () {
              ref.read(duelSessionProvider.notifier).clearDamageEffects();
            }),
          ),
      ],
    );
  }

  Widget _buildResults(DuelSessionState sessionState, AppLocalization l10n) {
    final won = sessionState.isPlayerWinning;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          won ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
          size: 100,
          color: AppColors.gold500,
        ).animate().scale(duration: 1.seconds, curve: Curves.bounceOut),
        const SizedBox(height: 24),
        Text(
          won ? l10n.translate('victory') : l10n.translate('defeat'),
          style: AppTypography.displayBold.copyWith(
            color: won ? AppColors.gold500 : AppColors.semanticRed,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          won ? 'Final HP: You ${sessionState.playerHp.toInt()} vs ${sessionState.opponentName} ${sessionState.opponentHp.toInt()}\nXP +150 • Crystals +25' : 'Final HP: You ${sessionState.playerHp.toInt()} vs ${sessionState.opponentName} ${sessionState.opponentHp.toInt()}',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              BrandButton(
                text: 'REMATCH ⚔️',
                onTap: () {
                  HapticService.light();
                  ref.read(duelSessionProvider.notifier).requestRematch();
                },
                type: BrandButtonType.primary,
              ),
              const SizedBox(height: 12),
              BrandButton(
                text: l10n.translate('leave_arena'),
                onTap: () {
                  ref.read(duelSessionProvider.notifier).reset();
                  context.pop();
                },
                type: BrandButtonType.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRematchPending(AppLocalization l10n) {
    return Center(
      key: const ValueKey('rematchPending'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold500)
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds),
            const SizedBox(height: 32),
            Text(
              'WAITING FOR REMATCH...',
              style: AppTypography.h2.copyWith(color: AppColors.gold500, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for opponent to accept rematch invitation.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 36),
            BrandButton(
              text: 'CANCEL',
              onTap: () {
                ref.read(duelSessionProvider.notifier).reset();
                context.pop();
              },
              type: BrandButtonType.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
