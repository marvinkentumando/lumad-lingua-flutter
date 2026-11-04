import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:lumad_lingua/models/sentiment_post.dart';
import 'package:lumad_lingua/services/sentiment_service.dart';
import '../services/haptic_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/app_shimmer_skeleton.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communitySentimentPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          bottom: false,
          child: postsAsync.when(
            data: (posts) => _buildLearnerContent(posts, isDark),
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

  Widget _buildLearnerContent(List<SentimentPost> posts, bool isDark) {
    final bool hasData = posts.isNotEmpty;

    // Calculate friendly vitality percentage
    final totalPosts = posts.length;
    final posCount = posts.where((p) => p.sentimentCategory == 'positive').length;
    final vitalityIndex = !hasData ? 75 : ((posCount / totalPosts) * 100).clamp(50, 99).toInt();

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
                _buildVitalityBannerCard(vitalityIndex, hasData, isDark),
                const SizedBox(height: 24),
                _buildSectionHeader('Trending Words & Expressions 🌿', isDark),
                const SizedBox(height: 12),
                _buildLearnerKeywordCloud(posts, isDark),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Community Reflections', isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.semanticGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shield_rounded, size: 12, color: AppColors.semanticGreen),
                          SizedBox(width: 4),
                          Text(
                            'Privacy Safe 🛡️',
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
                ).animate(delay: (60 * index).ms).fadeIn().slideY(begin: 0.05),
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
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
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
                  size: 10,
                ),
                SizedBox(width: 6),
                Text(
                  'COMMUNITY VITALITY',
                  style: TextStyle(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'Tribal Expressions & Reflections',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalityBannerCard(int vitalityIndex, bool hasData, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: BrandCard(
        theme: BrandCardTheme.gold,
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CULTURAL HEALTH',
                    style: AppTypography.label.copyWith(
                      color: AppColors.forest900.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Language Vitality 🌿',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.forest900,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasData
                        ? 'Mansaka language usage is flourishing across community expressions and everyday dialogues!'
                        : 'Explore real-world phrases, learn new vocabulary, and share tribal encouragement.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.forest900.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.forest900,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$vitalityIndex%',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.gold500,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'VITAL',
                    style: AppTypography.label.copyWith(
                      color: Colors.white60,
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnerKeywordCloud(List<SentimentPost> posts, bool isDark) {
    if (posts.isEmpty) {
      return Text(
        'Check back soon for community keyword highlights! 🌿',
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 12,
        ),
      );
    }

    final keywords = posts.expand((p) => p.redactedKeywords).toList();
    final counts = <String, int>{};
    for (var k in keywords) {
      counts[k] = (counts[k] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.take(10).map((entry) {
        return ActionChip(
          onPressed: () {
            context.push('/dictionary?q=${Uri.encodeComponent(entry.key)}');
          },
          avatar: const Icon(
            Icons.menu_book_rounded,
            size: 14,
            color: AppColors.gold500,
          ),
          label: Text(
            '#${entry.key}',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.forest900.withValues(alpha: 0.05),
          side: const BorderSide(color: AppColors.gold500, width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.gold500,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Learn this word',
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (isSparked) {
                      _sparkedPostIds.remove(post.id);
                    } else {
                      _sparkedPostIds.add(post.id);
                    }
                  });
                  HapticService.selection();
                },
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
                onPressed: () {
                  setState(() {
                    if (isSaved) {
                      _savedPostIds.remove(post.id);
                    } else {
                      _savedPostIds.add(post.id);
                    }
                  });
                  HapticService.selection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved ? 'Reflection removed' : 'Reflection saved to profile 🌿',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
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

  Widget _buildLearnerSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 20),
          AppShimmerSkeleton(height: 120, borderRadius: 28),
          SizedBox(height: 24),
          AppShimmerSkeleton(width: 180, height: 16, borderRadius: 4),
          SizedBox(height: 12),
          AppShimmerSkeleton(height: 50, borderRadius: 20),
          SizedBox(height: 24),
          AppShimmerSkeleton(height: 160, borderRadius: 24),
          SizedBox(height: 16),
          AppShimmerSkeleton(height: 160, borderRadius: 24),
        ],
      ),
    );
  }
}
