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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';


class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

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

    // Keyboard shortcuts
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

  Future<void> _updateSRS(bool wasCorrect) async {
    HapticService.medium();

    final user = ref.read(authStateProvider).value;
    if (user == null || _deck == null) return;

    final entry = _deck![_currentIndex];
    final currentSrs =
        _srsData[entry.id] ??
        SRSProgress(wordId: entry.id, nextReview: DateTime.now());

    int newLevel;
    DateTime? lastFailure = currentSrs.lastFailure;
    int consecutiveCorrect = currentSrs.consecutiveCorrect;

    if (wasCorrect) {
      newLevel = min(currentSrs.level + 1, 5);
      consecutiveCorrect++;
      ref.read(firebaseServiceProvider).addXp(user.uid, 10);
    } else {
      newLevel = max(currentSrs.level - 1, 0);
      lastFailure = DateTime.now();
      consecutiveCorrect = 0;
    }

    // Leitner intervals: 1, 2, 4, 7, 14, 30 days
    final intervals = [1, 2, 4, 7, 14, 30];
    final nextReview = DateTime.now().add(Duration(days: intervals[newLevel]));

    final updatedSrs = currentSrs.copyWith(
      level: newLevel,
      nextReview: nextReview,
      lastReview: DateTime.now(),
      lastFailure: lastFailure,
      timesReviewed: currentSrs.timesReviewed + 1,
      consecutiveCorrect: consecutiveCorrect,
    );

    await ref
        .read(firebaseServiceProvider)
        .updateSRSProgress(user.uid, updatedSrs);

    if (!mounted) return;
    _next();

    if (wasCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Mastery Level Up! +10 XP',
                style: AppTypography.label.copyWith(color: Colors.white),
              ),
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
    final bookmarksAsync = user != null
        ? ref.watch(userBookmarksStreamProvider(user.uid))
        : const AsyncValue.data(<String>[]);
    final srsAsync = user != null
        ? ref.watch(srsProgressStreamProvider(user.uid))
        : const AsyncValue.data(<SRSProgress>[]);

    return dictionaryAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.forest800,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold500),
        ),
      ),
      error: (_, __) => _buildEmptyState(),
      data: (dictionary) {
        return bookmarksAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.forest800,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.gold500),
            ),
          ),
          error: (_, __) => _buildEmptyState(),
          data: (bookmarks) {
            return srsAsync.when(
              loading: () => const Scaffold(
                backgroundColor: AppColors.forest800,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.gold500),
                ),
              ),
              error: (_, __) => _buildEmptyState(),
              data: (srsList) {
                // Map SRS data for quick lookup
                _srsData = {for (var s in srsList) s.wordId: s};

                if (_deck == null) {
                  final bookmarkedEntries = dictionary
                      .where((entry) => bookmarks.contains(entry.id))
                      .toList();

                  if (bookmarkedEntries.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Smart Shuffling (SRS Expansion): Prioritize based on Forgetfulness Curves
                  final now = DateTime.now();
                  bookmarkedEntries.sort((a, b) {
                    final srsA = _srsData[a.id];
                    final srsB = _srsData[b.id];

                    double scoreA = 0;
                    double scoreB = 0;

                    if (srsA != null) {
                      // Overdue component
                      final overdue = now.difference(srsA.nextReview).inMinutes;
                      scoreA += max(0, overdue).toDouble();

                      // Forgetfulness Curve component:
                      // Prioritize words wrong long ago over words wrong recently
                      if (srsA.lastFailure != null) {
                        final timeSinceFail = now
                            .difference(srsA.lastFailure!)
                            .inMinutes;
                        // Boost score based on how long ago they failed (up to 3 days/4320 mins)
                        scoreA += min(4320, timeSinceFail) * 1.5;
                      }
                    } else {
                      scoreA = 999999; // New cards always first
                    }

                    if (srsB != null) {
                      final overdue = now.difference(srsB.nextReview).inMinutes;
                      scoreB += max(0, overdue).toDouble();

                      if (srsB.lastFailure != null) {
                        final timeSinceFail = now
                            .difference(srsB.lastFailure!)
                            .inMinutes;
                        scoreB += min(4320, timeSinceFail) * 1.5;
                      }
                    } else {
                      scoreB = 999999;
                    }

                    return scoreB.compareTo(scoreA); // Higher score first
                  });

                  final initialDeck = bookmarkedEntries.take(15).toList();

                  // Only set initial deck once to avoid reshuffling on every build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _deck = initialDeck;
                    });
                  });
                  return const Scaffold(
                    backgroundColor: AppColors.forest800,
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold500,
                      ),
                    ),
                  );
                }

                if (_deck!.isEmpty) return _buildEmptyState();

                final entry = _deck![_currentIndex];
                final progress = (_currentIndex + 1) / _deck!.length;
                final isLast = _currentIndex == _deck!.length - 1;
                final currentSrs = _srsData[entry.id];

                return Scaffold(
                  backgroundColor: AppColors.forest800,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'DAILY REVIEW',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 2,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Text(
                            '${_currentIndex + 1} / ${_deck!.length}',
                            style: AppTypography.mono.copyWith(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mastery: ${currentSrs?.mastery.name ?? "New"}',
                              style: AppTypography.mono.copyWith(
                                color: _getMasteryColor(currentSrs?.mastery),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}% done',
                              style: AppTypography.mono.copyWith(
                                color: AppColors.gold500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // The flip card
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
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(angle),
                                  child: isShowingFront
                                      ? _buildFront(entry)
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(pi),
                                          child: _buildBack(entry),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Hint
                        Text(
                          _isFlipped ? '' : 'Tap card to reveal answer',
                          style: AppTypography.label.copyWith(
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Navigation Controls
                        Row(
                          children: [
                            // Previous
                            _navControl(
                              icon: Icons.chevron_left_rounded,
                              label: 'PREV',
                              onTap: _currentIndex > 0 ? _previous : null,
                            ),
                            const SizedBox(width: 12),

                            // Forgot / Learned
                            if (_isFlipped) ...[
                              Expanded(
                                child: BrandButton(
                                  text: 'Hard',
                                  type: BrandButtonType.secondary,
                                  onTap: () => _updateSRS(false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: BrandButton(
                                  text: isLast ? 'Finish ✓' : 'Easy ✓',
                                  type: BrandButtonType.primary,
                                  onTap: isLast
                                      ? _showCompletionModal
                                      : () => _updateSRS(true),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: BrandButton(
                                  text: 'Flip Card  ↕',
                                  type: BrandButtonType.primary,
                                  onTap: _flipCard,
                                ),
                              ),

                            const SizedBox(width: 12),
                            // Next
                            _navControl(
                              icon: Icons.chevron_right_rounded,
                              label: 'NEXT',
                              onTap: _currentIndex < _deck!.length - 1
                                  ? _next
                                  : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'â† → arrow keys or Space to navigate',
                          style: AppTypography.mono.copyWith(
                            color: Colors.white12,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getMasteryColor(MasteryLevel? level) {
    switch (level) {
      case MasteryLevel.mastered:
        return AppColors.semanticGreen;
      case MasteryLevel.reviewing:
        return AppColors.gold500;
      case MasteryLevel.learning:
        return Colors.blue;
      default:
        return Colors.white24;
    }
  }

  Widget _buildFront(DictionaryEntry entry) {
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
                color: AppColors.gold500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold500.withOpacity(0.3),
                ),
              ),
              child: Text(
                entry.language.toUpperCase(),
                style: AppTypography.mono.copyWith(
                  color: AppColors.gold500,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              entry.indigenousWord,
              style: AppTypography.display.copyWith(
                color: Colors.white,
                fontSize: 52,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              entry.partOfSpeechLabel,
              style: AppTypography.label.copyWith(color: Colors.white24),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app, color: Colors.white12, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Tap to reveal',
                  style: AppTypography.mono.copyWith(
                    color: Colors.white12,
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

  Widget _buildBack(DictionaryEntry entry) {
    return BrandCard(
      theme: BrandCardTheme.cream,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'TRANSLATION',
              style: AppTypography.mono.copyWith(
                color: AppColors.gold700,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              entry.translation,
              style: AppTypography.display.copyWith(
                color: AppColors.creamText,
                fontSize: 36,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            if (entry.usageContext.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: AppColors.creamBorder),
              ),
              Text(
                'EXAMPLE USAGE',
                style: AppTypography.mono.copyWith(
                  color: AppColors.creamText3,
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '"${entry.usageContext}"',
                style: AppTypography.body.copyWith(
                  color: AppColors.creamText2,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.forest700
              : AppColors.forest700.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(onTap != null ? 0.08 : 0.03),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap != null ? Colors.white70 : Colors.white12,
              size: 22,
            ),
            Text(
              label,
              style: AppTypography.mono.copyWith(
                color: onTap != null ? Colors.white24 : Colors.white10,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionModal() {
    HapticService.celebration();

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(firebaseServiceProvider).addXp(uid, _deck!.length * 10);
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BrandCard(
          theme: BrandCardTheme.cream,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ðŸ†', style: TextStyle(fontSize: 56))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.1, duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                'Session Complete!',
                style: AppTypography.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'You studied all ${_deck!.length} cards.',
                style: AppTypography.body.copyWith(color: AppColors.creamText3),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${_deck!.length * 10} XP EARNED',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.gold700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BrandButton(
                      text: 'Again',
                      type: BrandButtonType.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 0;
                          _isFlipped = false;
                          _deck!.shuffle(Random());
                        });
                        _flipController.reset();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrandButton(
                      text: 'Done',
                      type: BrandButtonType.primary,
                      onTap: () => Navigator.of(context)
                        ..pop()
                        ..pop(),
                    ),
                  ),
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
      backgroundColor: AppColors.forest800,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text(
                'No Flashcards Yet',
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Bookmark words from the Dictionary to start building your personal study deck.',
                style: AppTypography.body.copyWith(
                  color: Colors.white38,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              BrandButton(
                text: '📖  Go to Dictionary',
                type: BrandButtonType.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


