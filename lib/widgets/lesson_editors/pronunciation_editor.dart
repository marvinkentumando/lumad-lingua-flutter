import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
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
