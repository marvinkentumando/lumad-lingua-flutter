import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'summary_widgets.dart';

class SessionResultsView extends StatelessWidget {
  final int xpEarned;
  final int stars;
  final int totalTasks;
  final int distinctMistakeTasks;
  final int bonusXp;
  final VoidCallback onFinish;

  const SessionResultsView({
    super.key,
    required this.xpEarned,
    required this.stars,
    required this.totalTasks,
    required this.distinctMistakeTasks,
    required this.bonusXp,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalTasks == 0
        ? 100
        : (((totalTasks - distinctMistakeTasks) / totalTasks) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.forest900,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildStarRating(),
            const SizedBox(height: 24),
            Text(
              'SESSION COMPLETE',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SummaryStatRow(
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.gold500,
                      label: 'XP Earned',
                      value: '+$xpEarned XP',
                    ),
                    const SizedBox(height: 12),
                    SummaryStatRow(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.semanticGreen,
                      label: 'Accuracy',
                      value: '$accuracy%',
                    ),
                    const SizedBox(height: 12),
                    SummaryStatRow(
                      icon: Icons.task_alt_rounded,
                      iconColor: AppColors.semanticBlue,
                      label: 'Tasks Completed',
                      value: '$totalTasks tasks',
                    ),
                    if (bonusXp > 0) ...[
                      const SizedBox(height: 12),
                      SummaryStatRow(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.orange,
                        label: 'Bonus XP',
                        value: '+$bonusXp XP',
                      ),
                    ],
                  ],
                ).animate().fadeIn().slideY(begin: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold500,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'FINISH',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            isActive ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isActive ? AppColors.gold500 : Colors.white10,
            size: index == 1 ? 80 : 50,
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.easeOutBack,
                delay: Duration(milliseconds: index * 200),
              )
              .shimmer(delay: 1.seconds, duration: 2.seconds),
        );
      }),
    );
  }
}
