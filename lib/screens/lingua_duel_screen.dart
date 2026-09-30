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
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/models/duel_models.dart';
import 'package:lumad_lingua/services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(duelSessionProvider.notifier).checkAndRestoreActiveSession();
    });
  }

  @override
  void dispose() {
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

  void _startMatchmaking() {
    HapticService.light();
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final userProfile = {
      'username': user.displayName ?? 'Warrior',
      'avatar': '👤',
    };

    final questions = _createBattleQuestions();

    ref.read(duelSessionProvider.notifier).startMatchmaking(
          userProfile: userProfile,
          questions: questions,
        );
  }

  Future<bool> _handlePop(BuildContext context, DuelSessionState sessionState) async {
    if (sessionState.phase == DuelPhase.battling) {
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
      canPop: sessionState.phase != DuelPhase.battling && sessionState.phase != DuelPhase.searching,
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

  Widget _buildCurrentPhase(DuelSessionState sessionState, AppLocalization l10n) {
    switch (sessionState.phase) {
      case DuelPhase.idle:
        return _buildIdle(l10n);
      case DuelPhase.searching:
        return _buildSearching(l10n);
      case DuelPhase.matchFound:
        return _buildMatchFound(l10n);
      case DuelPhase.battling:
        return _buildBattling(sessionState, l10n);
      case DuelPhase.results:
        return _buildResults(sessionState, l10n);
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
    return Stack(
      key: const ValueKey('searching'),
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
            onPressed: () {
              HapticService.light();
              ref.read(duelSessionProvider.notifier).reset();
            },
            tooltip: l10n.translate('retreat'),
          ),
        ),
        Center(
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
                    'CANCEL MATCHMAKING',
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
        ),
      ],
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
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: sessionState.playerHp.clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticGreen, borderRadius: BorderRadius.circular(6))),
                        ),
                      ),
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
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: sessionState.opponentHp.clamp(0.0, 1.0),
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
          won ? l10n.translate('victory_reward') : l10n.translate('defeat_desc'),
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
                  final user = ref.read(authStateProvider).value;
                  if (user == null) return;
                  final userProfile = {
                    'username': user.displayName ?? 'Warrior',
                    'avatar': '👤',
                  };
                  ref.read(duelSessionProvider.notifier).startRematch(userProfile: userProfile);
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
}
