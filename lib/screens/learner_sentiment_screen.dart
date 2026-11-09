import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:lumad_lingua/models/sentiment_post.dart';
import 'package:lumad_lingua/services/sentiment_service.dart';
import '../services/haptic_service.dart';
import '../services/auth_service.dart';
import '../providers/student_provider.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/app_shimmer_skeleton.dart';
import '../widgets/spirit_particle_overlay.dart';
import '../utils/app_localization.dart';

enum _GameState { intro, playing, summary }

class LearnerSentimentScreen extends ConsumerStatefulWidget {
  const LearnerSentimentScreen({super.key});

  @override
  ConsumerState<LearnerSentimentScreen> createState() => _LearnerSentimentScreenState();
}

class _LearnerSentimentScreenState extends ConsumerState<LearnerSentimentScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedTranslationPostIds = {};
  final Set<String> _expandedPostTextIds = {};
  final Map<String, String> _userPostGuesses = {};
  final Set<String> _correctlyGuessedPosts = {};

  _GameState _gameState = _GameState.intro;
  List<SentimentPost> _shuffledPosts = [];
  int _currentIndex = 0;
  int _roundCorrectCount = 0;
  int _roundTotalXp = 0;
  bool _isThrowingAway = false;
  String? _lastGuessStatusText;
  bool? _isLastGuessCorrect;
  int _selectedCardCount = 10;

  void _toggleTranslation(String postId) {
    setState(() {
      if (_expandedTranslationPostIds.contains(postId)) {
        _expandedTranslationPostIds.remove(postId);
      } else {
        _expandedTranslationPostIds.add(postId);
      }
    });
    HapticService.selection();
  }

  void _togglePostTextExpansion(String postId) {
    setState(() {
      if (_expandedPostTextIds.contains(postId)) {
        _expandedPostTextIds.remove(postId);
      } else {
        _expandedPostTextIds.add(postId);
      }
    });
    HapticService.selection();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedGuesses();
  }

  Future<void> _loadSavedGuesses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final guessesList = prefs.getStringList('sentiment_guesses_$userId') ?? [];
    final correctList = prefs.getStringList('sentiment_correct_$userId') ?? [];
    final guesses = <String, String>{};
    for (final item in guessesList) {
      final parts = item.split(':');
      if (parts.length == 2) {
        guesses[parts[0]] = parts[1];
      }
    }
    if (mounted) {
      setState(() {
        _userPostGuesses.addAll(guesses);
        _correctlyGuessedPosts.addAll(correctList);
      });
    }
  }

  void _startQuest(List<SentimentPost> posts) {
    if (posts.isEmpty) return;
    final sliced = _selectedCardCount == -1
        ? List<SentimentPost>.from(posts)
        : posts.take(_selectedCardCount).toList();
    setState(() {
      _shuffledPosts = sliced..shuffle();
      _currentIndex = 0;
      _roundCorrectCount = 0;
      _roundTotalXp = 0;
      _isThrowingAway = false;
      _lastGuessStatusText = null;
      _isLastGuessCorrect = null;
      _gameState = _GameState.playing;
    });
    HapticService.selection();
  }

  Future<void> _handleSentimentChoice(SentimentPost post, String guessedCategory) async {
    if (_isThrowingAway) return;

    final rawCat = post.sentimentCategory.toLowerCase();
    String normalizedCorrect = 'neutral';
    if (rawCat.contains('pos') || rawCat.contains('enc') || rawCat.contains('grat') || rawCat.contains('joy')) {
      normalizedCorrect = 'positive';
    } else if (rawCat.contains('neg') || rawCat.contains('som') || rawCat.contains('sad')) {
      normalizedCorrect = 'negative';
    } else {
      normalizedCorrect = 'neutral';
    }

    final isCorrect = guessedCategory == normalizedCorrect;
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';

    _userPostGuesses[post.id] = guessedCategory;
    if (isCorrect) {
      _correctlyGuessedPosts.add(post.id);
      _roundCorrectCount++;
      _roundTotalXp += 25;
      ref.read(studentProvider.notifier).addXp(25);
      ref.read(studentProvider.notifier).addMistCrystals(15);
      HapticService.celebration();
      if (!mounted) return;
      showSpiritParticles(context, duration: const Duration(seconds: 2));
    } else {
      HapticService.error();
    }

    final guessesList = _userPostGuesses.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('sentiment_guesses_$userId', guessesList);
    await prefs.setStringList('sentiment_correct_$userId', _correctlyGuessedPosts.toList());

    setState(() {
      _isThrowingAway = true;
      _isLastGuessCorrect = isCorrect;
      _lastGuessStatusText = isCorrect
          ? 'Correct tone! (+25 XP)'
          : 'Tone was "$normalizedCorrect"';
    });

    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    setState(() {
      _isThrowingAway = false;
      _currentIndex++;
      if (_currentIndex >= _shuffledPosts.length) {
        _gameState = _GameState.summary;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communitySentimentPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: postsAsync.when(
            data: (posts) => _buildGameView(posts, isDark, l10n),
            loading: () => _buildLearnerSkeleton(isDark),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load community vitality. Please check your connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.forest900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameView(List<SentimentPost> posts, bool isDark, AppLocalization l10n) {
    switch (_gameState) {
      case _GameState.intro:
        return _buildIntroScreen(posts, isDark, l10n);
      case _GameState.playing:
        return _buildFlashcardGame(isDark, l10n);
      case _GameState.summary:
        return _buildSummaryScreen(isDark, l10n);
    }
  }

  Widget _buildIntroScreen(List<SentimentPost> posts, bool isDark, AppLocalization l10n) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.forest900,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Text(
                'COMMUNITY VITALITY QUEST',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 1.5,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BrandCard(
            theme: BrandCardTheme.vibrant,
            padding: const EdgeInsets.all(24),
            borderRadius: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        color: AppColors.gold500,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timbang sa Tingog',
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Flashcard Sentiment Quest',
                            style: AppTypography.body.copyWith(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Read real community posts, identify their tone as Positive, Neutral, or Negative, and throw completed cards away to earn XP and Mist Crystals!',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatBadge('Posts', '${posts.length}', Icons.layers_outlined),
                    const SizedBox(width: 12),
                    _buildStatBadge('Reward', '+25 XP', Icons.bolt_rounded),
                    const SizedBox(width: 12),
                    _buildStatBadge('Gems', '+15', Icons.diamond_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Cards per Round:',
                  style: AppTypography.label.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCardCountChip('10 Cards', 10),
                    const SizedBox(width: 8),
                    _buildCardCountChip('20 Cards', 20),
                    const SizedBox(width: 8),
                    _buildCardCountChip('All Cards', -1),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _startQuest(posts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold500,
                      foregroundColor: AppColors.forest900,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'START QUEST',
                      style: AppTypography.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.forest900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildCardCountChip(String label, int count) {
    final isSelected = _selectedCardCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCardCount = count);
          HapticService.selection();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold500 : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.gold500 : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.forest900 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.gold500),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardGame(bool isDark, AppLocalization l10n) {
    if (_currentIndex >= _shuffledPosts.length) {
      return const SizedBox.shrink();
    }

    final post = _shuffledPosts[_currentIndex];
    final total = _shuffledPosts.length;
    final progress = (_currentIndex + 1) / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : AppColors.forest900,
                ),
                onPressed: () {
                  setState(() {
                    _gameState = _GameState.intro;
                  });
                },
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/$total',
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_lastGuessStatusText != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (_isLastGuessCorrect ?? false)
                    ? AppColors.semanticGreen.withValues(alpha: 0.2)
                    : AppColors.gold500.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isLastGuessCorrect ?? false)
                      ? AppColors.semanticGreen
                      : AppColors.gold500,
                ),
              ),
              child: Text(
                _lastGuessStatusText!,
                style: TextStyle(
                  color: (_isLastGuessCorrect ?? false)
                      ? AppColors.semanticGreen
                      : AppColors.gold500,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Container(
                key: ValueKey(post.id),
                child: Builder(
                  builder: (context) {
                    final cardWidget = _buildCardFront(post, isDark);
                    if (_isThrowingAway) {
                      return cardWidget
                          .animate()
                          .slideY(begin: 0, end: -1.2, duration: 400.ms, curve: Curves.easeInBack)
                          .fadeOut(duration: 350.ms);
                    }
                    return cardWidget.animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Identify Card Sentiment',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest900,
              letterSpacing: 1.2,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGameActionButton(post, 'positive', 'Positive', AppColors.semanticGreen),
              const SizedBox(width: 8),
              _buildGameActionButton(post, 'neutral', 'Neutral', AppColors.gold500),
              const SizedBox(width: 8),
              _buildGameActionButton(post, 'negative', 'Negative', AppColors.semanticRed),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCardFront(SentimentPost post, bool isDark) {
    return BrandCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: AppColors.gold500, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lumad Community Member',
                            style: AppTypography.h3.copyWith(
                              color: isDark ? Colors.white : AppColors.forest900,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.gold500),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.relativeTime,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final bool isTextExpanded = _expandedPostTextIds.contains(post.id);
                final bool isLengthy = post.redactedOriginalText.length > 160;
                final displayText = (isLengthy && !isTextExpanded)
                    ? '${post.redactedOriginalText.substring(0, 160)}...'
                    : post.redactedOriginalText;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (isLengthy) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _togglePostTextExpansion(post.id),
                        child: Text(
                          isTextExpanded ? 'See less' : 'See more',
                          style: const TextStyle(
                            color: AppColors.gold500,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (post.redactedEnglishTranslation.isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _toggleTranslation(post.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _expandedTranslationPostIds.contains(post.id)
                            ? Icons.translate_rounded
                            : Icons.g_translate_rounded,
                        size: 14,
                        color: AppColors.gold500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expandedTranslationPostIds.contains(post.id)
                            ? 'Hide English'
                            : 'Translate to English',
                        style: const TextStyle(
                          color: AppColors.gold500,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandedTranslationPostIds.contains(post.id)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Text(
                    post.redactedEnglishTranslation,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest700,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameActionButton(SentimentPost post, String category, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleSentimentChoice(post, category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryScreen(bool isDark, AppLocalization l10n) {
    final total = _shuffledPosts.length;
    final accuracy = total > 0 ? ((_roundCorrectCount / total) * 100).round() : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: BrandCard(
          theme: BrandCardTheme.vibrant,
          padding: const EdgeInsets.all(28),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.gold500,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'QUEST COMPLETED!',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Great Job, Scholar!',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$accuracy%',
                          style: const TextStyle(
                            color: AppColors.gold500,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Accuracy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '$_roundCorrectCount/$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Correct Cards',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '+$_roundTotalXp',
                          style: const TextStyle(
                            color: AppColors.semanticGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'XP Earned',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _startQuest(_shuffledPosts),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold500,
                    foregroundColor: AppColors.forest900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'PLAY AGAIN',
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.forest900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'EXIT TO DASHBOARD',
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildLearnerSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 20),
          AppShimmerSkeleton(height: 120, borderRadius: 28),
          SizedBox(height: 24),
          AppShimmerSkeleton(height: 160, borderRadius: 24),
          SizedBox(height: 16),
          AppShimmerSkeleton(height: 160, borderRadius: 24),
        ],
      ),
    );
  }
}
