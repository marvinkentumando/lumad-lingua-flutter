import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/lesson_task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';

class LessonAbstractModal extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onBeginLesson;

  const LessonAbstractModal({
    super.key,
    required this.lesson,
    required this.onBeginLesson,
  });

  static void show(BuildContext context, {required Lesson lesson, required VoidCallback onBeginLesson}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonAbstractModal(
        lesson: lesson,
        onBeginLesson: onBeginLesson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract overview task content if present
    String overviewText = lesson.description;
    final overviewTasks = lesson.tasks.where((t) => t.type == TaskType.overview).toList();
    if (overviewTasks.isNotEmpty) {
      final taskText = overviewTasks.first.hintMetadata.trim().isNotEmpty
          ? overviewTasks.first.hintMetadata.trim()
          : overviewTasks.first.questionText.trim();
      if (taskText.isNotEmpty) {
        overviewText = taskText;
      }
    }

    final interactiveTasksCount = lesson.tasks.where((t) => t.type != TaskType.overview).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900 : AppColors.creamBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? AppColors.gold500.withValues(alpha: 0.2) : AppColors.creamBorder,
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Unit & Language Chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'UNIT ${lesson.unitNumber}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  lesson.language.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white70 : AppColors.forest900,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lesson Title
          Text(
            lesson.title,
            style: AppTypography.h1ExtraBold.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Overview & Abstract Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AppColors.gold500, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'LESSON ABSTRACT & OVERVIEW',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  overviewText.isNotEmpty
                      ? overviewText
                      : 'Explore vocabulary, indigenous cultural contexts, and interactive practice activities in this lesson.',
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white70 : AppColors.forest900,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Session Tasks Summary Badge
          Row(
            children: [
              const Icon(Icons.extension_rounded, size: 16, color: AppColors.gold500),
              const SizedBox(width: 8),
              Text(
                '$interactiveTasksCount Interactive Learning Tasks',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.forest900,
                ),
              ),
              const Spacer(),
              Text(
                '~${(interactiveTasksCount * 2).clamp(3, 20)} mins',
                style: AppTypography.caption.copyWith(color: AppColors.gold500),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Begin Lesson Button
          BrandButton(
            text: 'BEGIN LESSON',
            icon: Icons.play_arrow_rounded,
            type: BrandButtonType.primary,
            onTap: () {
              Navigator.of(context).pop();
              onBeginLesson();
            },
          ),
        ],
      ),
    );
  }
}
