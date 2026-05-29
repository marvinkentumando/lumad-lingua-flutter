import 'package:cloud_firestore/cloud_firestore.dart';

enum AssessmentType { preTest, postTest }

class AssessmentQuestion {
  final String id;
  final String text;
  final List<String> options;
  final bool isSurvey;

  AssessmentQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.isSurvey = true,
  });
}

class AssessmentResult {
  final String userId;
  final AssessmentType type;
  final String? lessonId;
  final Map<String, dynamic> answers;
  final DateTime timestamp;

  AssessmentResult({
    required this.userId,
    required this.type,
    this.lessonId,
    required this.answers,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'lessonId': lessonId,
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
