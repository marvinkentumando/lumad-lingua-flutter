import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/sentence_reordering_view.dart';

class SentenceReorderingPreview extends StatelessWidget {
  final LessonStep step;

  const SentenceReorderingPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final q = step.data['question'] ?? '';
    final parts = List<String>.from(step.data['parts'] ?? []);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SentenceReorderingView(
          question: q,
          scrambledParts: parts,
          availableParts: const [],
          onWordTap: (_) {},
          onScrambledWordTap: (_) {},
          isReadOnly: true,
        ),
      ),
    );
  }
}
