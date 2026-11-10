import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class OverviewEditor extends StatelessWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const OverviewEditor({
    super.key,
    required this.step,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lesson Overview & Abstract',
          style: AppTypography.label.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Overview Title',
          initialValue: (step.data['title'] as String?)?.isNotEmpty == true && step.data['title'] != 'overview'
              ? step.data['title']!
              : (step.title.isNotEmpty && step.title != 'overview'
                  ? step.title
                  : 'Lesson Overview'),
          maxLength: 80,
          onChanged: (val) {
            step.title = val;
            step.data['title'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Main Content / Abstract',
          initialValue: step.data['content'] ?? step.data['overviewText'] ?? '',
          maxLength: 1200,
          hint: 'Provide structured educational material, lesson objectives, or narrative overview...',
          onChanged: (val) {
            step.data['content'] = val;
            step.data['overviewText'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Cultural Heritage Notes (Optional)',
          initialValue: step.data['culturalNotes'] ?? '',
          maxLength: 400,
          hint: 'Add indigenous background, elder notes, or ancestral wisdom highlights...',
          onChanged: (val) {
            step.data['culturalNotes'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 24),
        EditorUtils.buildImageAttachment(
          context: context,
          currentImageUrl: step.data['imageUrl'],
          onUploadComplete: (url) {
            step.data['imageUrl'] = url;
            onUpdated();
          },
          onDelete: () {
            step.data['imageUrl'] = null;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildAudioRecorderPlaceholder(
          context: context,
          currentAudioUrl: step.data['audioUrl'],
          onUploadComplete: (url) {
            step.data['audioUrl'] = url;
            onUpdated();
          },
        ),
      ],
    );
  }
}
