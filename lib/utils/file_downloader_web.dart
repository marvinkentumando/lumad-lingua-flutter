import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> saveAndDownloadFile(String content, String fileName) async {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return 'Browser Downloads folder';
}
