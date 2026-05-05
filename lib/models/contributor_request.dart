import 'package:cloud_firestore/cloud_firestore.dart';

class ContributorRequest {
  final String id;
  final String userId;
  final String username;
  final String userEmail;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? message;

  ContributorRequest({
    required this.id,
    required this.userId,
    required this.username,
    required this.userEmail,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory ContributorRequest.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return ContributorRequest(
      id: id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown',
      userEmail: data['userEmail'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      message: data['message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userEmail': userEmail,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'message': message,
    };
  }
}


