import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/student_provider.dart';
import '../services/haptic_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/topo_background.dart';
import '../widgets/mist_crystal_store.dart';

class StreakHistoryScreen extends ConsumerWidget {
  const StreakHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: Stack(
        children: [
          const TopoBackground(opacity: 0.05, baseColor: AppColors.gold500),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildStreakHero(context, student),
                  const SizedBox(height: 32),
                  _buildShieldStats(context, ref, student),
                  const SizedBox(height: 32),
                  _buildMonthlyCalendar(context, student),
                  const SizedBox(height: 32),
                  _buildStreakMilestones(context, student, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.gold500,
        ),
        const SizedBox(width: 8),
        Text(
          'STREAK JOURNEY',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakHero(BuildContext context, StudentState student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
              
              // Flame Icon
              const Icon(
                Icons.local_fire_department_rounded,
                size: 120,
                color: AppColors.gold500,
              ).animate(onPlay: (c) => c.repeat())
               .shimmer(duration: 2.seconds, color: Colors.orangeAccent)
               .shake(hz: 2, curve: Curves.easeInOut),
              
              // Streak Number
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${student.displayedStreak} DAYS',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            student.displayedStreak > 0 
              ? 'You\'re on fire!' 
              : 'Start your journey today!',
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.forest700,
            ),
          ),
          Text(
            'Keep learning daily to grow your streak.',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldStats(BuildContext context, WidgetRef ref, StudentState student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.gold500, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STREAK SHIELDS',
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.gold700,
                  ),
                ),
                Text(
                  '${student.streakShields} Available',
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                  ),
                ),
              ],
            ),
          ),
          BrandButton(
            text: 'GET MORE',
            onTap: () => showMistCrystalStore(context, ref),
            type: BrandButtonType.small,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(BuildContext context, StudentState student) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(now).toUpperCase(),
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.4),
              ),
            ),
            Text(
              'ACTIVITY MAP',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.gold700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BrandCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => Text(d, style: TextStyle(color: isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.bold)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: daysInMonth + (startWeekday - 1),
                itemBuilder: (context, index) {
                  if (index < startWeekday - 1) {
                    return const SizedBox.shrink();
                  }
                  final day = index - (startWeekday - 2);
                  final isToday = day == now.day;

                  final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                  final isActive = student.activityMap[dateKey] ?? false;

                  return Container(
                    decoration: BoxDecoration(
                      color: isActive 
                        ? AppColors.gold500 
                        : (isToday ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: AppColors.gold500) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isActive
                            ? Colors.black
                            : (isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.6)),
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakMilestones(BuildContext context, StudentState student, WidgetRef ref) {
    final milestones = [
      {'days': 7, 'title': 'One Week', 'reward': 100, 'rewardText': '100 Crystals'},
      {'days': 30, 'title': 'Month of Wisdom', 'reward': 500, 'rewardText': '500 Crystals'},
      {'days': 100, 'title': 'Tribe Guardian', 'reward': 2000, 'rewardText': '2,000 Crystals'},
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MILESTONES',
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),
        ...milestones.map((m) {
          final days = m['days'] as int;
          final reward = m['reward'] as int;
          final isUnlocked = student.displayedStreak >= days;
          final isClaimed = student.claimedMilestones.contains(days);
          final progress = (student.displayedStreak / days).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BrandCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isClaimed ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)) : AppColors.gold500)
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isClaimed
                          ? Icons.check_circle_rounded
                          : (isUnlocked ? Icons.emoji_events_rounded : Icons.lock_rounded),
                      color: isUnlocked && !isClaimed
                          ? Colors.black
                          : (isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.2)),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: AppTypography.h3.copyWith(
                            color: isUnlocked
                                ? (isDark ? Colors.white : AppColors.forest900)
                                : (isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.3)),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          m['rewardText'] as String,
                          style: AppTypography.label.copyWith(
                            color: isUnlocked
                                ? (isDark ? AppColors.gold500 : AppColors.gold700)
                                : (isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.2)),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            color: AppColors.gold500,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (isUnlocked && !isClaimed)
                    BrandButton(
                      text: 'CLAIM',
                      onTap: () {
                        HapticService.celebration();
                        ref.read(studentProvider.notifier).claimMilestone(days, reward);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Claimed ${m['rewardText']}! 🎉'),
                            backgroundColor: AppColors.forest700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      type: BrandButtonType.small,
                    )
                  else
                    Text(
                      '$days d',
                      style: AppTypography.mono.copyWith(
                        color: isUnlocked
                            ? (isDark ? AppColors.gold500 : AppColors.gold700)
                            : (isDark ? Colors.grey : AppColors.forest900.withValues(alpha: 0.2)),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

