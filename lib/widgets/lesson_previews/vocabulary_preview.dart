import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/vocabulary_view.dart';

class VocabularyPreview extends StatelessWidget {
  final LessonStep step;

  const VocabularyPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final word = step.data['word'] ?? '';
    final trans = step.data['translation'] ?? '';
    final def = step.data['definition'] ?? '';
    final img = step.data['imageUrl'];
    final audio = step.data['audioUrl'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: VocabularyView(
          nativeWord: word,
          translation: trans,
          definition: def,
          imageUrl: img,
          audioUrl: audio,
          isReadOnly: true,
        ),
      ),
    );
  }
}
