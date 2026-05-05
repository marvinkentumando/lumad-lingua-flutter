import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/mcq_view.dart';

class MCQPreview extends StatelessWidget {
  final LessonStep step;

  const MCQPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final q = step.data['question'] ?? '';
    final options = List<String>.from(step.data['options'] ?? ['', '', '']);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: MCQView(question: q, options: options, isReadOnly: true),
      ),
    );
  }
}
