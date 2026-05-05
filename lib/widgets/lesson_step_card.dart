import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_button.dart';

enum LessonStepStatus { completed, active, locked }

class LessonStepCard extends StatelessWidget {
  final String title;
  final String type;
  final String time;
  final LessonStepStatus status;
  final int stars;
  final IconData? icon;
  final VoidCallback? onTap;
  final int? bestScore;
  final String? lessonId;

  const LessonStepCard({
    super.key,
    required this.title,
    required this.type,
    required this.time,
    this.status = LessonStepStatus.locked,
    this.stars = 0,
    this.icon,
    this.onTap,
    this.bestScore,
    this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Connection lines
        if (status != LessonStepStatus.active)
          Positioned(
            left: -12,
            top: 30,
            child: Container(
              width: 68,
              height: 4,
              color: AppColors.gold500.withOpacity(0.3),
            ),
          ),

        // Vertical path line (behind the node)
        Positioned(
          left: 20,
          top: -40,
          bottom: 0,
          child: Container(
            width: 4,
            color: AppColors.gold500.withOpacity(0.2),
          ),
        ),

        // Status Node
        Positioned(
          left: status == LessonStepStatus.active ? -4 : 4,
          top: status == LessonStepStatus.active ? 40 : 15,
          child: Container(
            width: status == LessonStepStatus.active ? 52 : 36,
            height: status == LessonStepStatus.active ? 52 : 36,
            decoration: BoxDecoration(
              color: status == LessonStepStatus.locked
                  ? (isDark ? Colors.grey.shade900 : Colors.grey.shade200)
                  : AppColors.gold500,
              shape: BoxShape.circle,
              boxShadow: status == LessonStepStatus.active
                  ? [
                      BoxShadow(
                        color: AppColors.gold500.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              status == LessonStepStatus.active
                  ? Icons.play_arrow_rounded
                  : (status == LessonStepStatus.completed
                        ? Icons.check_rounded
                        : Icons.lock_outline),
              color: status == LessonStepStatus.locked
                  ? Colors.grey
                  : Colors.black,
              size: status == LessonStepStatus.active ? 32 : 20,
            ),
          ),
        ),

        // Card Content
        Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              status == LessonStepStatus.active ? 24 : 20,
            ),
            decoration: BoxDecoration(
              color: status == LessonStepStatus.active
                  ? (isDark ? AppColors.forestDarkCard : Colors.white)
                  : (isDark
                        ? const Color(0xFF242C26)
                        : const Color(0xFFFEF8ED)),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05,
                ),
              ),
              boxShadow: status == LessonStepStatus.active
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Lesson Icon/Image
                Hero(
                  tag: 'lesson_icon_${lessonId ?? title}',
                  child: Container(
                    width: status == LessonStepStatus.active ? 56 : 64,
                    height: status == LessonStepStatus.active ? 56 : 64,
                    decoration: BoxDecoration(
                      color: status == LessonStepStatus.active
                          ? (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05))
                          : (status == LessonStepStatus.completed
                                ? AppColors.gold500.withOpacity(0.15)
                                : (isDark
                                      ? Colors.white.withOpacity(0.03)
                                      : Colors.black.withOpacity(0.04))),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon ?? Icons.menu_book_rounded,
                      color: status == LessonStepStatus.active
                          ? AppColors.gold500
                          : (status == LessonStepStatus.completed
                                ? AppColors.gold500
                                : (isDark ? Colors.white24 : Colors.black26)),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Lesson Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : (status == LessonStepStatus.active
                                        ? Colors.black.withOpacity(0.05)
                                        : const Color(0xFFF0E0D0)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: AppTypography.label.copyWith(
                                color: isDark
                                    ? Colors.white54
                                    : (status == LessonStepStatus.active
                                          ? Colors.black54
                                          : const Color(0xFFA04040)),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: AppTypography.body.copyWith(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (status == LessonStepStatus.completed) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              3,
                              (i) => Icon(
                                Icons.star_rounded,
                                color: i < stars
                                    ? AppColors.gold500
                                    : Colors.grey.withOpacity(0.3),
                                size: 16,
                              ),
                            ),
                            if (bestScore != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold500.withOpacity(0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$bestScore%',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.gold500,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (status == LessonStepStatus.active &&
                          onTap != null) ...[
                        const SizedBox(height: 16),
                        BrandButton(
                          text: 'START',
                          onTap: onTap,
                          type: BrandButtonType.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ).animate().slideX(begin: 0.1, duration: 400.ms),
          ),
        ),
      ],
    );
  }
}


