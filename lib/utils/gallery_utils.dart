import 'package:flutter/material.dart';

class GalleryUtils {
  static IconData getIconData(String name) {
    switch (name) {
      case 'lightbulb':
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'history_edu':
      case 'history_edu_rounded':
        return Icons.history_edu_rounded;
      case 'local_fire_department':
      case 'local_fire_department_rounded':
        return Icons.local_fire_department_rounded;
      case 'auto_awesome':
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'park':
      case 'park_rounded':
        return Icons.park_rounded;
      case 'star':
      case 'star_rounded':
        return Icons.star_rounded;
      case 'shield':
      case 'shield_outlined':
        return Icons.shield_outlined;
      case 'construction':
        return Icons.construction;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'music_note':
        return Icons.music_note;
      case 'brush':
        return Icons.brush;
      case 'visibility':
        return Icons.visibility;
      default:
        return Icons.help_outline;
    }
  }

  static Color getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }
}



