import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_button.dart';

enum LessonStepStatus { completed, active, locked }

class LessonStepCard extends StatelessWidget {
  final String title;
  final String time;
  final LessonStepStatus status;
  final VoidCallback? onTap;
  final int? bestScore;
  final String? lessonId;
  final bool isLast;

  const LessonStepCard({
    super.key,
    required this.title,
    required this.time,
    this.status = LessonStepStatus.locked,
    this.onTap,
    this.bestScore,
    this.lessonId,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Connection lines (drawn on the left relative to the content)
        if (!isLast)
          Positioned(
            left: 19,
            top: 40,
            bottom: -24,
            child: Container(
              width: 2,
              color: AppColors.gold500.withValues(alpha: 0.2),
            ),
          ),

        // Content
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Node
              Container(
                margin: const EdgeInsets.only(top: 4, right: 16),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: status == LessonStepStatus.locked
                      ? (isDark ? Colors.grey.shade900 : Colors.grey.shade300)
                      : (status == LessonStepStatus.active ? AppColors.gold500 : AppColors.gold500.withValues(alpha: 0.2)),
                  shape: BoxShape.circle,
                  border: status == LessonStepStatus.completed
                      ? Border.all(color: AppColors.gold500, width: 2)
                      : null,
                  boxShadow: status == LessonStepStatus.active
                      ? [
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
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
                      : (status == LessonStepStatus.completed ? AppColors.gold500 : Colors.black),
                  size: status == LessonStepStatus.active ? 24 : 18,
                ),
              ),

              // Item Content (No background card)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                    if (status == LessonStepStatus.completed) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (bestScore != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(alpha: 0.15),
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
                    if (status == LessonStepStatus.active && onTap != null) ...[
                      const SizedBox(height: 12),
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
          ).animate().slideX(begin: 0.05, duration: 300.ms),
        ),
      ],
    );
  }
}



