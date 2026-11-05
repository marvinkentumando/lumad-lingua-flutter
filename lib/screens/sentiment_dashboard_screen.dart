import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:lumad_lingua/models/sentiment_post.dart';
import 'package:lumad_lingua/services/sentiment_service.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import '../services/haptic_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/app_shimmer_skeleton.dart';
import '../providers/role_provider.dart';
import 'learner_sentiment_screen.dart';

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

  void _showImportJsonModal() {
    final textController = TextEditingController();
    bool isImporting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isDark = Theme.of(modalContext).brightness == Brightness.dark;

            Future<int> processAndSaveJson(String jsonStr) async {
              final decoded = jsonDecode(jsonStr);
              List<Map<String, dynamic>> rawList = [];
              if (decoded is List) {
                rawList = decoded.cast<Map<String, dynamic>>();
              } else if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
                rawList = (decoded['data'] as List).cast<Map<String, dynamic>>();
              } else {
                throw const FormatException('Expected a JSON array of sentiment objects.');
              }

              if (rawList.isEmpty) {
                throw const FormatException('The JSON array contains no sentiment records.');
              }

              await ref.read(sentimentServiceProvider).saveCustomSentimentPosts(rawList);
              ref.invalidate(communitySentimentPostsProvider);
              return rawList.length;
            }

          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? AppColors.forest800 : AppColors.creamBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Import Sentiment Dataset',
                        style: AppTypography.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pick a .json file or paste your sentiment JSON array below.',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isImporting
                              ? null
                              : () async {
                                  final result = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['json'],
                                    withData: true,
                                  );
                                  if (result != null && result.files.single.bytes != null) {
                                    final str = utf8.decode(result.files.single.bytes!);
                                    textController.text = str;
                                  } else if (result != null && result.files.single.path != null) {
                                    final file = await File(result.files.single.path!).readAsString();
                                    textController.text = file;
                                  }
                                },
                          icon: const Icon(Icons.file_open_rounded, size: 18),
                          label: const Text('Pick JSON File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold500,
                            side: const BorderSide(color: AppColors.gold500),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: '[\n  {\n    "id": "post_1",\n    "originalText": "Madyaw...",\n    "sentimentCategory": "positive"\n  }\n]',
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: BrandButton(
                      text: isImporting ? 'IMPORTING...' : 'IMPORT DATASET',
                      type: BrandButtonType.primary,
                      onTap: isImporting
                          ? null
                          : () async {
                              if (textController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  const SnackBar(content: Text('Please select or paste JSON data.')),
                                );
                                return;
                              }
                              setModalState(() => isImporting = true);
                              try {
                                final count = await processAndSaveJson(textController.text.trim());
                                if (!mounted) return;
                                HapticService.success();
                                if (modalContext.mounted) {
                                  Navigator.of(modalContext).pop();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Successfully imported $count sentiment records! 🌿'),
                                    backgroundColor: AppColors.semanticGreen,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                HapticService.error();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to parse JSON: $e'),
                                    backgroundColor: AppColors.semanticRed,
                                  ),
                                );
                              } finally {
                                if (modalContext.mounted) setModalState(() => isImporting = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final userRoleStr = userProfile?['role']?.toString().toLowerCase();

    final isLearner = currentRole == UserRole.learner &&
        userRoleStr != 'admin' &&
        userRoleStr != 'educator' &&
        userRoleStr != 'staff';

    if (isLearner) {
      return const LearnerSentimentScreen();
    }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Community Sentiment Entries', isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.semanticGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.semanticGreen.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 13,
                            color: AppColors.semanticGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Privacy Protected 🛡️',
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
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_rounded, color: AppColors.gold500),
          tooltip: 'Import JSON Dataset',
          onPressed: _showImportJsonModal,
        ),
        const SizedBox(width: 8),
      ],
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

    final keywords = posts
        .expand((p) => p.redactedKeywords)
        .toList();
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

    final displayText = post.redactedOriginalText;
    final displayFilipino = post.redactedFilipinoTranslation;
    final displayEnglish = post.redactedEnglishTranslation;
    final displayKeywords = post.redactedKeywords;
    final bool isNamesRedacted = post.originalText != post.redactedOriginalText;

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
                  if (isNamesRedacted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.semanticGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.semanticGreen.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shield_rounded, size: 10, color: AppColors.semanticGreen),
                          SizedBox(width: 3),
                          Text(
                            'REDACTED',
                            style: TextStyle(
                              color: AppColors.semanticGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            displayText,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (displayFilipino.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Filipino: $displayFilipino',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.forest700,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (displayEnglish.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'English: $displayEnglish',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
          if (displayKeywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: displayKeywords
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
          Divider(
            color: isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.1),
            height: 1,
          ),
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
                  color: isSparked
                      ? AppColors.gold500
                      : (isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4)),
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
                  color: isSaved
                      ? AppColors.gold500
                      : (isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4)),
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
                icon: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
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
                const AppShimmerSkeleton(height: 200, borderRadius: 24),
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
              (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.forest800.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.forest700.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        AppShimmerSkeleton(
                          width: 24,
                          height: 24,
                          isCircle: true,
                        ),
                        SizedBox(width: 10),
                        AppShimmerSkeleton(
                          width: 120,
                          height: 14,
                          borderRadius: 4,
                        ),
                        Spacer(),
                        AppShimmerSkeleton(
                          width: 60,
                          height: 22,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const AppShimmerSkeleton(
                      height: 16,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 8),
                    const AppShimmerSkeleton(
                      width: 240,
                      height: 14,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        AppShimmerSkeleton(
                          width: 80,
                          height: 20,
                          borderRadius: 10,
                        ),
                        SizedBox(width: 8),
                        AppShimmerSkeleton(
                          width: 60,
                          height: 20,
                          borderRadius: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}
