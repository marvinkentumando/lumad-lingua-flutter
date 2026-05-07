import 'package:share_plus/share_plus.dart';
import '../models/dictionary_entry.dart';

class SharingService {
  static const String webBaseUrl = "https://lumad-lingua.web.app";

  Future<void> shareWord(DictionaryEntry entry) async {
    final String text =
        '''
Check out this word from Lumad Lingua!

🌿 Indigenous Word: ${entry.indigenousWord}
🗣️ Translation: ${entry.translation}
🌍 Language: ${entry.language}
📝 Context: ${entry.usageContext}

Learn more at: $webBaseUrl/word/${entry.id}
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Indigenous Wisdom: ${entry.indigenousWord}',
      ),
    );
  }
}



