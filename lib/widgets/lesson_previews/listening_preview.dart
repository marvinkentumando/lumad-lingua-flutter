import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/listening_view.dart';

class ListeningPreview extends StatelessWidget {
  final LessonStep step;

  const ListeningPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final q = step.data['question'] ?? '';
    final options = List<String>.from(step.data['options'] ?? ['', '', '']);
    final audio = step.data['audioUrl'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ListeningView(
          question: q,
          options: options,
          audioUrl: audio,
          isReadOnly: true,
        ),
      ),
    );
  }
}
