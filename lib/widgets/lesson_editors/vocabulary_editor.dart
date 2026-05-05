import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class VocabularyEditor extends StatelessWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const VocabularyEditor({
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
          'Vocabulary Detail',
          style: AppTypography.label.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Native Word',
          initialValue: step.data['word'] ?? '',
          maxLength: 60,
          onChanged: (val) {
            step.data['word'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Translation',
          initialValue: step.data['translation'] ?? '',
          maxLength: 100,
          onChanged: (val) {
            step.data['translation'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          label: 'Definition/Context',
          initialValue: step.data['definition'] ?? '',
          maxLength: 300,
          onChanged: (val) {
            step.data['definition'] = val;
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


