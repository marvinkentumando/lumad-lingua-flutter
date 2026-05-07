import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/validator_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../widgets/wotd_widget.dart';
import '../services/firebase_service.dart';

class ValidatorHomeScreen extends ConsumerStatefulWidget {
  const ValidatorHomeScreen({super.key});

  @override
  ConsumerState<ValidatorHomeScreen> createState() =>
      _ValidatorHomeScreenState();
}

class _ValidatorHomeScreenState extends ConsumerState<ValidatorHomeScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final displayName = profile?['username'] ?? 'Elder Validator';
    final currentRank = profile?['rank'] ?? 'Guardian';

    // Live Metrics
    final pendingEntries = ref.watch(pendingWordsCountProvider).value ?? 0;
    final pendingVoices =
        ref.watch(pendingVoiceSubmissionsCountProvider).value ?? 0;
    final pendingLessons = ref.watch(pendingLessonsCountProvider).value ?? 0;

    // Stats for progress tracker
    final todayVerified = profile?['todayVerified'] ?? 0;
    final dailyGoal = profile?['dailyGoal'] ?? 20;
    final progress = (todayVerified / dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(urgentQueueProvider);
            ref.invalidate(pendingWordsCountProvider);
            ref.invalidate(pendingVoiceSubmissionsCountProvider);
            ref.invalidate(pendingLessonsCountProvider);
          },
          color: AppColors.gold500,
          backgroundColor: isDark ? AppColors.forest800 : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName, currentRank),
                const SizedBox(height: 24),
                const WotdWidget(),
                const SizedBox(height: 32),
                _buildVerificationOverview(
                  entries: pendingEntries,
                  voices: pendingVoices,
                  lessons: pendingLessons,
                ),
                const SizedBox(height: 32),
                _buildDailyImpactTracker(
                  todayVerified: todayVerified,
                  dailyGoal: dailyGoal,
                  progress: progress,
                ),
                const SizedBox(height: 32),
                Text(
                  'URGENT QUEUE',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                ref
                    .watch(urgentQueueProvider)
                    .when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: isDark
                                        ? AppColors.forest700
                                        : AppColors.forest200,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "All caught up!",
                                    style: AppTypography.body.copyWith(
                                      color: isDark
                                          ? AppColors.forest700
                                          : AppColors.forest300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: items
                              .map((item) => _buildUrgentCard(item))
                              .toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold500,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.semanticRed,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String rank) {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maayong\nAdlaw,\n$name!',
                  style: AppTypography.displayBold.copyWith(
                    color: isDark ? AppColors.gold500 : Colors.black,
                    fontSize: 32,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ELDER VALIDATOR  •  RANK $rank',
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.forest900,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationOverview({
    required int entries,
    required int voices,
    required int lessons,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENDING QUEUE',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQueueCard(
                title: 'ENTRIES',
                count: entries,
                icon: Icons.list_alt_rounded,
                color: AppColors.semanticGreen,
                route: '/validator/entries',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQueueCard(
                title: 'VOICES',
                count: voices,
                icon: Icons.record_voice_over_rounded,
                color: AppColors.semanticBlue,
                route: '/validator/voices',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQueueCard(
                title: 'LESSONS',
                count: lessons,
                icon: Icons.menu_book_rounded,
                color: AppColors.terracotta,
                route: '/validator/lessons',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQueueCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.forest800
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.forest700
                : AppColors.creamBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: AppTypography.h2ExtraBold.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.forest500,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.label.copyWith(
                color: AppColors.creamText3,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyImpactTracker({
    required int todayVerified,
    required int dailyGoal,
    required double progress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      theme: BrandCardTheme.vibrant,
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
                      'DAILY IMPACT',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep it up! You are ${dailyGoal - todayVerified} items away from your daily goal.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.creamText3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gold500,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$todayVerified',
                        style: AppTypography.h2ExtraBold.copyWith(
                          color: isDark ? Colors.white : AppColors.forest500,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '/$dailyGoal',
                        style: AppTypography.label.copyWith(
                          color: AppColors.creamText3,
                          fontSize: 10,
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildUrgentCard(ValidationItem item) {
    IconData itemIcon;
    Color iconColor;
    String route;

    switch (item.type) {
      case 'voice':
        itemIcon = Icons.record_voice_over_rounded;
        iconColor = AppColors.semanticBlue;
        route = '/validator/voices';
        break;
      case 'entry':
        itemIcon = Icons.list_alt_rounded;
        iconColor = AppColors.semanticGreen;
        route = '/validator/entries';
        break;
      case 'lesson':
      default:
        itemIcon = Icons.menu_book_rounded;
        iconColor = AppColors.terracotta;
        route = '/validator/lessons';
    }

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.forest800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(itemIcon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.priority.toUpperCase(),
                          style: AppTypography.label.copyWith(
                            color: AppColors.terracotta,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.dialect,
                        style: AppTypography.label.copyWith(
                          color: AppColors.creamText3,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: AppTypography.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.forest500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.creamText3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }
}


