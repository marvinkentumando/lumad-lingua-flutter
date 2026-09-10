import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import '../services/sentiment_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';

class SentimentDashboardScreen extends ConsumerStatefulWidget {
  const SentimentDashboardScreen({super.key});

  @override
  ConsumerState<SentimentDashboardScreen> createState() => _SentimentDashboardScreenState();
}

class _SentimentDashboardScreenState extends ConsumerState<SentimentDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentimentAsync = ref.watch(recentSentimentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          bottom: false,
          child: sentimentAsync.when(
            data: (data) => _buildMainContent(data, isDark),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
            error: (e, _) => Center(child: Text('Monitor Error: $e', style: TextStyle(color: isDark ? Colors.white : AppColors.forest900))),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<SentimentData> data, bool isDark) {
    // Calculate aggregate vitality
    final avgScore = data.isEmpty ? 0.0 : data.fold(0.0, (sum, item) => sum + item.sentimentScore) / data.length;
    final vitalityPercent = (avgScore + 1) / 2; // Map -1..1 to 0..1

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
                _buildVitalityGauge(vitalityPercent, avgScore, true),
                const SizedBox(height: 32),
                _buildInsightGrid(data, isDark),
                const SizedBox(height: 32),
                _buildKeywordCloud(data, isDark),
                const SizedBox(height: 32),
                _buildSectionHeader('Live Sentiment Stream', isDark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSentimentCard(data[index], index, true)
                  .animate(delay: (100 * index).ms)
                  .fadeIn()
                  .slideX(begin: 0.1),
              childCount: data.length,
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
        onPressed: () => context.pop(),
      ),
      expandedHeight: 120,
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.semanticGreen,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ).then().fadeOut(),
                const SizedBox(width: 8),
                Text(
                  'VITALITY MONITOR',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            Text(
              'Mansaka Digital Pulse',
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

  Widget _buildVitalityGauge(double percent, double score, bool isDark) {
    final status = score > 0.4 ? 'Vibrant' : (score > 0 ? 'Healthy' : 'At Risk');
    final statusColor = score > 0.4 ? AppColors.semanticGreen : (score > 0 ? AppColors.gold500 : AppColors.semanticRed);

    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State',
                    style: AppTypography.label.copyWith(color: Colors.white60),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: AppTypography.h1ExtraBold.copyWith(
                      color: statusColor,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on keywords & usage patterns analyzed from the last 24h.',
                    style: AppTypography.body.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 12,
                    backgroundColor: Colors.white10,
                    color: statusColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percent * 100).toInt()}',
                      style: AppTypography.h2.copyWith(color: Colors.white),
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
      ),
    );
  }

  Widget _buildInsightGrid(List<SentimentData> data, bool isDark) {
    final positiveCount = data.where((d) => d.sentimentScore > 0).length;
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard(
            'Positive Content',
            '${(positiveCount / data.length * 100).toInt()}%',
            Icons.trending_up_rounded,
            AppColors.semanticGreen,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStatCard(
            'Daily Reach',
            '${data.length * 24} users',
            Icons.people_alt_rounded,
            AppColors.gold500,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String val, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            val,
            style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordCloud(List<SentimentData> data, bool isDark) {
    final keywords = data.expand((d) => d.detectedKeywords).toList();
    final counts = <String, int>{};
    for (var k in keywords) {
      counts[k] = (counts[k] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Dominant Keywords', isDark),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sorted.take(10).map((entry) {
            final isPopular = entry.value > 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPopular ? AppColors.gold500 : (isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(30),
                boxShadow: isPopular ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
              child: Text(
                entry.key,
                style: AppTypography.body.copyWith(
                  color: isPopular ? Colors.black : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7)),
                  fontWeight: isPopular ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSentimentCard(SentimentData data, int index, bool isDark) {
    final isPositive = data.sentimentScore > 0;
    final timeAgo = _getTimeAgo(data.timestamp);

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
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF1877F2), // Facebook Blue
                      child: Icon(Icons.facebook, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Social Post • $timeAgo',
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.semanticGreen : AppColors.semanticRed).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.sentiment_satisfied_alt : Icons.sentiment_dissatisfied,
                        color: isPositive ? AppColors.semanticGreen : AppColors.semanticRed,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(data.sentimentScore * 100).toInt()}',
                        style: TextStyle(
                          color: isPositive ? AppColors.semanticGreen : AppColors.semanticRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.postText,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: data.detectedKeywords.map((k) => Text(
                '#$k',
                style: TextStyle(
                  color: AppColors.gold500.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )).toList(),
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
        color: AppColors.gold500.withValues(alpha: 0.5),
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
