import 'package:latlong2/latlong.dart';

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
  final LatLng location;
  final String metadata;
  final bool isValidated;
  final List<AudioRecording> recordings;

  const GeoRecording({
    required this.id,
    required this.title,
    required this.province,
    required this.dialect,
    required this.location,
    required this.metadata,
    required this.isValidated,
    this.recordings = const [],
  });

  factory GeoRecording.fromFirestore(Map<String, dynamic> data, String id) {
    var geoPoint = data['coords'];
    return GeoRecording(
      id: id,
      title: data['name'] ?? '',
      province: data['province'] ?? 'Davao Region',
      dialect: data['dialect'] ?? 'Lumad',
      location: geoPoint != null
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : const LatLng(0, 0),
      metadata: data['description'] ?? '',
      isValidated: data['status'] == 'validated',
      recordings: [], // Can implement from Firestore later
    );
  }
}



