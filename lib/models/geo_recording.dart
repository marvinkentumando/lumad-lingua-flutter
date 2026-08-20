class AudioRecording {
  final String id;
  final String title;
  final String speakerName;
  final String speakerRole;
  final String audioUrl;
  final String transcript;
  final Duration duration;

  const AudioRecording({
    required this.id,
    required this.title,
    required this.speakerName,
    this.speakerRole = "Community Member",
    this.audioUrl = "",
    this.transcript = "Transcript unavailable.",
    this.duration = const Duration(minutes: 1),
  });
}

class GeoRecording {
  final String id;
  final String title; // Usually the municipality name
  final String province;
  final String dialect;
  final double latitude;
  final double longitude;
  final String metadata;
  final bool isValidated;
  final List<String> supportedDialects;
  final List<AudioRecording> recordings;

  const GeoRecording({
    required this.id,
    required this.title,
    required this.province,
    required this.dialect,
    required this.latitude,
    required this.longitude,
    required this.metadata,
    required this.isValidated,
    this.supportedDialects = const [],
    this.recordings = const [],
  });

  // Explicitly ensure the getter exists and is safe
  List<String> get safeSupportedDialects => supportedDialects;

  factory GeoRecording.fromFirestore(Map<String, dynamic> data, String id) {
    var geoPoint = data['coords'];

    // Safely extract supported dialects
    List<String> dialects = [];
    if (data['supportedDialects'] != null) {
      if (data['supportedDialects'] is List) {
        dialects = List<String>.from(data['supportedDialects']);
      } else if (data['supportedDialects'] is String) {
        dialects = [data['supportedDialects'] as String];
      }
    }

    return GeoRecording(
      id: id,
      title: data['name'] ?? '',
      province: data['province'] ?? 'Davao Region',
      dialect: data['dialect'] ?? 'Lumad',
      latitude: geoPoint != null ? geoPoint.latitude : 0.0,
      longitude: geoPoint != null ? geoPoint.longitude : 0.0,
      metadata: data['description'] ?? '',
      isValidated: data['status'] == 'validated',
      supportedDialects: dialects,
      recordings: [], // Can implement from Firestore later
    );
  }
}
