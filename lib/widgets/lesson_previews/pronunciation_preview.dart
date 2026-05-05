import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/pronunciation_view.dart';

class PronunciationPreview extends StatelessWidget {
  final LessonStep step;

  const PronunciationPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final word = step.data['word'] ?? '';
    final phonetic = step.data['phonetic'] ?? '';
    final q = step.data['question'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: PronunciationView(
          question: q,
          word: word,
          phonetic: phonetic,
          audioUrl: step.data['audioUrl'],
          isReadOnly: true,
        ),
      ),
    );
  }
}
