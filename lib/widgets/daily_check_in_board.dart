import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class DailyCheckInBoard extends StatelessWidget {
  final int currentStreak;

  const DailyCheckInBoard({super.key, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.forest900,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, color: AppColors.gold500, size: 48)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.2, duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              '$currentStreak Day Streak!',
              style: AppTypography.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep the fire burning to unlock sacred artifacts.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isUnlocked = day <= (currentStreak % 7 == 0 && currentStreak > 0 ? 7 : currentStreak % 7);
                  final isRewardDay = day == 7;
                  
                  return Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppColors.gold500.withValues(alpha: 0.2) : Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked ? AppColors.gold500 : Colors.white24,
                        width: isUnlocked ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Day $day', style: AppTypography.label.copyWith(color: isUnlocked ? AppColors.gold500 : Colors.white54, fontSize: 10)),
                        const SizedBox(height: 8),
                        Icon(
                          isRewardDay ? Icons.star_rounded : Icons.local_fire_department_rounded,
                          color: isUnlocked ? AppColors.gold500 : Colors.white24,
                          size: 24,
                        ),
                      ],
                    ),
                  ).animate(delay: (index * 100).ms).slideY(begin: 0.5).fadeIn();
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold500,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('CONTINUE JOURNEY', style: AppTypography.label.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
}

void showDailyCheckInBoard(BuildContext context, int currentStreak) {
  showDialog(
    context: context,
    builder: (context) => DailyCheckInBoard(currentStreak: currentStreak),
  );
}
