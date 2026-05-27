import 'package:cloud_firestore/cloud_firestore.dart';

class StudentFeedback {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentPhotoUrl;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? educatorReply;
  final DateTime? repliedAt;

  StudentFeedback({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUrl,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.educatorReply,
    this.repliedAt,
  });

  factory StudentFeedback.fromFirestore(Map<String, dynamic> data, String id) {
    return StudentFeedback(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown Student',
      studentPhotoUrl: data['studentPhotoUrl'],
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      educatorReply: data['educatorReply'],
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      if (studentPhotoUrl != null) 'studentPhotoUrl': studentPhotoUrl,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'educatorReply': educatorReply,
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
    };
  }
}
