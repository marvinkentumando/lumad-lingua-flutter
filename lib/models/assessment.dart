import 'package:cloud_firestore/cloud_firestore.dart';

enum AssessmentType { preTest, postTest }

enum QuestionType { multipleChoice, starRating, textInput }

class AssessmentQuestion {
  final String id;
  final String text;
  final List<String> options;
  final bool isSurvey;
  final QuestionType questionType;

  AssessmentQuestion({
    required this.id,
    required this.text,
    this.options = const [],
    this.isSurvey = true,
    this.questionType = QuestionType.multipleChoice,
  });
}

class AssessmentResult {
  final String userId;
  final AssessmentType type;
  final String? lessonId;
  final String? lessonTitle;
  final double? accuracyScore;
  final int? ratingScore;
  final String? openTextFeedback;
  final int? timeSpentSeconds;
  final Map<String, dynamic> answers;
  final DateTime timestamp;

  AssessmentResult({
    required this.userId,
    required this.type,
    this.lessonId,
    this.lessonTitle,
    this.accuracyScore,
    this.ratingScore,
    this.openTextFeedback,
    this.timeSpentSeconds,
    required this.answers,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      if (lessonId != null) 'lessonId': lessonId,
      if (lessonTitle != null) 'lessonTitle': lessonTitle,
      if (accuracyScore != null) 'accuracyScore': accuracyScore,
      if (ratingScore != null) 'ratingScore': ratingScore,
      if (openTextFeedback != null && openTextFeedback!.isNotEmpty)
        'openTextFeedback': openTextFeedback,
      if (timeSpentSeconds != null) 'timeSpentSeconds': timeSpentSeconds,
      'answers': answers,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory AssessmentResult.fromFirestore(Map<String, dynamic> data) {
    return AssessmentResult(
      userId: data['userId'] ?? '',
      type: data['type'] == 'preTest'
          ? AssessmentType.preTest
          : AssessmentType.postTest,
      lessonId: data['lessonId'],
      lessonTitle: data['lessonTitle'],
      accuracyScore: (data['accuracyScore'] as num?)?.toDouble(),
      ratingScore: (data['ratingScore'] as num?)?.toInt(),
      openTextFeedback: data['openTextFeedback'],
      timeSpentSeconds: (data['timeSpentSeconds'] as num?)?.toInt(),
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
