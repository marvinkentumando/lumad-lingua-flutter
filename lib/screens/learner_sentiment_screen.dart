import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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

class LearnerSentimentScreen extends ConsumerStatefulWidget {
  const LearnerSentimentScreen({super.key});

  @override
  ConsumerState<LearnerSentimentScreen> createState() => _LearnerSentimentScreenState();
}

class _LearnerSentimentScreenState extends ConsumerState<LearnerSentimentScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _savedPostIds = {};
  final Set<String> _sparkedPostIds = {};
  bool _checkedInToday = false;
  String? _selectedMood;
  bool _minigameCompletedToday = false;
  String? _minigameSelectedGuess;
  bool _minigameCorrect = false;

  @override
  void initState() {
    super.initState();
    _checkDailyCheckInStatus();
    _checkMiniGameStatus();
    _loadSavedAndSparkedPosts();
  }

  Future<void> _loadSavedAndSparkedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final savedList = prefs.getStringList('saved_sentiment_posts_$userId') ?? [];
    final sparkedList = prefs.getStringList('sparked_sentiment_posts_$userId') ?? [];
    if (mounted) {
      setState(() {
        _savedPostIds.addAll(savedList);
        _sparkedPostIds.addAll(sparkedList);
      });
    }
  }

  Future<void> _toggleSavePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'saved_sentiment_posts_$userId';
    final isSaved = _savedPostIds.contains(postId);
    setState(() {
      if (isSaved) {
        _savedPostIds.remove(postId);
      } else {
        _savedPostIds.add(postId);
      }
    });
    await prefs.setStringList(key, _savedPostIds.toList());
    HapticService.selection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved ? 'Reflection removed from saved items' : 'Reflection saved to profile 🌿',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSparkPost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'sparked_sentiment_posts_$userId';
    final isSparked = _sparkedPostIds.contains(postId);
    setState(() {
      if (isSparked) {
        _sparkedPostIds.remove(postId);
      } else {
        _sparkedPostIds.add(postId);
      }
    });
    await prefs.setStringList(key, _sparkedPostIds.toList());
    HapticService.selection();
  }

  Future<void> _checkDailyCheckInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'sentiment_checkin_${userId}_$dateStr';
    final moodKey = 'sentiment_mood_${userId}_$dateStr';
    if (mounted) {
      setState(() {
        _checkedInToday = prefs.getBool(key) ?? false;
        _selectedMood = prefs.getString(moodKey);
      });
    }
  }

  Future<void> _checkMiniGameStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'sentiment_minigame_${userId}_$dateStr';
    final guessKey = 'sentiment_minigame_guess_${userId}_$dateStr';
    final correctKey = 'sentiment_minigame_correct_${userId}_$dateStr';
    if (mounted) {
      setState(() {
        _minigameCompletedToday = prefs.getBool(key) ?? false;
        _minigameSelectedGuess = prefs.getString(guessKey);
        _minigameCorrect = prefs.getBool(correctKey) ?? false;
      });
    }
  }

  Future<void> _submitMiniGameGuess(String guess, String correctCategory) async {
    if (_minigameCompletedToday) return;

    final isCorrect = guess.toLowerCase().trim() == correctCategory.toLowerCase().trim();
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'sentiment_minigame_${userId}_$dateStr';
    final guessKey = 'sentiment_minigame_guess_${userId}_$dateStr';
    final correctKey = 'sentiment_minigame_correct_${userId}_$dateStr';

    await prefs.setBool(key, true);
    await prefs.setString(guessKey, guess);
    await prefs.setBool(correctKey, isCorrect);

    if (isCorrect) {
      ref.read(studentProvider.notifier).addXp(25);
      ref.read(studentProvider.notifier).addMistCrystals(15);
      HapticService.celebration();
      if (!mounted) return;
      showSpiritParticles(context, duration: const Duration(seconds: 3));
    } else {
      HapticService.error();
    }

    setState(() {
      _minigameCompletedToday = true;
      _minigameSelectedGuess = guess;
      _minigameCorrect = isCorrect;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCorrect
                ? 'Correct tone! +25 XP & +15 Mist Crystals earned 💎🎉'
                : 'Not quite! The correct tone was "$correctCategory". Keep practicing!',
            style: AppTypography.label.copyWith(color: Colors.white),
          ),
          backgroundColor: isCorrect ? AppColors.semanticGreen : AppColors.gold500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logDailyCheckIn(String moodDesc, String mansakaTerm) async {
    if (_checkedInToday) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? 'guest';
    final key = 'sentiment_checkin_${userId}_$dateStr';
    final moodKey = 'sentiment_mood_${userId}_$dateStr';

    final displayMood = '$mansakaTerm ($moodDesc)';
    await prefs.setBool(key, true);
    await prefs.setString(moodKey, displayMood);

    if (!mounted) return;

    ref.read(studentProvider.notifier).addXp(10);
    ref.read(studentProvider.notifier).incrementStreak();

    HapticService.celebration();
    if (!mounted) return;
    showSpiritParticles(context, duration: const Duration(seconds: 3));

    setState(() {
      _checkedInToday = true;
      _selectedMood = displayMood;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Spirit Check-in logged! "$displayMood" recorded. +10 XP earned 🎉',
            style: AppTypography.label.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          bottom: false,
          child: postsAsync.when(
            data: (posts) => _buildLearnerContent(posts, isDark, l10n),
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

  Widget _buildLearnerContent(List<SentimentPost> posts, bool isDark, AppLocalization l10n) {
    final bool hasData = posts.isNotEmpty;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildLearnerAppBar(isDark),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSpiritCheckInCard(isDark),
                const SizedBox(height: 16),
                _buildSentimentMiniGameCard(posts, isDark),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(l10n.translate('community_reflections'), isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.semanticGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, size: 12, color: AppColors.semanticGreen),
                          const SizedBox(width: 4),
                          Text(
                            l10n.translate('privacy_safe'),
                            style: const TextStyle(
                              color: AppColors.semanticGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!hasData) _buildLearnerEmptyState(isDark),
              ],
            ),
          ),
        ),
        if (hasData)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildReflectionCard(
                  posts[index],
                  index,
                  isDark,
                ).animate(delay: (60 * (index % 5)).ms).fadeIn().slideY(begin: 0.05),
                childCount: posts.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildLearnerAppBar(bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.forest900,
        ),
        onPressed: () => context.pop(),
      ),
      expandedHeight: 80,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 52, bottom: 14, right: 16),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold500,
                  size: 9,
                ),
                SizedBox(width: 4),
                Text(
                  'COMMUNITY VITALITY',
                  style: TextStyle(
                    color: AppColors.gold500,
                    letterSpacing: 1.5,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Tribal Expressions & Reflections',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionCard(SentimentPost post, int index, bool isDark) {
    final isSaved = _savedPostIds.contains(post.id);
    final isSparked = _sparkedPostIds.contains(post.id);

    return BrandCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_rounded, color: AppColors.gold500, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MANSAKA REFLECTION',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Text(
                post.relativeTime,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.redactedOriginalText,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (post.redactedFilipinoTranslation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Filipino: ${post.redactedFilipinoTranslation}',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.forest700,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (post.redactedEnglishTranslation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'English: ${post.redactedEnglishTranslation}',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () {
                  final query = post.keywords.isNotEmpty
                      ? post.keywords.first
                      : (post.linkedDictionaryEntryIds.isNotEmpty
                          ? post.linkedDictionaryEntryIds.first
                          : '');
                  if (query.isNotEmpty) {
                    context.push('/dictionary?q=${Uri.encodeComponent(query)}');
                  } else {
                    context.push('/dictionary');
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.gold500,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Learn this word',
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => _toggleSparkPost(post.id),
                icon: Icon(
                  isSparked ? Icons.bolt_rounded : Icons.bolt_outlined,
                  color: isSparked
                      ? AppColors.gold500
                      : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
                tooltip: 'Spark',
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => _toggleSavePost(post.id),
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isSaved
                      ? AppColors.gold500
                      : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
                tooltip: 'Save',
              ),
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  final shareText =
                      '${post.originalText}\n${post.englishTranslation.isNotEmpty ? "(${post.englishTranslation})" : ""}\n\nVia LUMAD Lingua';
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 44,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'Awaiting Community Expressions',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Community reflections and sacred phrases will appear here as learners share progress.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: AppColors.gold500,
        letterSpacing: 1.5,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSpiritCheckInCard(bool isDark) {
    final moods = [
      {'name': 'Madyaw', 'desc': 'Great / Flourishing', 'emoji': '🌿'},
      {'name': 'Malipayon', 'desc': 'Joyful / Happy', 'emoji': '✨'},
      {'name': 'Naghunahuna', 'desc': 'Reflective / Thoughtful', 'emoji': '🌾'},
      {'name': 'Malinawon', 'desc': 'Peaceful / Calm', 'emoji': '🍃'},
    ];

    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌾', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY SPIRIT CHECK-IN',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kasing-kasing 🌿',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_checkedInToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.semanticGreen.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.semanticGreen.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppColors.semanticGreen),
                      SizedBox(width: 4),
                      Text(
                        'Logged (+10 XP)',
                        style: TextStyle(
                          color: AppColors.semanticGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _checkedInToday
                ? 'You checked in today feeling "${_selectedMood ?? 'Madyaw'}". Come back tomorrow for your next spirit check-in!'
                : 'How is your spirit today? Choose your feeling in Mansaka/Cebuano to earn +10 XP and boost your streak:',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (!_checkedInToday) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moods.map((m) {
                return InkWell(
                  onTap: () => _logDailyCheckIn(m['desc']!, m['name']!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m['emoji']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              m['desc']!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentimentMiniGameCard(List<SentimentPost> posts, bool isDark) {
    final now = DateTime.now();
    final challengePost = posts.isNotEmpty
        ? posts[now.day % posts.length]
        : SentimentPost(
            id: 'demo_1',
            originalText: 'Madyaw na adlaw kanatong tanan! Padayon ta sa pagpangga sa atong pinulongan.',
            filipinoTranslation: 'Magandang araw sa ating lahat! Patuloy nating mahalin ang ating wika.',
            englishTranslation: 'Good day to us all! Let us continue cherishing our language.',
            sentimentCategory: 'encouraging',
          );

    final categoryDisplayMap = {
      'positive': 'Positive / Encouraging',
      'neutral': 'Neutral / Reflective',
      'negative': 'Negative / Somber',
      'encouraging': 'Positive / Encouraging',
      'gratitude': 'Gratitude / Sacred',
    };

    final rawCat = challengePost.sentimentCategory.toLowerCase();
    final correctTone = categoryDisplayMap[rawCat] ??
        (challengePost.sentimentCategory.isNotEmpty
            ? challengePost.sentimentCategory[0].toUpperCase() + challengePost.sentimentCategory.substring(1)
            : 'Positive / Encouraging');

    final baseOptions = ['Positive / Encouraging', 'Neutral / Reflective', 'Negative / Somber', 'Gratitude / Sacred'];
    final options = List<String>.from(baseOptions);
    if (!options.contains(correctTone)) {
      options[0] = correctTone;
    }

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.forest900.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY TONE CHALLENGE',
                      style: AppTypography.label.copyWith(
                        color: AppColors.forest900.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Timbang sa Tingog 🧩',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.forest900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_minigameCompletedToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _minigameCorrect ? AppColors.semanticGreen : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _minigameCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _minigameCorrect ? '+25 XP / +15 Gems' : 'Completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Read the community excerpt below and guess its emotional tone:',
            style: AppTypography.body.copyWith(
              color: AppColors.forest900.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forest900.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.forest900.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${challengePost.redactedOriginalText}"',
                  style: AppTypography.body.copyWith(
                    color: AppColors.forest900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (challengePost.redactedEnglishTranslation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '(${challengePost.redactedEnglishTranslation})',
                    style: TextStyle(
                      color: AppColors.forest900.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_minigameCompletedToday) ...[
            if (_minigameCorrect)
              Text(
                'Your guess: "${_minigameSelectedGuess ?? ''}" (Correct! 🎉)',
                style: AppTypography.label.copyWith(
                  color: AppColors.forest900,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your guess: "${_minigameSelectedGuess ?? ''}" (Incorrect ❌)',
                    style: AppTypography.label.copyWith(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Correct tone: "$correctTone"',
                    style: AppTypography.body.copyWith(
                      color: AppColors.forest900,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ] else ...[
            Text(
              'Select the correct tone:',
              style: AppTypography.label.copyWith(
                color: AppColors.forest900,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                return ElevatedButton(
                  onPressed: () => _submitMiniGameGuess(opt, correctTone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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
