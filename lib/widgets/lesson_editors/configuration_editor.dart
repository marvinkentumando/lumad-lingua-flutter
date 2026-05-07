import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson_step.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ConfigurationEditor extends ConsumerWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final String? currentLessonId;
  final String? prerequisiteId;
  final String category;
  final String dialect;
  final int unitNumber;
  final String difficulty;
  final LessonStep step;
  final ValueChanged<String?> onPrerequisiteChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onDialectChanged;
  final ValueChanged<int> onUnitNumberChanged;
  final ValueChanged<String?> onDifficultyChanged;
  final VoidCallback onUpdated;

  const ConfigurationEditor({
    super.key,
    required this.titleController,
    required this.descController,
    required this.currentLessonId,
    required this.prerequisiteId,
    required this.category,
    required this.dialect,
    required this.unitNumber,
    required this.difficulty,
    required this.step,
    required this.onPrerequisiteChanged,
    required this.onCategoryChanged,
    required this.onDialectChanged,
    required this.onUnitNumberChanged,
    required this.onDifficultyChanged,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          maxLength: 50,
          decoration: InputDecoration(
            labelText: 'Lesson Title',
            hintText: 'e.g. Daily Phrases',
            filled: true,
            fillColor: isDark ? AppColors.forestDarkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.creamText3,
              fontSize: 10,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
          onChanged: (v) => onUpdated(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descController,
          maxLength: 250,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Brief lesson description',
            filled: true,
            fillColor: isDark ? AppColors.forestDarkCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(
              color: isDark ? Colors.white38 : AppColors.creamText3,
              fontSize: 10,
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
          onChanged: (v) => onUpdated(),
        ),
        const SizedBox(height: 16),
        Text(
          'Prerequisite Lesson',
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ref
            .watch(allLessonsStreamProvider)
            .when(
              data: (lessons) {
                final otherLessons = lessons
                    .where((l) => l.id != currentLessonId)
                    .toList();
                if (otherLessons.isEmpty && prerequisiteId == null) {
                  return Text(
                    'No other lessons available.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.creamText3,
                    ),
                  );
                }

                final List<DropdownMenuItem<String?>> items = [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      'None',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.creamText2,
                      ),
                    ),
                  ),
                ];

                items.addAll(
                  otherLessons.map(
                    (l) => DropdownMenuItem(
                      value: l.id,
                      child: Text(
                        l.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.creamText,
                        ),
                      ),
                    ),
                  ),
                );

                // Safety check: ensure prerequisiteId exists in items
                final bool exists =
                    prerequisiteId == null ||
                    otherLessons.any((l) => l.id == prerequisiteId);

                return DropdownButtonFormField<String?>(
                  initialValue: exists ? prerequisiteId : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppColors.forestDarkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.forestDarkCard : Colors.white,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gold500,
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.creamText,
                  ),
                  items: items,
                  onChanged: onPrerequisiteChanged,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => const Text(
                'Error loading lessons',
                style: TextStyle(color: AppColors.semanticRed),
              ),
            ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Category',
          ['Vocabulary', 'Oral History', 'Rituals', 'Phrases'],
          category,
          onCategoryChanged,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Dialect',
          ['Mansaka', 'Mandaya'],
          dialect,
          onDialectChanged,
          isDark,
        ),
        const SizedBox(height: 16),
        Text(
          'Unit Number',
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: unitNumber,
              dropdownColor: isDark ? AppColors.forest800 : Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.gold500,
              ),
              isExpanded: true,
              items: List.generate(20, (i) => i + 1)
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        'Unit $v',
                        style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => onUnitNumberChanged(val!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Difficulty Level',
          ['Beginner', 'Intermediate', 'Advanced'],
          difficulty,
          onDifficultyChanged,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildTagsInput(context, isDark),
        const SizedBox(height: 16),
        _buildTimeEstimator(isDark),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String current,
    ValueChanged<String?> onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              dropdownColor: isDark ? AppColors.forest800 : Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.gold500,
              ),
              isExpanded: true,
              items: options
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        v,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInput(BuildContext context, bool isDark) {
    final tags = step.data['tags'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultural Tags',
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tags.map(
                (t) => Chip(
                  label: Text(
                    t,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.creamText,
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                  onDeleted: () {
                    tags.remove(t);
                    step.data['tags'] = tags;
                    onUpdated();
                  },
                ),
              ),
              ActionChip(
                label: const Text(
                  '+ Add Tag',
                  style: TextStyle(color: AppColors.gold500, fontSize: 10),
                ),
                backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
                onPressed: () => _showAddTagDialog(context, tags, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeEstimator(bool isDark) {
    final mins = step.data['estimatedMinutes'] ?? 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Time: $mins mins',
          style: AppTypography.body.copyWith(
            color: isDark ? Colors.white70 : AppColors.creamText2,
            fontSize: 13,
          ),
        ),
        Slider(
          value: (mins as int).toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: AppColors.gold500,
          inactiveColor: isDark ? Colors.white12 : AppColors.creamBorder,
          onChanged: (val) {
            step.data['estimatedMinutes'] = val.toInt();
            onUpdated();
          },
        ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context, List<dynamic> tags, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.forestDarkCard : Colors.white,
        title: Text(
          'Add Cultural Tag',
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Ritual, Daily, Elder',
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : AppColors.creamText3,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.creamText3,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                tags.add(controller.text.trim());
                step.data['tags'] = tags;
                onUpdated();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'ADD',
              style: TextStyle(color: AppColors.gold500),
            ),
          ),
        ],
      ),
    );
  }
}


