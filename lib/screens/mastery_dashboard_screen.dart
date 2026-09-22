import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/srs_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import 'package:lumad_lingua/widgets/app_shimmer_skeleton.dart';

class MasteryDashboardScreen extends ConsumerWidget {
  const MasteryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(srsStatsProvider);

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: statsAsync.when(
                  data: (stats) => _buildContent(context, stats),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.forest900;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Mastery Trends',
            style: AppTypography.h2ExtraBold.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SRSStats stats) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildOverallMasteryCard(stats.overallMastery),
        const SizedBox(height: 32),
        _buildMasteryBreakdown(context, stats.counts),
        const SizedBox(height: 32),
        _buildWeeklyTrend(context, stats.weeklyProgress),
        const SizedBox(height: 32),
        _buildReviewAction(context),
      ],
    );
  }

  Widget _buildOverallMasteryCard(double mastery) {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL MASTERY',
                    style: AppTypography.label.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${(mastery * 100).toStringAsFixed(0)}%',
                    style: AppTypography.displayBold.copyWith(
                      color: Colors.black,
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: mastery,
            backgroundColor: Colors.black.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildMasteryBreakdown(BuildContext context, Map<MasteryLevel, int> counts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VOCABULARY STATUS',
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBreakdownItem(
                context,
                'NEW',
                counts[MasteryLevel.newWord]!,
                AppColors.semanticBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownItem(
                context,
                'LEARNING',
                counts[MasteryLevel.learning]!,
                AppColors.gold500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownItem(
                context,
                'MASTERED',
                counts[MasteryLevel.mastered]!,
                AppColors.semanticGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(BuildContext context, String label, int count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTypography.h1ExtraBold.copyWith(
              color: isDark ? color : AppColors.forest900,
              fontSize: 24,
            ),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, List<double> progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY PROGRESS',
            style: AppTypography.label.copyWith(
              color: isDark ? AppColors.gold500 : AppColors.forest900.withValues(alpha: 0.5),
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: progress.map((val) {
                return Container(
                  width: 30,
                  height: (val / 12) * 100, // Normalized to max 12
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? AppColors.gold500 : AppColors.forest900,
                        (isDark ? AppColors.gold500 : AppColors.forest900).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).animate().scaleY(
                  begin: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewAction(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userId = ref.watch(authServiceProvider).currentUser?.uid;
        if (userId == null) return const SizedBox.shrink();

        final dueCountAsync = ref.watch(dueSRSCountProvider(userId));

        return dueCountAsync.when(
          data: (count) {
            final hasDue = count > 0;
            return GestureDetector(
              onTap: hasDue
                  ? () => context.push('/flashcards?mode=review')
                  : null,
              child: BrandCard(
                theme: hasDue ? BrandCardTheme.vibrant : BrandCardTheme.cream,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      hasDue ? Icons.alarm_on_rounded : Icons.check_circle_outline_rounded,
                      color: hasDue ? AppColors.gold500 : AppColors.semanticGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasDue ? '$count Words Ready for Review' : 'All Caught Up!',
                            style: AppTypography.h3.copyWith(
                              color: hasDue ? Colors.white : AppColors.forest900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            hasDue ? 'Keep your streak alive!' : 'Come back later for more reviews.',
                            style: AppTypography.body.copyWith(
                              color: hasDue ? Colors.white60 : AppColors.forest700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasDue)
                      const Icon(Icons.chevron_right_rounded, color: AppColors.gold500),
                  ],
                ),
              ),
            ).animate(target: hasDue ? 1 : 0).shimmer(duration: 2.seconds);
          },
          loading: () => AppShimmerSkeleton(height: 80, borderRadius: 24),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}



