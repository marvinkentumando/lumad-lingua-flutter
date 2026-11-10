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
        if ((step.data['word'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.gold500),
                label: Text('Insert Word: "${step.data['word']}"', style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.gold500.withValues(alpha: 0.15),
                labelStyle: const TextStyle(color: AppColors.gold500),
                onPressed: () {
                  final currentDef = step.data['definition'] ?? '';
                  final wordToInsert = step.data['word'];
                  final newDef = currentDef.isEmpty ? wordToInsert : '$currentDef $wordToInsert';
                  step.data['definition'] = newDef;
                  onUpdated();
                },
              ),
            ],
          ),
        ],
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



