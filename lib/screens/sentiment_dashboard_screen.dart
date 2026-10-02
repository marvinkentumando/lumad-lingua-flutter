import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:lumad_lingua/models/sentiment_post.dart';
import 'package:lumad_lingua/services/sentiment_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/app_shimmer_skeleton.dart';

class SentimentDashboardScreen extends ConsumerStatefulWidget {
  const SentimentDashboardScreen({super.key});

  @override
  ConsumerState<SentimentDashboardScreen> createState() =>
      _SentimentDashboardScreenState();
}

class _SentimentDashboardScreenState
    extends ConsumerState<SentimentDashboardScreen> {
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
            data: (posts) => _buildMainContent(posts, isDark),
            loading: () => _buildDashboardSkeleton(isDark),
            error: (e, _) => Center(
              child: Text(
                'Monitor Error: $e',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.forest900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<SentimentPost> posts, bool isDark) {
    final bool hasData = posts.isNotEmpty;

    // Aggregate metrics if data exists
    final totalPosts = posts.length;
    final posCount =
        posts.where((p) => p.sentimentCategory == 'positive').length;
    final neuCount =
        posts.where((p) => p.sentimentCategory == 'neutral').length;
    final negCount =
        posts.where((p) => p.sentimentCategory == 'negative').length;

    final overallIndex = !hasData ? 0 : ((posCount / totalPosts) * 100).toInt();

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(isDark),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSentimentSummaryCard(
                  overallIndex: overallIndex,
                  hasData: hasData,
                  totalPosts: totalPosts,
                  posCount: posCount,
                  neuCount: neuCount,
                  negCount: negCount,
                  isDark: isDark,
                ),
                const SizedBox(height: 28),
                _buildSectionHeader('Sentiment Distribution', isDark),
                const SizedBox(height: 12),
                _buildSentimentDistributionSection(
                  hasData: hasData,
                  totalPosts: totalPosts,
                  posCount: posCount,
                  neuCount: neuCount,
                  negCount: negCount,
                  isDark: isDark,
                ),
                const SizedBox(height: 28),
                _buildSectionHeader('Dominant Keywords', isDark),
                const SizedBox(height: 12),
                _buildKeywordCloud(posts, isDark),
                const SizedBox(height: 28),
                _buildSectionHeader('Community Sentiment Entries', isDark),
                const SizedBox(height: 16),
                if (!hasData) _buildNoDataState(isDark),
              ],
            ),
          ),
        ),
        if (hasData)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSentimentPostCard(
                  posts[index],
                  index,
                  isDark,
                ).animate(delay: (80 * index).ms).fadeIn().slideX(begin: 0.05),
                childCount: posts.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
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
      expandedHeight: 110,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold500,
                  size: 10,
                ),
                const SizedBox(width: 6),
                Text(
                  'COMMUNITY SENTIMENT MONITOR',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            Text(
              'Mansaka Community Sentiment',
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

  Widget _buildSentimentSummaryCard({
    required int overallIndex,
    required bool hasData,
    required int totalPosts,
    required int posCount,
    required int neuCount,
    required int negCount,
    required bool isDark,
  }) {
    final statusColor = !hasData
        ? Colors.white24
        : (overallIndex >= 60
            ? AppColors.semanticGreen
            : (overallIndex >= 40 ? AppColors.gold500 : AppColors.semanticRed));

    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(28),
        borderRadius: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SENTIMENT OVERVIEW',
                        style: AppTypography.label.copyWith(
                          color: hasData
                              ? statusColor.withValues(alpha: 0.8)
                              : Colors.white24,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overall Index',
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasData
                            ? 'Aggregated analysis based on human-validated community dataset.'
                            : 'Community sentiment monitoring active. Awaiting validated sentiment dataset connection.',
                        style: AppTypography.body.copyWith(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: hasData ? overallIndex / 100 : 0,
                        strokeWidth: 10,
                        backgroundColor: Colors.white10,
                        color: statusColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasData ? '$overallIndex%' : '--',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'INDEX',
                          style: AppTypography.label.copyWith(
                            color: Colors.white24,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentDistributionSection({
    required bool hasData,
    required int totalPosts,
    required int posCount,
    required int neuCount,
    required int negCount,
    required bool isDark,
  }) {
    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.forest900.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.forest900.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              color: isDark
                  ? Colors.white24
                  : AppColors.forest900.withValues(alpha: 0.2),
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              'Sentiment distribution data will appear here once the validated dataset is connected. 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white60
                    : AppColors.forest900.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final posPct = totalPosts > 0 ? (posCount / totalPosts * 100).toInt() : 0;
    final neuPct = totalPosts > 0 ? (neuCount / totalPosts * 100).toInt() : 0;
    final negPct = totalPosts > 0 ? (negCount / totalPosts * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(
          child: _buildCategoryCard(
            'Positive',
            '$posPct%',
            '$posCount posts',
            Icons.sentiment_satisfied_alt_rounded,
            AppColors.semanticGreen,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryCard(
            'Neutral',
            '$neuPct%',
            '$neuCount posts',
            Icons.sentiment_neutral_rounded,
            AppColors.gold500,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryCard(
            'Negative',
            '$negPct%',
            '$negCount posts',
            Icons.sentiment_dissatisfied_rounded,
            AppColors.semanticRed,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String label,
    String percentage,
    String countStr,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.forest900.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            percentage,
            style: AppTypography.h3.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            countStr,
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordCloud(List<SentimentPost> posts, bool isDark) {
    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.forest900.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.forest900.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          'Dominant keywords will appear once community sentiment posts are loaded. 🌿',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark
                ? Colors.white60
                : AppColors.forest900.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      );
    }

    final keywords = posts.expand((p) => p.keywords).toList();
    final counts = <String, int>{};
    for (var k in keywords) {
      counts[k] = (counts[k] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sorted.take(12).map((entry) {
        final isPopular = entry.value > 1;
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
              fontWeight: isPopular ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.forest900.withValues(alpha: 0.05),
          side: BorderSide(
            color: isPopular
                ? AppColors.gold500.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSentimentPostCard(
    SentimentPost post,
    int index,
    bool isDark,
  ) {
    final isSaved = _savedPostIds.contains(post.id);
    final isSparked = _sparkedPostIds.contains(post.id);

    Color categoryColor;
    IconData categoryIcon;

    switch (post.sentimentCategory) {
      case 'positive':
        categoryColor = AppColors.semanticGreen;
        categoryIcon = Icons.sentiment_satisfied_alt_rounded;
        break;
      case 'negative':
        categoryColor = AppColors.semanticRed;
        categoryIcon = Icons.sentiment_dissatisfied_rounded;
        break;
      case 'neutral':
      default:
        categoryColor = AppColors.gold500;
        categoryIcon = Icons.sentiment_neutral_rounded;
        break;
    }

    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: BrandCard(
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categoryIcon, color: categoryColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.sentimentCategory.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: categoryColor,
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
                    color: isDark
                        ? Colors.white38
                        : AppColors.forest900.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.originalText,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (post.filipinoTranslation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Filipino: ${post.filipinoTranslation}',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (post.englishTranslation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'English: ${post.englishTranslation}',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
            if (post.keywords.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: post.keywords
                    .map(
                      (k) => InkWell(
                        onTap: () => context.push('/dictionary?q=${Uri.encodeComponent(k)}'),
                        child: Text(
                          '#$k',
                          style: TextStyle(
                            color: AppColors.gold500.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                // Learn this word / dictionary link
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                // Spark / Appreciate
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (isSparked) {
                        _sparkedPostIds.remove(post.id);
                      } else {
                        _sparkedPostIds.add(post.id);
                      }
                    });
                  },
                  icon: Icon(
                    isSparked
                        ? Icons.bolt_rounded
                        : Icons.bolt_outlined,
                    color: isSparked ? AppColors.gold500 : Colors.white38,
                    size: 20,
                  ),
                  tooltip: 'Spark',
                ),
                // Save
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (isSaved) {
                        _savedPostIds.remove(post.id);
                      } else {
                        _savedPostIds.add(post.id);
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSaved ? 'Post removed from saved' : 'Post saved to profile 🌿',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isSaved ? AppColors.gold500 : Colors.white38,
                    size: 20,
                  ),
                  tooltip: 'Save',
                ),
                // Share
                IconButton(
                  onPressed: () {
                    final shareText =
                        '${post.originalText}\n${post.englishTranslation.isNotEmpty ? "(${post.englishTranslation})" : ""}\n\nVia LUMAD Lingua';
                    SharePlus.instance.share(ShareParams(text: shareText));
                  },
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Colors.white38,
                    size: 18,
                  ),
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Awaiting Validated Dataset',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No community sentiment posts found yet. Community sentiment analysis entries will appear here once connected. 🌿',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.3),
                fontSize: 12,
                height: 1.4,
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
        color: AppColors.gold500.withValues(alpha: 0.6),
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }

  Widget _buildDashboardSkeleton(bool isDark) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        _buildSliverAppBar(isDark),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const AppShimmerSkeleton(height: 150, borderRadius: 32),
                const SizedBox(height: 28),
                const AppShimmerSkeleton(width: 160, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    3,
                    (i) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: AppShimmerSkeleton(height: 90, borderRadius: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const AppShimmerSkeleton(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                const AppShimmerSkeleton(height: 50, borderRadius: 20),
                const SizedBox(height: 28),
                const AppShimmerSkeleton(width: 200, height: 14, borderRadius: 4),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: AppShimmerSkeleton(height: 160, borderRadius: 24),
              ),
              childCount: 2,
            ),
          ),
        ),
      ],
    );
  }
}
