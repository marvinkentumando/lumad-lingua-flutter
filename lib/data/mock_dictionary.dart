import '../models/dictionary_entry.dart';

final List<DictionaryEntry> mockDictionary = [
  const DictionaryEntry(
    id: '1',
    indigenousWord: 'Buntag',
    translation: 'Morning',
    translationFilipino: 'Umaga',
    partOfSpeech: PartOfSpeech.noun,
    language: 'Mansaka',
    usageContext: 'Used commonly in greetings like "Maayong buntag".',
  ),
  const DictionaryEntry(
    id: '2',
    indigenousWord: 'Salamat',
    translation: 'Thank you',
    translationFilipino: 'Salamat',
    partOfSpeech: PartOfSpeech.phrase,
    language: 'Mansaka / Mandaya',
    usageContext: 'Universal expression of gratitude in Mindanao.',
  ),
  const DictionaryEntry(
    id: '3',
    indigenousWord: 'Kalog',
    translation: 'Friend / Companion',
    translationFilipino: 'Kaibigan',
    partOfSpeech: PartOfSpeech.noun,
    language: 'Mandaya',
    usageContext: 'Used to address someone you share a close bond with.',
  ),
  const DictionaryEntry(
    id: '4',
    indigenousWord: 'Manik',
    translation: 'To climb / Ascend',
    translationFilipino: 'Umakyat',
    partOfSpeech: PartOfSpeech.verb,
    language: 'Mansaka',
    usageContext: 'Refers to climbing a mountain or stairs.',
  ),
];
