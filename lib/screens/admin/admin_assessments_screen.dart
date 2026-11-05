import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/firebase_service.dart';
import '../../models/assessment.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/branded_empty_state.dart';
import '../../widgets/admin/admin_screen_header.dart';
import '../../utils/app_localization.dart';

class AdminAssessmentsScreen extends ConsumerWidget {
  const AdminAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              AdminScreenHeader(
                title: l10n.translate('effectiveness_assessments'),
                subtitle: 'Pre vs post-test evaluations and learner satisfaction analytics',
                eyebrow: 'EFFECTIVENESS & ANALYTICS',
              ),
              Expanded(
                child: assessmentsAsync.when(
                  data: (data) => data.isEmpty
                      ? BrandedEmptyState.empty(
                          title: l10n.translate('no_assessments_title'),
                          message: l10n.translate('no_assessments_message'),
                          advice: 'Completed pronunciation and dialect assessments will appear here.',
                          imagePath: 'assets/images/lumad_character (1).png',
                          icon: Icons.assignment_turned_in_rounded,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildAnalyticsDashboard(data, isDark, l10n),
                            const SizedBox(height: 24),
                            Text(
                              'INDIVIDUAL ASSESSMENT LOGS',
                              style: AppTypography.label.copyWith(
                                color: AppColors.gold500,
                                letterSpacing: 1.5,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              data.length,
                              (index) => _buildAssessmentCard(data[index], isDark, index, l10n),
                            ),
                          ],
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                  error: (e, _) => BrandedEmptyState.error(
                    error: e.toString(),
                    advice: 'Unable to load assessment records. Tap retry to reconnect.',
                    onRetry: () => ref.invalidate(assessmentResultsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsDashboard(List<AssessmentResult> data, bool isDark, AppLocalization l10n) {
    final int preCount = data.where((a) => a.type == AssessmentType.preTest).length;
    final int postCount = data.where((a) => a.type == AssessmentType.postTest).length;

    final List<int> ratedScores = data
        .where((a) => a.ratingScore != null)
        .map((a) => a.ratingScore!)
        .toList();

    final double avgRating = ratedScores.isEmpty
        ? 0.0
        : ratedScores.reduce((a, b) => a + b) / ratedScores.length;

    final Map<int, int> starDist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final score in ratedScores) {
      if (score >= 1 && score <= 5) {
        starDist[score] = (starDist[score] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Summary Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'SUBMISSIONS',
                value: '${data.length}',
                subtitle: '$preCount Pre / $postCount Post',
                icon: Icons.assignment_turned_in_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'AVG SATISFACTION',
                value: avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ★' : 'N/A',
                subtitle: '${ratedScores.length} Ratings Given',
                icon: Icons.star_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pre vs Post Bar Chart & Star Distribution in Brand Card
        BrandCard(
          theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRE-TEST VS POST-TEST COMPARISON',
                style: AppTypography.label.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.forest900,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (data.length.toDouble() + 2).clamp(5, 100),
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Pre-Test', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest900, fontSize: 11, fontWeight: FontWeight.bold)),
                                );
                              case 1:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Post-Test', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest900, fontSize: 11, fontWeight: FontWeight.bold)),
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: preCount.toDouble(),
                            color: AppColors.semanticBlue,
                            width: 28,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: postCount.toDouble(),
                            color: AppColors.gold500,
                            width: 28,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text(
                'SATISFACTION RATING BREAKDOWN',
                style: AppTypography.label.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.forest900,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ...[5, 4, 3, 2, 1].map((star) {
                final count = starDist[star] ?? 0;
                final pct = ratedScores.isEmpty ? 0.0 : count / ratedScores.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(
                          '$star ★',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.forest900,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white10 : AppColors.forest900.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              star >= 4 ? AppColors.semanticGreen : (star == 3 ? AppColors.gold500 : AppColors.semanticRed),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold500, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(AssessmentResult assessment, bool isDark, int index, AppLocalization l10n) {
    const cardTextColor = AppColors.forest900;
    final cardSubColor = AppColors.forest700.withValues(alpha: 0.8);
    final cardLabelColor = AppColors.forest900.withValues(alpha: 0.5);

    return BrandCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      theme: assessment.type == AssessmentType.preTest ? BrandCardTheme.cream : BrandCardTheme.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forest900.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment.type == AssessmentType.preTest ? l10n.translate('pre_test') : l10n.translate('post_test'),
                  style: AppTypography.label.copyWith(
                    color: assessment.type == AssessmentType.preTest ? AppColors.semanticBlue : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(assessment.timestamp),
                style: AppTypography.label.copyWith(color: cardLabelColor, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.translate('user_id')}: ${assessment.userId}',
            style: AppTypography.mono.copyWith(fontSize: 10, color: cardSubColor),
          ),
          if (assessment.lessonTitle != null || assessment.lessonId != null)
            Text(
              '${l10n.translate('lesson')}: ${assessment.lessonTitle ?? assessment.lessonId}',
              style: AppTypography.body.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: cardTextColor),
            ),
          if (assessment.ratingScore != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < assessment.ratingScore!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.gold500,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('stars_count', params: {'count': '${assessment.ratingScore}'}),
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cardTextColor,
                  ),
                ),
              ],
            ),
          ],
          if (assessment.openTextFeedback != null &&
              assessment.openTextFeedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.forest900.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${assessment.openTextFeedback}"',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: cardTextColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: AppColors.forest900.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          ...assessment.answers.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: AppTypography.label.copyWith(color: cardLabelColor, fontSize: 8),
                    ),
                    Text(
                      entry.value.toString(),
                      style: AppTypography.body.copyWith(color: cardTextColor, fontSize: 13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}
