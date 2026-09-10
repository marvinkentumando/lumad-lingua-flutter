enum ActivityType {
  configuration,
  vocabulary,
  mcq,
  pronunciation,
  matching,
  sentenceReordering,
  listening,
  scenario,
  wordHunt,
  trueOrFalse,
  fillInTheBlanks,
}

class LessonStep {
  final String id;
  ActivityType type;
  String title;
  Map<String, dynamic> data;

  LessonStep({
    required this.id,
    required this.type,
    required this.title,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  bool get isValid {
    switch (type) {
      case ActivityType.configuration:
        return true; // Config is handled by the overall lesson model
      case ActivityType.vocabulary:
        return (data['word'] ?? '').isNotEmpty &&
            (data['translation'] ?? '').isNotEmpty;
      case ActivityType.mcq:
        final options = data['options'] as List?;
        return (data['question'] ?? '').trim().isNotEmpty &&
            options != null &&
            options.length >= 2 &&
            options.every((opt) => opt.toString().trim().isNotEmpty) &&
            data['correctIndex'] != null;
      case ActivityType.listening:
        final options = data['options'] as List?;
        return (data['question'] ?? '').trim().isNotEmpty &&
            options != null &&
            options.length >= 2 &&
            options.every((opt) => opt.toString().trim().isNotEmpty) &&
            data['correctIndex'] != null &&
            (data['audioUrl'] ?? '').isNotEmpty;
      case ActivityType.pronunciation:
        return (data['word'] ?? '').isNotEmpty &&
            (data['audioUrl'] ?? '').isNotEmpty;
      case ActivityType.matching:
        final pairs = data['pairs'] as List?;
        return (data['question'] ?? '').trim().isNotEmpty &&
            pairs != null &&
            pairs.length >= 2 &&
            pairs.every(
              (p) =>
                  (p['native'] ?? '').trim().isNotEmpty &&
                  (p['meaning'] ?? '').trim().isNotEmpty,
            );
      case ActivityType.sentenceReordering:
        final parts = data['parts'] as List?;
        return (data['question'] ?? '').trim().isNotEmpty &&
            (data['sentence'] ?? '').trim().isNotEmpty &&
            parts != null &&
            parts.length >= 2 &&
            parts.every((p) => p.toString().trim().isNotEmpty);
      case ActivityType.scenario:
        final options = data['options'] as List?;
        return (data['scenarioText'] ?? '').trim().isNotEmpty &&
            (data['question'] ?? '').trim().isNotEmpty &&
            options != null &&
            options.length >= 2 &&
            options.every((opt) => opt.toString().trim().isNotEmpty);
      case ActivityType.wordHunt:
        final options = data['options'] as List?;
        return (data['question'] ?? '').trim().isNotEmpty &&
            options != null &&
            options.isNotEmpty;
      case ActivityType.trueOrFalse:
        return (data['question'] ?? '').trim().isNotEmpty &&
            data['correctIndex'] != null;
      case ActivityType.fillInTheBlanks:
        return (data['question'] ?? '').trim().isNotEmpty &&
            (data['expectedSentence'] ?? '').trim().isNotEmpty;
    }
  }
}



