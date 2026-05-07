import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/scenario_view.dart';

class ScenarioPreview extends StatelessWidget {
  final LessonStep step;

  const ScenarioPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final q = step.data['question'] ?? '';
    final text = step.data['scenarioText'] ?? '';
    final options = List<String>.from(step.data['options'] ?? ['', '', '']);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ScenarioView(
          question: q,
          scenarioText: text,
          options: options,
          isReadOnly: true,
        ),
      ),
    );
  }
}



