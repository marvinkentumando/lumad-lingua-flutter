import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

String redactPersonalNames(String text) {
  if (text.isEmpty) return text;
  String result = text;

  final knownNames = [
    'Carla Bantasan Cemine',
    'Carla Bantasan',
    'Mario Manaytay Yesan Bantasan',
    'Mario Manaytay',
    'Yesan Bantasan',
    'Danilo Jamorie A. Manlinab',
    'Danilo Jamorie Manlinab',
    'Danilo Manlinab',
    'Jupiter Comania',
    'Cesar Clarion Colina Sr.',
    'Cesar Clarion Colina',
    'Cesar Colina',
    'Tata Albarico',
    'Maricar Zamora Mabanglo',
    'Maricar Zamora',
    'CEPRIANO MAGLINAB',
    'Cepriano Maglinab',
    'Grace Marundan Ilio',
    'Grace Marundan',
    'Larry Bunyogan Sr.',
    'Larry Bunyogan',
    'Bhe-bhe Masunggari Escarlan',
    'Bhe-bhe Escarlan',
    'Bhe-bhe Masunggari',
    'Wiser Jade',
    'Saturnino Hidlay',
    'Ruben Capantoc Comania Jr.',
    'Ruben Comania Jr.',
    'Ruben Comania',
    'Julimar Mante',
    'Lito Bangkiling',
    'Liniel Calibadan',
    'liniel calibadan',
    'Noelita (nday) camana maglimolo',
    'Noelita Camana Maglimolo',
    'Noelita Camana',
    'Noelita Maglimolo',
    'Feliciana sa dalagapa',
    'Feliciana Liganso',
    'Feliciana',
    'Pablo Ampilan',
    'Alopio',
    'Londong Casa Manumbilang',
    'Tiumoh Yu Dakaw',
    'Su Re',
    'Nerio Camana',
    'Kikido EgDaasan',
    'Mang Edo Cabiza',
    'Edo Cabiza',
    'jems maniquez',
    'Jems Maniquez',
    'Romeo Tadian',
  ];

  for (final name in knownNames) {
    final pattern = RegExp(RegExp.escape(name), caseSensitive: false);
    result = result.replaceAll(pattern, '[Redacted Name]');
  }

  final honorificPattern = RegExp(
    r"\b(Sir|Ma'am|Mr|Mrs|Ms|Dr|Hon|IPMR|Capt|Mayor|Cong|Mtkdg|Mktdg|Gbbyn|Gibubayan|Chairman)\.?\s+([A-Z][a-zA-Z\-]+(?:\s+[A-Z][a-zA-Z\-]+|\s+[A-Z]\.){1,4}(?:\s+(?:Sr|Jr|III|II|IV)\.?)?)",
    caseSensitive: false,
  );
  result = result.replaceAllMapped(honorificPattern, (match) {
    final honorific = match.group(1);
    return '$honorific [Redacted Name]';
  });

  final cSiMentionPattern = RegExp(
    r'\b(c|si|kay|kang)\s+([A-Za-z\-]+(?:\s+[A-Za-z\-]+){1,3})\b',
    caseSensitive: false,
  );
  result = result.replaceAllMapped(cSiMentionPattern, (match) {
    final prefix = match.group(1);
    final nameCandidate = match.group(2)!;
    final lower = nameCandidate.toLowerCase();
    if (lower == 'ina' ||
        lower == 'ama' ||
        lower == 'bapa' ||
        lower == 'magbabaya' ||
        lower == 'dios' ||
        lower == 'god' ||
        lower.startsWith('mga') ||
        lower == 'tribu') {
      return match.group(0)!;
    }
    return '$prefix [Redacted Name]';
  });

  result = result.replaceAll(RegExp(r'(\[Redacted Name\]\s*)+'), '[Redacted Name]');
  return result;
}

void main() async {
  final csvFile = File(r'C:/Users/Aspire-3/Downloads/mansaka_fully_predicted_corpus.csv');
  if (!await csvFile.exists()) {
    print('CSV file not found');
    return;
  }

  final contents = await csvFile.readAsString();
  final rows = const CsvDecoder().convert(contents);
  if (rows.isEmpty) {
    print('CSV is empty');
    return;
  }

  final headers = rows[0].map((e) => e.toString().trim()).toList();
  final List<Map<String, dynamic>> jsonList = [];

  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    final map = <String, dynamic>{};
    for (int j = 0; j < headers.length && j < row.length; j++) {
      map[headers[j]] = row[j];
    }

    final id = map['id']?.toString().trim();
    if (id == null || id.isEmpty) continue;

    final preprocessed = map['preprocessed_text']?.toString().trim() ?? '';
    final normalized = map['normalized_text']?.toString().trim() ?? '';
    final textToUse = preprocessed.isNotEmpty ? preprocessed : normalized;
    if (textToUse.isEmpty) continue;

    final redactedText = redactPersonalNames(textToUse);
    final englishTrans = map['english_translation']?.toString().trim() ?? '';
    final redactedEnglish = redactPersonalNames(englishTrans);

    final finalSentiment = map['final_sentiment_label']?.toString().trim().toLowerCase() ?? 'neutral';
    String category = 'neutral';
    double score = 0.0;
    if (finalSentiment.contains('positive')) {
      category = 'positive';
      score = 0.8;
    } else if (finalSentiment.contains('negative')) {
      category = 'negative';
      score = -0.8;
    }

    final postedAtStr = map['posted_at']?.toString().trim() ?? '';
    String? publishedAt;
    if (postedAtStr.isNotEmpty) {
      final dt = DateTime.tryParse(postedAtStr);
      if (dt != null) {
        publishedAt = dt.toIso8601String();
      }
    }

    final url = map['url']?.toString().trim();

    final words = redactedText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet()
        .take(4)
        .toList();

    jsonList.add({
      'id': id,
      'originalText': redactedText,
      'filipinoTranslation': 'Saling Filipino (Sumangguni sa orihinal na post)',
      'englishTranslation': redactedEnglish,
      'sentimentCategory': category,
      'sentimentScore': score,
      'keywords': words,
      if (publishedAt != null) 'publishedAt': publishedAt,
      if (url != null && url.isNotEmpty) 'sourceUrl': url,
      'sparkCount': null,
    });
  }

  final outputFile = File(r'C:/Users/Aspire-3/Desktop/Lumad Lingua Flutter/assets/data/sentiment_posts.json');
  const encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString(encoder.convert(jsonList));
  print('Successfully generated ${jsonList.length} sentiment posts to ${outputFile.path}');
}
