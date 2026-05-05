import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/haptic_service.dart';
import 'lottie_feedback.dart';

class XPCelebration extends StatefulWidget {
  final int xpEarned;
  final VoidCallback onComplete;

  const XPCelebration({
    super.key,
    required this.xpEarned,
    required this.onComplete,
  });

  @override
  State<XPCelebration> createState() => _XPCelebrationState();
}

class _XPCelebrationState extends State<XPCelebration> {
  @override
  void initState() {
    super.initState();
    HapticService.celebration();
    Future.delayed(const Duration(milliseconds: 3500), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Lottie Celebration
        const CelebrationLottie(),

        // Main Text Column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.gold500, width: 4),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.gold500,
                    size: 80,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 1.seconds,
                )
                .then()
                .shimmer(duration: 1.seconds, color: Colors.white),
            const SizedBox(height: 32),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: widget.xpEarned),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Text(
                  "+$value XP",
                  style: AppTypography.display.copyWith(
                    fontSize: 56,
                    color: AppColors.gold500,
                    shadows: [
                      const Shadow(
                        blurRadius: 16,
                        color: AppColors.gold700,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ).animate().slideY(begin: 0.5, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Text(
              "Lumad Wisdom Gained!",
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.forest700,
                letterSpacing: 1.5,
              ),
            ).animate().fade(delay: 800.ms).slideY(begin: 0.5),
          ],
        ),
      ],
    );
  }
}
