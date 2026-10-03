import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../activity_views/word_hunt_view.dart';

class WordHuntPreview extends StatefulWidget {
  final LessonStep step;

  const WordHuntPreview({super.key, required this.step});

  @override
  State<WordHuntPreview> createState() => _WordHuntPreviewState();
}

class _WordHuntPreviewState extends State<WordHuntPreview> {
  final Set<String> _foundWords = {};

  @override
  Widget build(BuildContext context) {
    final rawQuestion = widget.step.data['question'] as String?;
    final question = (rawQuestion != null && rawQuestion.trim().isNotEmpty)
        ? rawQuestion
        : 'Find the hidden words';
    final words = List<String>.from(
      (widget.step.data['options'] as List?)
              ?.where((w) => w.toString().trim().isNotEmpty) ??
          [],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: WordHuntView(
              question: question,
              wordsToFind: words.isNotEmpty ? words : ['MANSAKA', 'LUMAD'],
              foundWords: _foundWords,
              onWordFound: (word) {
                setState(() {
                  _foundWords.add(word);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
