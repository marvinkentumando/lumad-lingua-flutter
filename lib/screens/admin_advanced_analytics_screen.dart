import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_box.dart';
import '../widgets/brand_card.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/brand_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminAdvancedAnalyticsScreen extends ConsumerWidget {
  const AdminAdvancedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(advancedAnalyticsProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'PEDAGOGICAL ANALYTICS',
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
          onPressed: () => Navigator.pop(context),
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
                  _sectionLabel(context, 'LEARNING ECOSYSTEM HEALTH'),
                  const SizedBox(height: 16),
                  _buildSystemMetrics(data['srsHealth'] as Map<String, dynamic>? ?? {}),
                  
                  const SizedBox(height: 40),
                  _sectionLabel(context, 'LESSON HEATMAPS (STUMBLE POINTS)'),
                  const SizedBox(height: 16),
                  _buildLessonHeatmaps(
                    context,
                    data['lessonStruggles'] as Map<String, dynamic>? ?? {},
                    data['lessonNames'] as Map<String, dynamic>? ?? {},
                  ),
                  
                  const SizedBox(height: 40),
                  _sectionLabel(context, 'SPACED REPETITION (SRS) MASTERY'),
                  const SizedBox(height: 16),
                  _buildSRSMasteryChart(context, data['srsHealth'] as Map<String, dynamic>? ?? {}),
                  
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
                Text('Failed to sync wisdom: $e', style: TextStyle(color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7))),
                TextButton(
                  onPressed: () {
                    HapticService.selection();
                    ref.invalidate(advancedAnalyticsProvider);
                  },
                  child: const Text('RETRY SYNC'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Text(
    label,
    style: AppTypography.label.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      letterSpacing: 2,
      fontWeight: FontWeight.w900,
      fontSize: 10,
    ),
  );

  Widget _buildSystemMetrics(Map<String, dynamic> health) {
    final rate = (health['retentionRate'] as num? ?? 0.0).toDouble() * 100;
    final total = (health['totalCards'] as num? ?? 0).toInt();

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Retention Rate',
            '${rate.toStringAsFixed(1)}%',
            rate > 85 ? AppColors.semanticGreen : AppColors.gold500,
            Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            'Active Terms',
            total.toString(),
            AppColors.semanticBlue,
            Icons.menu_book_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonHeatmaps(BuildContext context, Map<String, dynamic> struggles, Map<String, dynamic> names) {
    if (struggles.isEmpty) return _emptyState('The trail is fresh. No student stumbles recorded yet.');

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
        final lessonName = names[lessonId] ?? 'Ancestral Lesson';
        
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
                        style: AppTypography.h3.copyWith(color: AppColors.gold500, fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                ...taskStruggles.entries.map((ts) {
                  // Percentage of struggle compared to top stumble
                  final maxStumble = taskStruggles.values.reduce((a, b) => a > b ? a : b);
                  final pct = maxStumble > 0 ? ts.value / maxStumble : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Task ${ts.key.split('_').last}', 
                              style: AppTypography.label.copyWith(color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              '${ts.value} slips', 
                              style: AppTypography.mono.copyWith(color: AppColors.semanticRed, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation(
                              Color.lerp(AppColors.gold500, AppColors.semanticRed, pct),
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
        );
      }).toList(),
    );
  }

  Widget _buildSRSMasteryChart(BuildContext context, Map<String, dynamic> health) {
    final dist = Map<int, int>.from(health['masteryDistribution'] as Map? ?? {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0});
    final maxDist = dist.values.isEmpty ? 1 : dist.values.reduce((a, b) => a > b ? a : b);

    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mastery Box Distribution', 
              style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 14),
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
                          color: isPeak ? AppColors.gold500 : Colors.white60, 
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
                          color: _getLevelColor(e.key),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          boxShadow: [
                            if (isPeak)
                              BoxShadow(
                                color: _getLevelColor(e.key).withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BOX ${e.key}', 
                        style: AppTypography.label.copyWith(
                          color: Colors.white24, 
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

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return GlassBox(
      borderRadius: 24,
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value, 
              style: AppTypography.display.copyWith(
                color: Colors.white, 
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label.toUpperCase(), 
              style: AppTypography.label.copyWith(
                color: Colors.white38, 
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level == 0) return Colors.white10;
    if (level < 3) return AppColors.semanticRed;
    if (level < 5) return AppColors.gold500;
    return AppColors.semanticGreen;
  }

  Widget _emptyState(String message) => BrandedEmptyState(
    title: 'Trail is Fresh',
    message: message,
    icon: Icons.analytics_outlined,
  );
}
