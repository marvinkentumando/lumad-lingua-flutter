import '../models/geo_recording.dart';

List<AudioRecording> _generateMockAudios(String dialect) {
  return [
    AudioRecording(
      id: '${dialect.toLowerCase()}_1',
      title: 'Everyday Greetings in $dialect',
      speakerName: 'Datu Matu',
      speakerRole: 'Tribal Elder',
      transcript: 'Maayong buntag. Kanang... [Transcript of morning greetings]',
      duration: const Duration(minutes: 1, seconds: 45),
    ),
  ];
}

final List<GeoRecording> mockRecordings = [
  GeoRecording(
    id: 'oro_1',
    title: 'Compostela',
    province: 'Davao de Oro',
    dialect: 'Mansaka',
    latitude: 7.66,
    longitude: 126.08,
    metadata: 'Mansaka settlements',
    isValidated: true,
    recordings: _generateMockAudios('Mansaka'),
  ),
  GeoRecording(
    id: 'oro_11',
    title: 'Pantukan',
    province: 'Davao de Oro',
    dialect: 'Mansaka',
    latitude: 7.13,
    longitude: 125.90,
    metadata: 'Mining regions',
    isValidated: true,
    recordings: _generateMockAudios('Mansaka'),
  ),
];
