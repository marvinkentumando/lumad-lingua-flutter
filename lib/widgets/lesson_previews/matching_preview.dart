import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/matching_view.dart';

class MatchingPreview extends StatelessWidget {
  final LessonStep step;

  const MatchingPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final q = step.data['question'] ?? '';
    final pairs =
        (step.data['pairs'] as List?)
            ?.map((p) => Map<String, String>.from(p))
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: MatchingView(
          question: q,
          pairs: pairs,
          matchedPairs: const {},
          onNativeTap: (_) {},
          onMeaningTap: (_) {},
          isReadOnly: true,
        ),
      ),
    );
  }
}


