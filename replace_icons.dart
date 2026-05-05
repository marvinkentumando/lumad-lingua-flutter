// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  // Safe icons to replace with _rounded
  final safeIcons = {
    'person', 'search', 'play_arrow', 'pause', 'stop', 'home', 
    'menu_book', 'arrow_back', 'arrow_forward', 'check', 'close',
    'settings', 'notifications', 'star', 'favorite', 'history',
    'info', 'warning', 'error', 'edit', 'delete', 'add', 'remove',
    'keyboard_arrow_down', 'keyboard_arrow_up', 'keyboard_arrow_left', 'keyboard_arrow_right',
    'chevron_right', 'chevron_left', 'flag', 'mic'
  };

  int changedFiles = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;
    
    for (final icon in safeIcons) {
      final regex = RegExp('Icons\\.$icon(?!_rounded|_outlined|_sharp)');
      if (regex.hasMatch(content)) {
        content = content.replaceAll(regex, 'Icons.${icon}_rounded');
        changed = true;
      }
    }
    
    if (changed) {
      file.writeAsStringSync(content);
      changedFiles++;
      print('Updated ${file.path}');
    }
  }
  print('Total files updated: $changedFiles');
}
