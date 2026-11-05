import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  final file = File(r'C:/Users/Aspire-3/Downloads/mansaka_fully_predicted_corpus.csv');
  final contents = await file.readAsString();
  final rows = const CsvDecoder().convert(contents);
  final headers = rows[0].map((e) => e.toString()).toList();
  for (int i = 0; i < headers.length; i++) {
    print('$i: ${headers[i]}');
  }
}
