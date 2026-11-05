import 'package:share_plus/share_plus.dart';
import '../models/dictionary_entry.dart';
import '../models/community_activity.dart';

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

  Future<void> shareActivity(CommunityActivity activity) async {
    final String text =
        '''
Check out this achievement on Lumad Lingua! 🌿

${activity.emoji} ${activity.userName}: ${activity.message}

Join the movement to preserve indigenous languages & heritage:
$webBaseUrl
''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Lumad Lingua Community Update from ${activity.userName}',
      ),
    );
  }
}




