import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ProgressHeader extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int hearts;
  final String? lessonId;
  final IconData? icon;

  const ProgressHeader({
    super.key, 
    required this.progress, 
    this.hearts = 5,
    this.lessonId,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      color: isDark ? AppColors.forest700 : Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : AppColors.forest500,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          
          // Advanced Hero Transition Destination
          if (icon != null)
            Hero(
              tag: 'lesson_icon_${lessonId ?? 'default'}',
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold500,
                  size: 20,
                ),
              ),
            ),
            
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold500, Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 1,
                          left: 2,
                          right: 2,
                          bottom: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Icon(
                    hearts > 0 ? Icons.favorite_rounded : Icons.favorite_border,
                    color: hearts > 0
                        ? AppColors.semanticRed
                        : (isDark ? Colors.white38 : AppColors.forest200),
                    size: 24,
                  )
                  .animate(key: ValueKey(hearts), target: 1)
                  .shake(hz: 8, curve: Curves.easeInOut)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.3, 1.3),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.3, 1.3),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                    curve: Curves.easeIn,
                  ),
              const SizedBox(width: 4),
              Text(
                "$hearts",
                style: AppTypography.h3.copyWith(
                  color: hearts > 0
                      ? AppColors.semanticRed
                      : (isDark ? Colors.white38 : AppColors.forest200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


