import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/true_false_view.dart';

class TrueFalsePreview extends StatefulWidget {
  final LessonStep step;

  const TrueFalsePreview({super.key, required this.step});

  @override
  State<TrueFalsePreview> createState() => _TrueFalsePreviewState();
}

class _TrueFalsePreviewState extends State<TrueFalsePreview> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final rawQuestion = widget.step.data['question'] as String?;
    final question = (rawQuestion != null && rawQuestion.trim().isNotEmpty)
        ? rawQuestion
        : 'Is this statement correct?';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: TrueFalseView(
            question: question,
            selectedIndex: _selectedIndex,
            onOptionSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
