import '../models/lesson_task.dart';

class TaskEvaluationResult {
  final bool isCorrect;
  final String feedbackSubtitle;

  TaskEvaluationResult({required this.isCorrect, required this.feedbackSubtitle});
}

class TaskEvaluator {
  static TaskEvaluationResult evaluate({
    required LessonTask task,
    int? selectedIndex,
    List<String> scrambledParts = const [],
    Map<String, String> matchedPairs = const {},
    Map<int, String> selectedBlanks = const {},
    bool hasRecorded = false,
    String lastWords = '',
  }) {
    bool isCorrect = false;
    String feedbackSubtitle = "";

    switch (task.type) {
      case TaskType.multipleChoice:
      case TaskType.listening:
      case TaskType.trueOrFalse:
        isCorrect = selectedIndex == task.correctAnswerIndex;
        if (task.type == TaskType.trueOrFalse) {
          final correctLabel = task.correctAnswerIndex == 0 ? 'TRUE' : 'FALSE';
          feedbackSubtitle = isCorrect ? "Spot on! That's correct." : "Actually, the answer is $correctLabel.";
        } else {
          feedbackSubtitle = isCorrect ? task.hintMetadata : "Correct answer: ${task.options[task.correctAnswerIndex]}.";
        }
        break;

      case TaskType.sentenceReordering:
        isCorrect = scrambledParts.join(' ') == task.expectedSentence;
        feedbackSubtitle = isCorrect ? task.hintMetadata : "Correct answer: ${task.expectedSentence}.";
        break;

      case TaskType.matching:
        isCorrect = true;
        List<String> incorrectPairs = [];
        for (var p in task.pairs) {
          final native = p['native'] ?? '';
          final expectedMeaning = p['meaning'] ?? '';
          if (matchedPairs[native] != expectedMeaning) {
            isCorrect = false;
            incorrectPairs.add('$native -> $expectedMeaning');
          }
        }
        feedbackSubtitle = isCorrect ? "Ancient connections restored!" : "Review these pairs:\n${incorrectPairs.join('\n')}";
        break;

      case TaskType.pronunciation:
        isCorrect = false;
        if (hasRecorded && lastWords.isNotEmpty) {
          final similarity = _stringSimilarity(
            lastWords.toLowerCase().trim(),
            task.nativeWord.toLowerCase().trim(),
          );
          isCorrect = similarity >= 0.6;
          feedbackSubtitle = isCorrect
              ? "Captured: \"$lastWords\" (${(similarity * 100).round()}% match). Great effort!"
              : "Heard: \"$lastWords\". Try to say \"${task.nativeWord}\" more clearly. (${(similarity * 100).round()}% match)";
        } else {
          feedbackSubtitle = "We couldn't hear you clearly. Please try again.";
        }
        break;

      case TaskType.vocabulary:
        isCorrect = true;
        feedbackSubtitle = "Great job reviewing this word!";
        break;

      case TaskType.scenario:
        isCorrect = selectedIndex == task.correctAnswerIndex;
        feedbackSubtitle = isCorrect
            ? "Perfect response!"
            : "Actually, it might be better to say: ${task.options[task.correctAnswerIndex]}";
        break;

      case TaskType.wordHunt:
        // Already handled by UI state in session screen (checking foundWords.length)
        isCorrect = true; 
        feedbackSubtitle = "Excellent! You found all the words.";
        break;

      case TaskType.fillInTheBlanks:
        isCorrect = true;
        for (int i = 0; i < task.sentenceParts.length; i++) {
          if (selectedBlanks[i] != task.sentenceParts[i]) {
            isCorrect = false;
            break;
          }
        }
        feedbackSubtitle = isCorrect ? "Sentence complete and accurate!" : "Some words don't quite fit there.";
        break;
    }

    return TaskEvaluationResult(isCorrect: isCorrect, feedbackSubtitle: feedbackSubtitle);
  }

  static double _stringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    int matches = 0;
    List<String> aWords = a.split(' ');
    List<String> bWords = b.split(' ');

    for (var word in aWords) {
      if (bWords.contains(word)) {
        matches++;
      }
    }

    return (matches * 2) / (aWords.length + bWords.length);
  }
}
