import 'package:cloud_firestore/cloud_firestore.dart';

class VillageBroadcast {
  final String id;
  final String educatorId;
  final String educatorName;
  final String title;
  final String message;
  final DateTime timestamp;
  final List<String> recipients; // Student IDs

  VillageBroadcast({
    required this.id,
    required this.educatorId,
    required this.educatorName,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.recipients,
  });

  factory VillageBroadcast.fromFirestore(Map<String, dynamic> data, String id) {
    return VillageBroadcast(
      id: id,
      educatorId: data['educatorId'] ?? '',
      educatorName: data['educatorName'] ?? 'Educator',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      recipients: List<String>.from(data['recipients'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'educatorId': educatorId,
      'educatorName': educatorName,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'recipients': recipients,
    };
  }
}
