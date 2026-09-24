import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static Future<String> downloadCsv(String content, String fileName) async {
    return await saveAndDownloadFile(content, fileName);
  }
}
