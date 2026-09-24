import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndDownloadFile(String content, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsString(content);
  return filePath;
}
