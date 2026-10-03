import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/fill_blanks_view.dart';

class FillBlanksPreview extends StatefulWidget {
  final LessonStep step;

  const FillBlanksPreview({super.key, required this.step});

  @override
  State<FillBlanksPreview> createState() => _FillBlanksPreviewState();
}

class _FillBlanksPreviewState extends State<FillBlanksPreview> {
  final Map<int, String> _selectedBlanks = {};

  @override
  Widget build(BuildContext context) {
    final rawQuestion = widget.step.data['question'] as String?;
    final question = (rawQuestion != null && rawQuestion.trim().isNotEmpty)
        ? rawQuestion
        : 'Fill in the missing words';

    final rawSentence = (widget.step.data['expectedSentence'] ??
        widget.step.data['sentence']) as String?;
    String sentence = (rawSentence != null && rawSentence.trim().isNotEmpty)
        ? rawSentence
        : 'Complete the sentence: [word]';

    if (!sentence.contains('[word]')) {
      sentence = '$sentence [word]';
    }

    final rawParts = List<String>.from(
      (widget.step.data['parts'] as List?)
              ?.where((p) => p.toString().trim().isNotEmpty) ??
          [],
    );
    final options = rawParts.isNotEmpty ? rawParts : ['word'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: FillBlanksView(
        question: question,
        sentence: sentence,
        availableOptions: options,
        selectedBlanks: _selectedBlanks,
        onWordSelected: (index, word) {
          setState(() {
            _selectedBlanks[index] = word;
          });
        },
        onBlankTap: (index) {
          setState(() {
            _selectedBlanks.remove(index);
          });
        },
      ),
    );
  }
}
