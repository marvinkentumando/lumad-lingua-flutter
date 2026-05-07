import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'local_florist':
        return Icons.local_florist;
      case 'school':
        return Icons.school;
      case 'translate':
        return Icons.translate;
      case 'record_voice_over':
        return Icons.record_voice_over;
      case 'hearing':
        return Icons.hearing;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'chat':
        return Icons.chat_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'explore':
        return Icons.explore_rounded;
      default:
        return Icons.school;
    }
  }
}



