import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';

import '../models/dictionary_entry.dart';
import '../models/srs_models.dart';
import '../models/app_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../widgets/brand_background.dart';
import '../widgets/branded_empty_state.dart';
import '../utils/app_localization.dart';


class FlashcardsScreen extends ConsumerStatefulWidget {
  final bool isReviewMode;
  const FlashcardsScreen({super.key, this.isReviewMode = false});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen>
    with TickerProviderStateMixin {
  List<DictionaryEntry>? _deck;
  Map<String, SRSProgress> _srsData = {};
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    _flipController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _flipCard();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _next();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previous();
        return true;
      }
    }
    return false;
  }

  void _flipCard() {
    HapticService.light();

    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _next() {
    if (_deck != null) {
      if (_currentIndex < _deck!.length - 1) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
        _flipController.reset();
      }
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
      _flipController.reset();
    }
  }

  Future<void> _updateSRS(bool wasCorrect, AppLocalization l10n) async {
    HapticService.medium();

    final user = ref.read(authStateProvider).value;
    if (user == null || _deck == null) return;

    final entry = _deck![_currentIndex];
    final currentSrs = _srsData[entry.id] ?? SRSProgress(wordId: entry.id, nextReview: DateTime.now());

    int newLevel;
    double newEaseFactor = currentSrs.easeFactor;
    int consecutiveCorrect = currentSrs.consecutiveCorrect;
    int intervalDays;
    DateTime now = DateTime.now();
    DateTime? lastFailure = currentSrs.lastFailure;

    final config = ref.read(appConfigProvider).value ?? AppConfig.fromFirestore({});

    if (wasCorrect) {
      newLevel = min(currentSrs.level + 1, 5);
      consecutiveCorrect++;
      newEaseFactor = min(3.0, newEaseFactor + 0.1);

      if (consecutiveCorrect == 1) {
        intervalDays = 1;
      } else if (consecutiveCorrect == 2) {
        intervalDays = 4;
      } else {
        final lastReview = currentSrs.lastReview ?? now.subtract(const Duration(days: 1));
        final prevInterval = currentSrs.nextReview.difference(lastReview).inDays;
        final overdueDays = max(0, now.difference(currentSrs.nextReview).inDays);
        intervalDays = ((prevInterval + (overdueDays / 2)) * newEaseFactor).round();
      }
      ref.read(firebaseServiceProvider).addXp(user.uid, config.cardReviewXp); 
    } else {
      newLevel = 0; 
      consecutiveCorrect = 0;
      newEaseFactor = max(1.3, newEaseFactor - 0.2);
      intervalDays = 1;
      lastFailure = now;
    }

    intervalDays = min(365, max(1, intervalDays));
    final nextReview = now.add(Duration(days: intervalDays));

    final updatedSrs = currentSrs.copyWith(
      level: newLevel,
      nextReview: nextReview,
      lastReview: now,
      lastFailure: lastFailure,
      timesReviewed: currentSrs.timesReviewed + 1,
      consecutiveCorrect: consecutiveCorrect,
      easeFactor: newEaseFactor,
    );

    await ref.read(firebaseServiceProvider).updateSRSProgress(user.uid, updatedSrs);

    if (!mounted) return;
    _next();

    if (wasCorrect) {
      final config = ref.read(appConfigProvider).value ?? AppConfig.fromFirestore({});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('${l10n.translate('mastery_level_up')} +${config.cardReviewXp} XP', style: AppTypography.label.copyWith(color: Colors.white)),
            ],
          ),
          backgroundColor: AppColors.semanticGreen,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final dictionaryAsync = ref.watch(dictionaryStreamProvider);
    final bookmarksAsync = user != null ? ref.watch(userBookmarksStreamProvider(user.uid)) : const AsyncValue.data(<String>[]);
    final srsAsync = user != null ? ref.watch(srsProgressStreamProvider(user.uid)) : const AsyncValue.data(<SRSProgress>[]);
    final l10n = ref.watch(localizationProvider);

    return dictionaryAsync.when(
      loading: () => const Scaffold(backgroundColor: Colors.transparent, body: BrandBackground(child: Center(child: CircularProgressIndicator(color: AppColors.gold500)))),
      error: (_, __) => _buildEmptyState(),
      data: (dictionary) => bookmarksAsync.when(
        loading: () => const Scaffold(backgroundColor: Colors.transparent, body: BrandBackground(child: Center(child: CircularProgressIndicator(color: AppColors.gold500)))),
        error: (_, __) => _buildEmptyState(),
        data: (bookmarks) => srsAsync.when(
          loading: () => const Scaffold(backgroundColor: Colors.transparent, body: BrandBackground(child: Center(child: CircularProgressIndicator(color: AppColors.gold500)))),
          error: (_, __) => _buildEmptyState(),
          data: (srsList) {
            _srsData = {for (var s in srsList) s.wordId: s};
            if (_deck == null) {
              List<DictionaryEntry> deckEntries = [];
              if (widget.isReviewMode) {
                final now = DateTime.now();
                deckEntries = dictionary.where((entry) {
                  final srs = _srsData[entry.id];
                  return srs != null && srs.nextReview.isBefore(now);
                }).toList();
              } else {
                deckEntries = dictionary.where((entry) => bookmarks.contains(entry.id)).toList();
              }

              if (deckEntries.isEmpty) return _buildEmptyState();

              final now = DateTime.now();
              deckEntries.sort((a, b) {
                final srsA = _srsData[a.id];
                final srsB = _srsData[b.id];
                double scoreA = srsA != null ? max(0, now.difference(srsA.nextReview).inMinutes).toDouble() + (srsA.lastFailure != null ? max(0, 4320 - now.difference(srsA.lastFailure!).inMinutes) * 1.5 : 0) : 999999;
                double scoreB = srsB != null ? max(0, now.difference(srsB.nextReview).inMinutes).toDouble() + (srsB.lastFailure != null ? max(0, 4320 - now.difference(srsB.lastFailure!).inMinutes) * 1.5 : 0) : 999999;
                return scoreB.compareTo(scoreA);
              });

              final initialDeck = deckEntries.take(15).toList();
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _deck = initialDeck); });
              return const Scaffold(backgroundColor: Colors.transparent, body: BrandBackground(child: Center(child: CircularProgressIndicator(color: AppColors.gold500))));
            }

            if (_deck!.isEmpty) return _buildEmptyState();
            final entry = _deck![_currentIndex];
            final progress = (_currentIndex + 1) / _deck!.length;
            final isLast = _currentIndex == _deck!.length - 1;
            final currentSrs = _srsData[entry.id];

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(l10n.translate('daily_review'), style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 2)),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '${_currentIndex + 1} / ${_deck!.length}',
                        style: AppTypography.mono.copyWith(
                          color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: BrandBackground(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), valueColor: const AlwaysStoppedAnimation(AppColors.gold500))),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mastery: ${currentSrs?.mastery.name ?? "New"}', style: AppTypography.mono.copyWith(color: _getMasteryColor(currentSrs?.mastery, isDark), fontSize: 11)),
                          Text('${(progress * 100).toInt()}% done', style: AppTypography.mono.copyWith(color: isDark ? AppColors.gold500 : AppColors.gold700, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: GestureDetector(
                          onTap: _flipCard,
                          child: AnimatedBuilder(
                            animation: _flipAnimation,
                            builder: (context, child) {
                              final angle = _flipAnimation.value * pi;
                              final isShowingFront = angle < pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                                child: isShowingFront ? _buildFront(entry, isDark) : Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: _buildBack(entry, l10n)),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isFlipped ? '' : 'Tap card to reveal answer',
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _navControl(icon: Icons.chevron_left_rounded, label: 'PREV', onTap: _currentIndex > 0 ? _previous : null, isDark: isDark),
                          const SizedBox(width: 12),
                          if (_isFlipped) ...[
                            Expanded(child: BrandButton(text: 'Hard', type: BrandButtonType.secondary, onTap: () => _updateSRS(false, l10n))),
                            const SizedBox(width: 12),
                            Expanded(child: BrandButton(text: isLast ? 'Finish ✓' : 'Easy ✓', type: BrandButtonType.primary, onTap: isLast ? () => _showCompletionModal(l10n) : () => _updateSRS(true, l10n))),
                          ] else
                            Expanded(child: BrandButton(text: 'Flip Card  ↕', type: BrandButtonType.primary, onTap: _flipCard)),
                          const SizedBox(width: 12),
                          _navControl(icon: Icons.chevron_right_rounded, label: 'NEXT', onTap: _currentIndex < _deck!.length - 1 ? _next : null, isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '← → arrow keys or Space to navigate',
                        style: AppTypography.mono.copyWith(
                          color: isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.1),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getMasteryColor(MasteryLevel? level, bool isDark) {
    switch (level) {
      case MasteryLevel.mastered: return AppColors.semanticGreen;
      case MasteryLevel.reviewing: return AppColors.gold500;
      case MasteryLevel.learning: return Colors.blue;
      default: return isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2);
    }
  }

  Widget _buildFront(DictionaryEntry entry, bool isDark) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
              ),
              child: Text(
                entry.language.toUpperCase(),
                style: AppTypography.mono.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.gold700,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              entry.indigenousWord,
              style: AppTypography.display.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 52,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              entry.partOfSpeechLabel,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  color: isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.2),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to reveal',
                  style: AppTypography.mono.copyWith(
                    color: isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(DictionaryEntry entry, AppLocalization l10n) {
    return BrandCard(
      theme: BrandCardTheme.cream,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(l10n.translate('translation'), style: AppTypography.mono.copyWith(color: AppColors.gold700, fontSize: 9, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(entry.translation, style: AppTypography.display.copyWith(color: AppColors.creamText, fontSize: 36, height: 1.1), textAlign: TextAlign.center),
            if (entry.usageContext.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.creamBorder)),
              Text(l10n.translate('example_usage'), style: AppTypography.mono.copyWith(color: AppColors.creamText3, fontSize: 9, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text('"${entry.usageContext}"', style: AppTypography.body.copyWith(color: AppColors.creamText2, fontStyle: FontStyle.italic, height: 1.5), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navControl({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.forest700 : AppColors.forest700.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: onTap != null ? 0.08 : 0.03)
                : Colors.black.withValues(alpha: onTap != null ? 0.08 : 0.03),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap != null
                  ? (isDark ? Colors.white70 : Colors.white)
                  : (isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.2)),
              size: 22,
            ),
            Text(
              label,
              style: AppTypography.mono.copyWith(
                color: onTap != null
                    ? (isDark ? Colors.white24 : Colors.white.withValues(alpha: 0.5))
                    : (isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.1)),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionModal(AppLocalization l10n) {
    HapticService.celebration();
    final config = ref.read(appConfigProvider).value ?? AppConfig.fromFirestore({});
    final bonusXp = _deck!.length * config.cardCompletionBonusXp;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) ref.read(firebaseServiceProvider).addXp(uid, bonusXp.toInt());
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BrandCard(
          theme: BrandCardTheme.cream,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 56)).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 600.ms),
              const SizedBox(height: 16),
              Text(l10n.translate('session_complete_msg'), style: AppTypography.display.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text("${l10n.translate('studied_all_cards').replaceAll('all cards.', 'all')} ${_deck!.length} cards.", style: AppTypography.body.copyWith(color: AppColors.creamText3)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.gold100, borderRadius: BorderRadius.circular(12)), child: Text('+$bonusXp XP EARNED', style: AppTypography.mono.copyWith(color: AppColors.gold700, fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: BrandButton(text: 'Again', type: BrandButtonType.secondary, onTap: () { Navigator.pop(context); setState(() { _currentIndex = 0; _isFlipped = false; _deck!.shuffle(Random()); }); _flipController.reset(); })),
                  const SizedBox(width: 12),
                  Expanded(child: BrandButton(text: 'Done', type: BrandButtonType.primary, onTap: () => Navigator.of(context)..pop()..pop())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: BrandedEmptyState(
          title: widget.isReviewMode ? 'All Caught Up!' : 'No Flashcards Yet',
          message: widget.isReviewMode ? 'You have reviewed all your due cards. Come back later for more reinforcement.' : 'Bookmark words from the Dictionary to start building your personal study deck.',
          emoji: widget.isReviewMode ? '🌿' : '💫',
          action: BrandButton(text: widget.isReviewMode ? '🏠  Back to Dashboard' : '📖  Go to Dictionary', type: BrandButtonType.primary, onTap: () => Navigator.pop(context)),
        ),
      ),
    );
  }
}
