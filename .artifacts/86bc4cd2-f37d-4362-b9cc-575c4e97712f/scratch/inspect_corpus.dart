import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  final file = File(r'C:/Users/Aspire-3/Downloads/mansaka_fully_predicted_corpus.csv');
  if (!await file.exists()) {
    print('File not found');
    return;
  }
  final contents = await file.readAsString();
  final rows = const CsvDecoder().convert(contents);
  if (rows.isEmpty) {
    print('Empty CSV');
    return;
  }
  final headers = rows[0].map((e) => e.toString()).toList();
  print('Headers count: ${headers.length}');
  print('Total rows: ${rows.length - 1}');

  for (int i = 1; i <= 3 && i < rows.length; i++) {
    final row = rows[i];
    final map = <String, dynamic>{};
    for (int j = 0; j < headers.length && j < row.length; j++) {
      map[headers[j]] = row[j];
    }
    print('--- Row $i ---');
    print('id: ${map['id']}');
    print('preprocessed_text: ${map['preprocessed_text']}');
    print('final_sentiment_label: ${map['final_sentiment_label']}');
    print('english_translation: ${map['english_translation']}');
  }
}
