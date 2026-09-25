import 'package:hive/hive.dart';

part 'dictionary_entry.g.dart';

@HiveType(typeId: 0)
enum PartOfSpeech {
  @HiveField(0)
  noun,
  @HiveField(1)
  verb,
  @HiveField(2)
  adjective,
  @HiveField(3)
  phrase,
  @HiveField(4)
  adverb,
  @HiveField(5)
  pronoun,
  @HiveField(6)
  preposition,
  @HiveField(7)
  conjunction,
  @HiveField(8)
  interjection,
  @HiveField(9)
  idiom,
  @HiveField(10)
  proverb,
  @HiveField(11)
  simile,
  @HiveField(12)
  metaphor,
  @HiveField(13)
  personification,
  @HiveField(14)
  hyperbole,
  @HiveField(15)
  onomatopoeia,
  @HiveField(16)
  locative,
  @HiveField(17)
  particle,
  @HiveField(18)
  prefix,
  @HiveField(19)
  suffix,
  @HiveField(20)
  marker,
  @HiveField(21)
  vocative,
  @HiveField(22)
  interrogative,
}

@HiveType(typeId: 1)
enum ValidationStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  flagged,
  @HiveField(3)
  rejected,
}

@HiveType(typeId: 2)
class DictionaryEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String indigenousWord;
  @HiveField(2)
  final String? phonetic;
  @HiveField(3)
  final String translation; // English
  @HiveField(4)
  final String translationFilipino;
  @HiveField(5)
  final PartOfSpeech partOfSpeech;
  @HiveField(6)
  final String language; // e.g. "Mansaka"
  @HiveField(7)
  final String usageContext; // Definition
  @HiveField(8)
  final String? usageExampleNative;
  @HiveField(9)
  final String? usageExampleTranslation;
  @HiveField(10)
  final String? audioUrl;

  @HiveField(11)
  final ValidationStatus status;
  @HiveField(12)
  final String? validatorRole;
  @HiveField(13)
  final String? validatorId;
  @HiveField(14)
  final String? validatorFeedback;
  @HiveField(15)
  final String? contributorName;
  @HiveField(16)
  final String? contributorId;
  @HiveField(17)
  final DateTime? validatedAt;
  @HiveField(18)
  final DateTime? submittedAt;
  @HiveField(19)
  final String? validatorAudioTipUrl;

  const DictionaryEntry({
    required this.id,
    required this.indigenousWord,
    this.phonetic,
    this.translation = '',
    this.translationFilipino = '',
    required this.partOfSpeech,
    required this.language,
    required this.usageContext,
    this.usageExampleNative,
    this.usageExampleTranslation,
    this.audioUrl,
    this.status = ValidationStatus.approved,
    this.validatorRole,
    this.validatorId,
    this.validatorFeedback,
    this.contributorName,
    this.contributorId,
    this.validatedAt,
    this.submittedAt,
    this.validatorAudioTipUrl,
  });

  bool get isValidated => status == ValidationStatus.approved;

  String get partOfSpeechLabel {
    switch (partOfSpeech) {
      case PartOfSpeech.noun:
        return 'Noun';
      case PartOfSpeech.verb:
        return 'Verb';
      case PartOfSpeech.adjective:
        return 'Adjective';
      case PartOfSpeech.phrase:
        return 'Phrase';
      case PartOfSpeech.adverb:
        return 'Adverb';
      case PartOfSpeech.pronoun:
        return 'Pronoun';
      case PartOfSpeech.preposition:
        return 'Preposition';
      case PartOfSpeech.conjunction:
        return 'Conjunction';
      case PartOfSpeech.interjection:
        return 'Interjection';
      case PartOfSpeech.idiom:
        return 'Idiom / Expression';
      case PartOfSpeech.proverb:
        return 'Proverb / Salawikain';
      case PartOfSpeech.simile:
        return 'Simile';
      case PartOfSpeech.metaphor:
        return 'Metaphor';
      case PartOfSpeech.personification:
        return 'Personification';
      case PartOfSpeech.hyperbole:
        return 'Hyperbole';
      case PartOfSpeech.onomatopoeia:
        return 'Onomatopoeia';
      case PartOfSpeech.locative:
        return 'Locative';
      case PartOfSpeech.particle:
        return 'Particle';
      case PartOfSpeech.prefix:
        return 'Prefix';
      case PartOfSpeech.suffix:
        return 'Suffix';
      case PartOfSpeech.marker:
        return 'Marker';
      case PartOfSpeech.vocative:
        return 'Vocative';
      case PartOfSpeech.interrogative:
        return 'Interrogative';
    }
  }

  factory DictionaryEntry.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? validatedAt;
    if (data['validatedAt'] != null) {
      if (data['validatedAt'].runtimeType.toString().contains('Timestamp')) {
        validatedAt = data['validatedAt'].toDate();
      } else if (data['validatedAt'] is String) {
        validatedAt = DateTime.tryParse(data['validatedAt']);
      }
    }

    DateTime? submittedAt;
    final dynamic rawCreatedAt = data['createdAt'] ?? data['timestamp'];
    if (rawCreatedAt != null) {
      if (rawCreatedAt.runtimeType.toString().contains('Timestamp')) {
        submittedAt = rawCreatedAt.toDate();
      } else if (rawCreatedAt is String) {
        submittedAt = DateTime.tryParse(rawCreatedAt);
      }
    }

    return DictionaryEntry(
      id: id,
      indigenousWord: data['term'] ?? '',
      phonetic: data['phonetic'],
      translation: data['translation'] ?? '',
      translationFilipino: data['translationFilipino'] ?? '',
      partOfSpeech: PartOfSpeech.values.firstWhere(
        (e) => e.name == (data['pos'] ?? 'noun'),
        orElse: () => PartOfSpeech.noun,
      ),
      language: data['dialect'] ?? 'Lumad',
      usageContext: data['definition'] ?? '',
      usageExampleNative: data['usageExampleNative'],
      usageExampleTranslation: data['usageExampleTranslation'],
      audioUrl: data['audioUrl'] ?? data['audioPath'],
      status: ValidationStatus.values.firstWhere(
        (e) =>
            e.name ==
            (data['status'] ?? 'approved'),
        orElse: () => ValidationStatus.approved,
      ),
      validatorRole: data['validatorRole'],
      validatorId: data['validatorId'],
      validatorFeedback: data['validatorFeedback'],
      validatorAudioTipUrl: data['validatorAudioTipUrl'],
      contributorName: data['contributorName'],
      contributorId: data['contributorId'],
      validatedAt: validatedAt,
      submittedAt: submittedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'term': indigenousWord,
      'term_lowercase': indigenousWord.toLowerCase(),
      'phonetic': phonetic,
      'translation': translation,
      'translationFilipino': translationFilipino,
      'pos': partOfSpeech.name,
      'dialect': language,
      'definition': usageContext,
      'usageExampleNative': usageExampleNative,
      'usageExampleTranslation': usageExampleTranslation,
      'audioUrl': audioUrl,
      'status': status.name,
      'isValidated': status == ValidationStatus.approved,
      'validatorRole': validatorRole,
      'validatorId': validatorId,
      'validatorFeedback': validatorFeedback,
      'validatorAudioTipUrl': validatorAudioTipUrl,
      'contributorName': contributorName,
      'contributorId': contributorId,
      if (validatedAt != null) 'validatedAt': validatedAt,
    };
  }
}



