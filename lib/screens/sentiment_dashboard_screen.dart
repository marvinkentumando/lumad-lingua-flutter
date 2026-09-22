import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import 'package:lumad_lingua/services/sentiment_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/app_shimmer_skeleton.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
    final allModelsAsync = ref.watch(allModelsSentimentProvider);
    final configAsync = ref.watch(appConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          bottom: false,
          child: configAsync.when(
            data: (config) => allModelsAsync.when(
              data: (allData) => _buildMainContent(allData, config.activeSentimentAlgorithm, isDark),
              loading: () => _buildDashboardSkeleton(isDark),
              error: (e, _) => Center(child: Text('Monitor Error: $e', style: TextStyle(color: isDark ? Colors.white : AppColors.forest900))),
            ),
            loading: () => _buildDashboardSkeleton(isDark),
            error: (e, _) => Center(child: Text('Config Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<SentimentModelType, List<SentimentData>> allData, String activeModelName, bool isDark) {
    final activeModel = SentimentModelType.values.firstWhere(
      (e) => e.name == activeModelName,
      orElse: () => SentimentModelType.naiveBayes,
    );
    final data = allData[activeModel] ?? [];
    final bool hasData = data.isNotEmpty;

    // Calculate aggregate vitality
    final avgScore = !hasData ? 0.0 : data.fold(0.0, (sum, item) => sum + item.sentimentScore) / data.length;
    final vitalityPercent = !hasData ? 0.0 : (avgScore + 1) / 2; // Map -1..1 to 0..1

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
                _buildVitalityGauge(vitalityPercent, avgScore, hasData, true),
                const SizedBox(height: 32),
                if (hasData) ...[
                  _buildInsightGrid(data, isDark),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Multi-Model Health Trends', isDark),
                  const SizedBox(height: 16),
                  _buildVitalityChart(allData, isDark),
                  const SizedBox(height: 12),
                  _buildLegend(isDark),
                  const SizedBox(height: 32),
                  _buildKeywordCloud(data, isDark),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Community Analysis Archive (${_getSentimentModelName(activeModel)})', isDark),
                  const SizedBox(height: 16),
                ] else
                  _buildNoDataState(isDark),
              ],
            ),
          ),
        ),
        if (hasData)
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold500,
                  size: 10,
                ),
                const SizedBox(width: 8),
                Text(
                  'COMMUNITY HEALTH MONITOR',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontSize: 8,
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

  Widget _buildVitalityGauge(double percent, double score, bool hasData, bool isDark) {
    final statusColor = !hasData 
        ? Colors.white12 
        : (score > 0.4 ? AppColors.semanticGreen : (score > 0 ? AppColors.gold500 : AppColors.semanticRed));

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
                    'VITALITY SCORE',
                    style: AppTypography.label.copyWith(
                      color: hasData ? statusColor.withValues(alpha: 0.7) : Colors.white24,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall Index',
                    style: AppTypography.h2.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasData 
                      ? 'Aggregated analysis based on internal linguistic models and archived digital footprints.'
                      : 'Linguistic monitoring system active. Awaiting community data retrieval for analysis.',
                    style: AppTypography.body.copyWith(
                      color: Colors.white60,
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
                    value: hasData ? percent : 0,
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
                      hasData ? '${(percent * 100).toInt()}' : '--',
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

  Widget _buildNoDataState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off_rounded,
              size: 48,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              'Awaiting Community Pulse',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No linguistic data entries found for this period.',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.1),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightGrid(List<SentimentData> data, bool isDark) {
    final positiveCount = data.where((d) => d.sentimentScore > 0).length;
    return _buildSmallStatCard(
      'Positive Content Ratio',
      '${(positiveCount / data.length * 100).toInt()}%',
      Icons.trending_up_rounded,
      AppColors.semanticGreen,
      isDark,
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
              color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storage_rounded, color: AppColors.gold500, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Archived Entry • $timeAgo',
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
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

  Widget _buildVitalityChart(Map<SentimentModelType, List<SentimentData>> allData, bool isDark) {
    if (allData.isEmpty) return const SizedBox.shrink();

    // Use Naive Bayes as reference for time axis
    final referenceData = allData[SentimentModelType.naiveBayes] ?? [];
    if (referenceData.isEmpty) return const SizedBox.shrink();
    
    final sortedRef = List<SentimentData>.from(referenceData)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      height: 260,
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.forest900.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.forest900.withValues(alpha: 0.05)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedRef.length) {
                    if (index == 0 || index == sortedRef.length - 1 || index == (sortedRef.length / 2).floor()) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MM/dd').format(sortedRef[index].timestamp),
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 35,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedRef.length - 1).toDouble(),
          minY: -1.1,
          maxY: 1.1,
          lineBarsData: allData.entries.map((entry) {
            final model = entry.key;
            final data = entry.value;
            final sortedModelData = List<SentimentData>.from(data)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            final spots = sortedModelData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sentimentScore)).toList();

            final color = _getModelColor(model);
            
            return LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: model == SentimentModelType.naiveBayes ? 4 : 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: model == SentimentModelType.naiveBayes,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: model == SentimentModelType.naiveBayes,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? AppColors.forest800 : Colors.white,
              tooltipRoundedRadius: 12,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final model = SentimentModelType.values[barSpot.barIndex];
                  return LineTooltipItem(
                    '${_getSentimentModelName(model)}: ${barSpot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: _getModelColor(model),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: SentimentModelType.values.map((model) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getModelColor(model),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _getSentimentModelName(model),
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getModelColor(SentimentModelType type) {
    switch (type) {
      case SentimentModelType.naiveBayes: return AppColors.gold500;
      case SentimentModelType.svm: return AppColors.semanticBlue;
      case SentimentModelType.biLstm: return AppColors.terracotta;
    }
  }

  String _getSentimentModelName(SentimentModelType type) {
    switch (type) {
      case SentimentModelType.naiveBayes: return 'Naïve Bayes';
      case SentimentModelType.svm: return 'SVM';
      case SentimentModelType.biLstm: return 'BiLSTM';
    }
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
                const AppShimmerSkeleton(height: 160, borderRadius: 40),
                const SizedBox(height: 32),
                const AppShimmerSkeleton(height: 90, borderRadius: 24),
                const SizedBox(height: 32),
                const AppShimmerSkeleton(width: 180, height: 14, borderRadius: 4),
                const SizedBox(height: 16),
                const AppShimmerSkeleton(height: 260, borderRadius: 24),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Row(
                        children: [
                          const AppShimmerSkeleton(width: 12, height: 12, isCircle: true),
                          const SizedBox(width: 6),
                          Expanded(child: const AppShimmerSkeleton(height: 10, borderRadius: 2)),
                        ],
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 32),
                const AppShimmerSkeleton(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(6, (i) => AppShimmerSkeleton(
                    width: (60 + (i * 15) % 50).toDouble(),
                    height: 32,
                    borderRadius: 30,
                  )),
                ),
                const SizedBox(height: 32),
                const AppShimmerSkeleton(width: 220, height: 14, borderRadius: 4),
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
                child: AppShimmerSkeleton(height: 140, borderRadius: 24),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}
