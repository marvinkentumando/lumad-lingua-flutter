import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/brand_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_localization.dart';

class AdminAdvancedAnalyticsScreen extends ConsumerWidget {
  const AdminAdvancedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(advancedAnalyticsProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.translate('pedagogical_analytics'),
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : AppColors.forest900,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
          onPressed: () => context.pop(),
        ),
      ),
      body: BrandBackground(
        child: analyticsAsync.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              HapticService.light();
              ref.invalidate(advancedAnalyticsProvider);
            },
            color: isDark ? AppColors.gold500 : AppColors.forest500,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(context, l10n.translate('learning_eco_health')),
                  const SizedBox(height: 16),
                  _buildSystemMetrics(context, data['srsHealth'] as Map<String, dynamic>? ?? {}, l10n),
                  
                  const SizedBox(height: 40),
                  _sectionLabel(context, l10n.translate('xp_growth_trends')),
                  const SizedBox(height: 16),
                  _buildXPTrendsChart(context, data['xpTrends'] as Map<String, dynamic>? ?? {}, l10n),

                  const SizedBox(height: 40),
                  _sectionLabel(context, l10n.translate('pronunciation_by_dialect')),
                  const SizedBox(height: 16),
                  _buildAccuracyBreakdown(context, data['dialectAccuracy'] as Map<String, dynamic>? ?? {}, l10n),

                  const SizedBox(height: 40),
                  _sectionLabel(context, l10n.translate('pronunciation_by_location')),
                  const SizedBox(height: 16),
                  _buildAccuracyBreakdown(context, data['locationAccuracy'] as Map<String, dynamic>? ?? {}, l10n),

                  const SizedBox(height: 40),
                  _sectionLabel(context, l10n.translate('lesson_heatmaps')),
                  const SizedBox(height: 16),
                  _buildLessonHeatmaps(
                    context,
                    data['lessonStruggles'] as Map<String, dynamic>? ?? {},
                    data['lessonNames'] as Map<String, dynamic>? ?? {},
                    l10n,
                  ),
                  
                  const SizedBox(height: 40),
                  _sectionLabel(context, l10n.translate('srs_mastery_title')),
                  const SizedBox(height: 16),
                  _buildSRSMasteryChart(context, data['srsHealth'] as Map<String, dynamic>? ?? {}, l10n),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.semanticRed, size: 48),
                const SizedBox(height: 16),
                Text(l10n.translate('failed_sync_wisdom', params: {'error': e.toString()}), style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7))),
                TextButton(
                  onPressed: () {
                    HapticService.selection();
                    ref.invalidate(advancedAnalyticsProvider);
                  },
                  child: Text(l10n.translate('retry_sync')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: AppTypography.label.copyWith(
        color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.forest900.withValues(alpha: 0.5),
        letterSpacing: 2,
        fontWeight: FontWeight.w900,
        fontSize: 10,
      ),
    );
  }

  Widget _buildSystemMetrics(BuildContext context, Map<String, dynamic> health, AppLocalization l10n) {
    final rate = (health['retentionRate'] as num? ?? 0.0).toDouble() * 100;
    final total = (health['totalCards'] as num? ?? 0).toInt();

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            l10n.translate('retention_rate'),
            '${rate.toStringAsFixed(1)}%',
            rate > 85 ? AppColors.semanticGreen : AppColors.gold500,
            Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            context,
            l10n.translate('active_terms'),
            total.toString(),
            AppColors.semanticBlue,
            Icons.menu_book_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildXPTrendsChart(BuildContext context, Map<String, dynamic> trends, AppLocalization l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = trends.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return _emptyState(l10n.translate('no_xp_activity'), l10n);

    final maxXP = entries.map((e) => (e.value as num).toInt()).reduce((a, b) => a > b ? a : b);
    final displayMax = maxXP == 0 ? 100 : maxXP;

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('aggregate_xp_growth').toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                Text(
                  '+$maxXP Peak',
                  style: AppTypography.mono.copyWith(color: AppColors.gold500, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: entries.map((e) {
                  final xpValue = (e.value as num).toInt();
                  final hPct = xpValue / displayMax;
                  final dayLabel = e.key.split('-').last;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: (hPct * 80).clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: AppColors.gold500,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              if (xpValue == maxXP && xpValue > 0)
                                BoxShadow(
                                  color: AppColors.gold500.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ).animate().scaleY(begin: 0, duration: 600.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 8),
                        Text(
                          dayLabel,
                          style: AppTypography.mono.copyWith(
                            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyBreakdown(BuildContext context, Map<String, dynamic> data, AppLocalization l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) return _emptyState(l10n.translate('insufficient_voice_data'), l10n);

    final sorted = data.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Column(
      children: sorted.take(5).map((entry) {
        final accuracy = (entry.value as num).toDouble();
        final label = entry.key;

        return BrandCard(
          theme: BrandCardTheme.cream,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label.substring(0, 1).toUpperCase(),
                      style: AppTypography.h3.copyWith(color: AppColors.gold500, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white : AppColors.forest900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: accuracy,
                          minHeight: 4,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(
                            accuracy > 0.8 ? AppColors.semanticGreen : (accuracy > 0.6 ? AppColors.gold500 : AppColors.semanticRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(accuracy * 100).toInt()}%',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ACCURACY',
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonHeatmaps(BuildContext context, Map<String, dynamic> struggles, Map<String, dynamic> names, AppLocalization l10n) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (struggles.isEmpty) return _emptyState(l10n.translate('student_stumbles_empty'), l10n);

    final sortedLessons = struggles.entries.toList()
      ..sort((a, b) {
        final sumA = (a.value as Map).values.fold(0, (prev, curr) => prev + (curr as num).toInt());
        final sumB = (b.value as Map).values.fold(0, (prev, curr) => prev + (curr as num).toInt());
        return sumB.compareTo(sumA);
      });

    return Column(
      children: sortedLessons.take(5).map((entry) {
        final lessonId = entry.key;
        final taskStruggles = Map<String, int>.from(entry.value as Map);
        final lessonName = names[lessonId] ?? l10n.translate('ancestral_lesson_default');
        final maxStumble = taskStruggles.values.isEmpty ? 1 : taskStruggles.values.reduce((a, b) => a > b ? a : b);
        
        return BrandCard(
          theme: BrandCardTheme.vibrant,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lessonName, 
                        style: AppTypography.h3.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.gold700, 
                          fontSize: 14
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.semanticRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CRITICAL',
                        style: AppTypography.label.copyWith(color: AppColors.semanticRed, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Heatmap Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: taskStruggles.entries.map((ts) {
                    final intensity = ts.value / maxStumble;
                    return Tooltip(
                      message: 'Task ${ts.key}: ${ts.value} slips',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            AppColors.semanticRed,
                            intensity,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: intensity > 0.7 ? AppColors.semanticRed.withValues(alpha: 0.5) : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            ts.key.split('_').last.substring(0, min(2, ts.key.split('_').last.length)),
                            style: TextStyle(
                              color: intensity > 0.5 ? Colors.white : (isDark ? Colors.white60 : Colors.black38),
                              fontSize: 10,
                              fontWeight: intensity > 0.5 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color intensity represents frequency of learner slips.',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSRSMasteryChart(BuildContext context, Map<String, dynamic> health, AppLocalization l10n) {
    final dist = Map<int, int>.from(health['masteryDistribution'] as Map? ?? {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0});
    final maxDist = dist.values.isEmpty ? 1 : dist.values.reduce((a, b) => a > b ? a : b);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('mastery_box_dist'), 
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900, 
                fontSize: 14
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dist.entries.map((e) {
                  final h = maxDist > 0 ? (e.value / maxDist * 100).clamp(10.0, 100.0) : 10.0;
                  final isPeak = e.value == maxDist && e.value > 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${e.value}', 
                        style: AppTypography.mono.copyWith(
                          color: isPeak 
                              ? (isDark ? AppColors.gold500 : AppColors.gold900) 
                              : (isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5)), 
                          fontSize: 9,
                          fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        width: 28,
                        height: h,
                        decoration: BoxDecoration(
                          color: _getLevelColor(e.key, isDark),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          boxShadow: [
                            if (isPeak)
                              BoxShadow(
                                color: _getLevelColor(e.key, isDark).withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.translate('box_label')} ${e.key}', 
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3), 
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, Color color, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? color : AppColors.gold900, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value, 
              style: AppTypography.display.copyWith(
                color: isDark ? Colors.white : AppColors.forest900, 
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label.toUpperCase(), 
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white60 : AppColors.forest900.withValues(alpha: 0.5),
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level, bool isDark) {
    if (level == 0) return isDark ? Colors.white10 : Colors.black12;
    if (level < 3) return AppColors.semanticRed;
    if (level < 5) return AppColors.gold500;
    return AppColors.semanticGreen;
  }

  Widget _emptyState(String message, AppLocalization l10n) => BrandedEmptyState(
    title: 'Trail is Fresh',
    message: message,
    icon: Icons.analytics_outlined,
  );
}
