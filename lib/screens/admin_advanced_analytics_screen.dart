import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_box.dart';
import '../widgets/brand_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminAdvancedAnalyticsScreen extends ConsumerWidget {
  const AdminAdvancedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(advancedAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.forest900,
      appBar: AppBar(
        title: Text('PEDAGOGICAL ANALYTICS', style: AppTypography.h3.copyWith(color: AppColors.gold500)),
        backgroundColor: AppColors.forest900,
      ),
      body: analyticsAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('LESSON HEATMAPS (Struggle Points)'),
              const SizedBox(height: 16),
              _buildLessonHeatmaps(data['lessonStruggles'], data['lessonNames']),
              
              const SizedBox(height: 32),
              _sectionLabel('DIALECT POPULARITY (Active Learners)'),
              const SizedBox(height: 16),
              _buildDialectPopularity(data['dialectPopularity']),
              
              const SizedBox(height: 32),
              _sectionLabel('SRS ECOSYSTEM HEALTH'),
              const SizedBox(height: 16),
              _buildSRSHealth(data['srsHealth']),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: AppTypography.mono.copyWith(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
  );

  Widget _buildLessonHeatmaps(Map<String, dynamic> struggles, Map<String, dynamic> names) {
    if (struggles.isEmpty) return _emptyState('No student attempts recorded yet.');

    final sortedLessons = struggles.entries.toList()
      ..sort((a, b) {
        final sumA = (a.value as Map).values.fold(0, (prev, curr) => prev + (curr as int));
        final sumB = (b.value as Map).values.fold(0, (prev, curr) => prev + (curr as int));
        return sumB.compareTo(sumA);
      });

    return Column(
      children: sortedLessons.take(5).map((entry) {
        final lessonId = entry.key;
        final taskStruggles = entry.value as Map<String, int>;
        final lessonName = names[lessonId] ?? 'Unknown Lesson';
        
        return BrandCard(
          theme: BrandCardTheme.vibrant,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lessonName, style: AppTypography.h3.copyWith(color: AppColors.gold500, fontSize: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: taskStruggles.entries.map((ts) {
                    final intensity = (ts.value / 20).clamp(0.1, 1.0);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: intensity),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        'Task ${ts.key.split('_').last}: ${ts.value} fails',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialectPopularity(Map<String, dynamic> popularity) {
    if (popularity.isEmpty) return _emptyState('No dialect data available.');

    return BrandCard(
      theme: BrandCardTheme.cream,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: popularity.entries.map((e) {
            final dialect = e.key;
            final count = e.value as int;
            final max = popularity.values.fold(0, (p, c) => (c as int) > p ? c : p);
            final pct = max > 0 ? count / max : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dialect.toUpperCase(), style: AppTypography.label.copyWith(color: AppColors.forest900)),
                      Text('$count learners', style: AppTypography.mono.copyWith(color: AppColors.forest700, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(height: 6, decoration: BoxDecoration(color: AppColors.forest900.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3))),
                      AnimatedContainer(
                        duration: 1.seconds,
                        height: 6,
                        width: 250 * pct,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.forest700, AppColors.forest500]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSRSHealth(Map<String, dynamic> health) {
    final rate = (health['retentionRate'] as double) * 100;
    final dist = health['masteryDistribution'] as Map<int, int>;
    final total = health['totalCards'] as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Retention Rate',
                '${rate.toStringAsFixed(1)}%',
                rate > 85 ? AppColors.semanticGreen : AppColors.gold500,
                Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Total Cards',
                total.toString(),
                AppColors.semanticBlue,
                Icons.layers_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BrandCard(
          theme: BrandCardTheme.vibrant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mastery Distribution', style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: dist.entries.map((e) {
                    final h = total > 0 ? (e.value / total * 100).clamp(5.0, 100.0) : 5.0;
                    return Column(
                      children: [
                        Text('${e.value}', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                        const SizedBox(height: 4),
                        Container(
                          width: 20,
                          height: h,
                          decoration: BoxDecoration(
                            color: _getLevelColor(e.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('L${e.key}', style: const TextStyle(color: Colors.white24, fontSize: 8)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return GlassBox(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.display.copyWith(color: Colors.white, fontSize: 24)),
            Text(label.toUpperCase(), style: AppTypography.label.copyWith(color: Colors.white24, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level == 0) return Colors.grey;
    if (level < 3) return AppColors.semanticRed;
    if (level < 5) return AppColors.gold500;
    return AppColors.semanticGreen;
  }

  Widget _emptyState(String message) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(child: Text(message, style: const TextStyle(color: Colors.white38))),
  );
}
