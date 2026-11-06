import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'editor_utils.dart';

class PronunciationEditor extends StatelessWidget {
  final LessonStep step;
  final VoidCallback onUpdated;

  const PronunciationEditor({
    super.key,
    required this.step,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pronunciation Anchor Detail',
              style: AppTypography.label.copyWith(color: AppColors.gold500),
            ),
            InkWell(
              onTap: () {
                EditorUtils.showNativeAudioVaultPicker(
                  context: context,
                  onComplete: (url) {
                    step.data['audioUrl'] = url;
                    onUpdated();
                  },
                  onEntrySelected: (entry) {
                    step.data['word'] = entry.title;
                    step.data['phonetic'] = entry.subtitle.isNotEmpty
                        ? entry.subtitle
                        : entry.folderName.replaceAll('_', ' ');
                    step.data['audioUrl'] = entry.primaryTake?.audioUrl ?? '';
                    step.title = entry.title;
                    onUpdated();
                  },
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      color: AppColors.gold500,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Auto-Fill Vault',
                      style: TextStyle(
                        color: AppColors.gold500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          key: ValueKey('pron_word_${step.id}_${step.data['word']}'),
          label: 'Native Word / Target Phrase',
          initialValue: step.data['word'] ?? '',
          maxLength: 60,
          onChanged: (val) {
            step.data['word'] = val;
            onUpdated();
          },
        ),
        const SizedBox(height: 16),
        EditorUtils.buildDataTextField(
          key: ValueKey('pron_phonetic_${step.id}_${step.data['phonetic']}'),
          label: 'Phonetic Guide',
          initialValue: step.data['phonetic'] ?? '',
          maxLength: 80,
          onChanged: (val) {
            step.data['phonetic'] = val;
            onUpdated();
          },
          hint: 'e.g. ma-a-yong',
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
