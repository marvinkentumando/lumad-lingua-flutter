import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a voice submission in the validation pipeline.
enum VoiceStatus { pending, approved, flagged, rejected }

/// Represents a community voice recording submission awaiting validation.
class VoiceSubmission {
  final String id;
  final String title;
  final String dialect;
  final String contributorId;
  final String contributorName;
  final String audioUrl;
  final String transcript;
  final String? culturalNote;
  final String speakerRole;
  final String? province;
  final String? municipality;
  final String? barangay;
  final String? duration;
  final bool priority;
  final VoiceStatus status;
  final String? municipalityId; // Reference to municipality sub-collection
  final String? recordingId; // Reference to the actual recording doc
  final String? validatorId;
  final String? validatorRole;
  final String? validatorFeedback;
  final String? validatorAudioTipUrl;
  final DateTime? submittedAt;
  final DateTime? validatedAt;

  const VoiceSubmission({
    required this.id,
    required this.title,
    required this.dialect,
    required this.contributorId,
    required this.contributorName,
    required this.audioUrl,
    this.transcript = '',
    this.culturalNote,
    this.speakerRole = 'Community Member',
    this.province,
    this.municipality,
    this.barangay,
    this.duration,
    this.priority = false,
    this.status = VoiceStatus.approved,
    this.municipalityId,
    this.recordingId,
    this.validatorId,
    this.validatorRole,
    this.validatorFeedback,
    this.validatorAudioTipUrl,
    this.submittedAt,
    this.validatedAt,
  });

  factory VoiceSubmission.fromFirestore(Map<String, dynamic> data, String id) {
    return VoiceSubmission(
      id: id,
      title: data['title'] ?? 'Untitled Recording',
      dialect: data['dialect'] ?? 'Unknown',
      contributorId: data['contributorId'] ?? '',
      contributorName:
          data['contributorName'] ?? data['speakerName'] ?? 'Unknown',
      audioUrl: data['audioUrl'] ?? '',
      transcript: data['transcript'] ?? data['transcription'] ?? '',
      culturalNote: data['culturalNote'] ?? data['note'],
      speakerRole: data['speakerRole'] ?? 'Community Member',
      province: data['province'],
      municipality: data['municipality'],
      barangay: data['barangay'],
      duration: data['duration'],
      priority: data['priority'] == true,
      status: _parseStatus(data['status']),
      municipalityId: data['municipalityId'],
      recordingId: data['recordingId'],
      validatorId: data['validatorId'],
      validatorRole: data['validatorRole'],
      validatorFeedback: data['validatorFeedback'],
      validatorAudioTipUrl: data['validatorAudioTipUrl'],
      submittedAt: _parseTimestamp(data['submittedAt'] ?? data['timestamp']),
      validatedAt: _parseTimestamp(data['validatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'dialect': dialect,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'audioUrl': audioUrl,
      'transcript': transcript,
      'culturalNote': culturalNote,
      'speakerRole': speakerRole,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'duration': duration,
      'priority': priority,
      'status': status.name,
      'validatorFeedback': validatorFeedback,
      'validatorAudioTipUrl': validatorAudioTipUrl,
      'municipalityId': municipalityId,
      'recordingId': recordingId,
    };
  }

  static VoiceStatus _parseStatus(dynamic value) {
    if (value is String) {
      return VoiceStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VoiceStatus.approved,
      );
    }
    return VoiceStatus.approved;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}



