import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await seedDictionary();
    await seedMunicipalities();
    await seedLessons();
    await seedArtifacts();
    await seedBadges();
  }

  static Future<void> seedBadges() async {
    final List<Map<String, dynamic>> sampleBadges = [
      {
        'title': 'Perfect Scholar',
        'description': 'Completed a lesson with 3 stars.',
        'iconName': 'star',
        'colorHex': '#FFD700',
      },
      {
        'title': 'Active Guardian',
        'description': 'Reached a 7-day streak.',
        'iconName': 'local_fire_department',
        'colorHex': '#FF5722',
      },
      {
        'title': 'Word Weaver',
        'description': 'Contributed 10 approved words.',
        'iconName': 'auto_awesome',
        'colorHex': '#9C27B0',
      },
    ];

    final batch = _db.batch();
    for (var badge in sampleBadges) {
      final docRef = _db.collection('badges').doc();
      batch.set(docRef, badge);
    }
    await batch.commit();
  }

  static Future<void> seedArtifacts() async {
    final List<Map<String, dynamic>> sampleArtifacts = [
      {
        'title': 'Mansaka Binallog',
        'description':
            'A traditional hand-woven textile featuring intricate geometric patterns representing the spirit of the mountains.',
        'imageUrl': 'assets/images/artifact_weave.png',
        'type': 'clothing',
        'culturalNote': 'Used in ceremonies to signify tribal leadership.',
        'tier': 'Sacred',
        'rarity': 5,
      },
      {
        'title': 'Mandaya Dagmay',
        'description':
            'A sacred cloth made from abaca fibers, dyed using organic pigments from the forest.',
        'imageUrl': '',
        'type': 'clothing',
        'culturalNote':
            'The patterns are said to be revealed in dreams by the ancestors.',
        'tier': 'Sacred',
        'rarity': 4,
      },
      {
        'title': 'Kudlung',
        'description':
            'A two-stringed boat lute used in traditional storytelling and community gatherings.',
        'imageUrl': '',
        'type': 'instrument',
        'culturalNote':
            'One string plays the melody while the other provides a constant drone.',
        'tier': 'Rare',
        'rarity': 3,
      },
      {
        'title': 'Sanggot',
        'description':
            'A curved tool used for harvesting and clearing brush in the ancestral highlands.',
        'imageUrl': '',
        'type': 'tool',
        'culturalNote':
            'Symbolizes the hardworking nature of the Lumad people.',
        'tier': 'Common',
        'rarity': 1,
      },
    ];

    final batch = _db.batch();
    for (var artifact in sampleArtifacts) {
      final docRef = _db.collection('artifacts').doc();
      batch.set(docRef, artifact);
    }
    await batch.commit();
  }

  static Future<void> seedLessons() async {
    final List<Map<String, dynamic>> sampleLessons = [
      {
        'title': 'Forest Gatherings',
        'description': 'Learn basic greetings used in communal gatherings.',
        'category': 'Basics',
        'language': 'Mansaka',
        'level': 1,
        'unitNumber': 3,
        'icon': 'psychology',
        'isPremium': false,
        'tasks': [
          {
            'id': 't1',
            'type': 'multipleChoice',
            'questionText': 'How do you say "Welcome" in Mansaka?',
            'options': ['Madayaw na pag-abot', 'Madyaw na buntag', 'Salamat'],
            'correctAnswerIndex': 0,
            'hintMetadata': 'It literally means "Good arrival".',
          },
          {
            'id': 't2',
            'type': 'pronunciation',
            'questionText': 'Pronounce "Madayaw"',
            'nativeWord': 'Madayaw',
            'phoneticGuide': '/ma-da-yaw/',
            'hintMetadata': 'Stress the last syllable.',
          },
        ],
      },
      {
        'title': 'Rivers of Life',
        'description': 'Master terms related to nature and water.',
        'category': 'Nature',
        'language': 'Mandaya',
        'level': 2,
        'unitNumber': 1,
        'icon': 'local_florist',
        'isPremium': false,
        'tasks': [
          {
            'id': 't3',
            'type': 'multipleChoice',
            'questionText': 'What is "River" in Mandaya?',
            'options': ['Suba', 'Sapa', 'Wahig'],
            'correctAnswerIndex': 2,
            'hintMetadata': 'Commonly used in Mandaya river names.',
          },
        ],
      },
    ];

    final batch = _db.batch();
    for (var lesson in sampleLessons) {
      final docRef = _db.collection('lessons').doc();
      batch.set(docRef, lesson);
    }
    await batch.commit();
  }

  static Future<void> seedDictionary() async {
    final List<Map<String, dynamic>> sampleWords = [
      {
        'term': 'Madayaw',
        'phonetic': '/ma-da-yaw/',
        'translation': 'Good / Beautiful',
        'translationFilipino': 'Mabuti / Maganda',
        'pos': 'adjective',
        'dialect': 'Mansaka',
        'definition':
            'A versatile greeting or description of something positive.',
        'usageExampleNative': 'Madayaw na pag-abot!',
        'usageExampleTranslation': 'Welcome (Good arrival)!',
        'status': 'approved',
        'isValidated': true,
      },
      {
        'term': 'Pyagpukan',
        'phonetic': '/pyag-pu-kan/',
        'translation': 'Ancestral Land',
        'translationFilipino': 'Lupang Ninuno',
        'pos': 'noun',
        'dialect': 'Mandaya',
        'definition': 'The sacred territory inherited from ancestors.',
        'usageExampleNative': 'Mahalaga ang pyagpukan para sa tribo.',
        'usageExampleTranslation':
            'The ancestral land is important for the tribe.',
        'status': 'approved',
        'isValidated': true,
      },
      {
        'term': 'Panayday',
        'phonetic': '/pa-nay-day/',
        'translation': 'To sing / chant',
        'translationFilipino': 'Umawit / Mag-chant',
        'pos': 'verb',
        'dialect': 'Lumad',
        'definition': 'Traditional way of rhythmic chanting of stories.',
        'usageExampleNative': 'Mag-panayday kita kani-on.',
        'usageExampleTranslation': 'Let us chant together later.',
        'status': 'approved',
        'isValidated': true,
      },
      {
        'term': 'Lugwa',
        'phonetic': '/lug-wa/',
        'translation': 'To emerge',
        'translationFilipino': 'Lumabas',
        'pos': 'verb',
        'dialect': 'Mansaka',
        'definition': 'To come out or appear from somewhere.',
        'usageExampleNative': 'Lugwa na kamo!',
        'usageExampleTranslation': 'Come out now!',
        'status': 'approved',
        'isValidated': true,
      },
      {
        'term': 'Buntag',
        'phonetic': '/bun-tag/',
        'translation': 'Morning',
        'translationFilipino': 'Umaga',
        'pos': 'noun',
        'dialect': 'Mandaya',
        'definition': 'The early part of the day.',
        'usageExampleNative': 'Madyaw na buntag.',
        'usageExampleTranslation': 'Good morning.',
        'status': 'approved',
        'isValidated': true,
      },
    ];

    final batch = _db.batch();
    for (var word in sampleWords) {
      final docRef = _db.collection('words').doc();
      batch.set(docRef, word);
    }
    await batch.commit();
  }

  static Future<void> seedMunicipalities() async {
    final List<Map<String, dynamic>> sampleMunis = [
      {
        'name': 'Davao City',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.0707, 125.6094),
        'description': 'The regional center of Davao.',
        'status': 'validated',
      },
      {
        'name': 'Digos City',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.7567, 125.3550),
        'description': 'Capital of Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Santa Cruz',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.8378, 125.4128),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Bansalan',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.7844, 125.2156),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Hagonoy',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.6719, 125.3403),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Magsaysay',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.7533, 125.1764),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Matanao',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.7444, 125.2333),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Padada',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.6500, 125.3667),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Sulop',
        'province': 'Davao del Sur',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.6333, 125.3333),
        'description': 'Municipality in Davao del Sur.',
        'status': 'validated',
      },
      {
        'name': 'Tagum City',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.4478, 125.8078),
        'description': 'Capital of Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Panabo City',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.3000, 125.6833),
        'description': 'City in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Island Garden City of Samal',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.0414, 125.7531),
        'description': 'Island city in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Carmen',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.3558, 125.7039),
        'description': 'Municipality in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Kapalong',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.7867, 125.7031),
        'description': 'Municipality in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'New Corella',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.5833, 125.8167),
        'description': 'Municipality in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Santo Tomas',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.5333, 125.6333),
        'description': 'Municipality in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Talaingod',
        'province': 'Davao del Norte',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.7000, 125.6167),
        'description': 'Municipality in Davao del Norte.',
        'status': 'validated',
      },
      {
        'name': 'Nabunturan',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.6000, 125.9667),
        'description': 'Capital of Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Compostela',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.6667, 126.0833),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Laak',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.8667, 125.8000),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Mabini',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.2833, 125.8500),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Maco',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.3500, 125.8500),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Maragusan',
        'province': 'Davao de Oro',
        'dialect': 'mansaka',
        'coords': const GeoPoint(7.3333, 126.1167),
        'description': 'Known for its cold climate and Mansaka heritage.',
        'status': 'validated',
      },
      {
        'name': 'Mawab',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.5000, 125.9333),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Monkayo',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.8167, 126.0500),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Montevista',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.7000, 126.0167),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Pantukan',
        'province': 'Davao de Oro',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.1333, 125.9000),
        'description': 'Municipality in Davao de Oro.',
        'status': 'validated',
      },
      {
        'name': 'Mati City',
        'province': 'Davao Oriental',
        'dialect': 'mandaya',
        'coords': const GeoPoint(6.9500, 126.2167),
        'description': 'Coastal area with rich Mandaya cultural roots.',
        'status': 'validated',
      },
      {
        'name': 'Baganga',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.5833, 126.5667),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Banaybanay',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.9333, 125.9833),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Boston',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.8667, 126.3667),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Caraga',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.3333, 126.5667),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Cateel',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.7833, 126.4500),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Lupon',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.9000, 126.0000),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Manay',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.2167, 126.5333),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'San Isidro',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.8333, 126.0833),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Tarragona',
        'province': 'Davao Oriental',
        'dialect': 'lumad',
        'coords': const GeoPoint(7.0500, 126.4500),
        'description': 'Municipality in Davao Oriental.',
        'status': 'validated',
      },
      {
        'name': 'Malita',
        'province': 'Davao Occidental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.4103, 125.6108),
        'description': 'Capital of Davao Occidental.',
        'status': 'validated',
      },
      {
        'name': 'Don Marcelino',
        'province': 'Davao Occidental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.1517, 125.6881),
        'description': 'Municipality in Davao Occidental.',
        'status': 'validated',
      },
      {
        'name': 'Jose Abad Santos',
        'province': 'Davao Occidental',
        'dialect': 'lumad',
        'coords': const GeoPoint(5.8833, 125.6167),
        'description': 'Municipality in Davao Occidental.',
        'status': 'validated',
      },
      {
        'name': 'Sarangani',
        'province': 'Davao Occidental',
        'dialect': 'lumad',
        'coords': const GeoPoint(5.4028, 125.4639),
        'description': 'Island municipality in Davao Occidental.',
        'status': 'validated',
      },
      {
        'name': 'Santa Maria',
        'province': 'Davao Occidental',
        'dialect': 'lumad',
        'coords': const GeoPoint(6.5667, 125.4667),
        'description': 'Municipality in Davao Occidental.',
        'status': 'validated',
      },
    ];

    final batch = _db.batch();
    for (var muni in sampleMunis) {
      // Use a consistent ID generation logic: name lowercase with underscores
      final docId = muni['name'].toString().toLowerCase().replaceAll(' ', '_');
      final docRef = _db.collection('municipalities').doc(docId);
      batch.set(docRef, muni, SetOptions(merge: true));
    }
    await batch.commit();
  }
}



