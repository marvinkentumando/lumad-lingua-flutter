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
        'name': 'Maragusan',
        'province': 'Davao de Oro',
        'dialect': 'mansaka',
        'coords': const GeoPoint(7.3333, 126.1167),
        'description': 'Known for its cold climate and Mansaka heritage.',
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
    ];

    final batch = _db.batch();
    for (var muni in sampleMunis) {
      final docRef = _db.collection('municipalities').doc();
      batch.set(docRef, muni);
    }
    await batch.commit();
  }
}



