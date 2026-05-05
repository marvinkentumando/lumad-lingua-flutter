// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int changedFiles = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('_rounded_')) {
      content = content.replaceAll('_rounded_', '_');
      file.writeAsStringSync(content);
      changedFiles++;
      print('Fixed ${file.path}');
    }
  }
  print('Total files fixed: $changedFiles');
}
