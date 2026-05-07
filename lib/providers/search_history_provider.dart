import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/offline_service.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const int _maxItems = 10;

  @override
  List<String> build() {
    final box = Hive.box<String>(OfflineService.searchHistoryBoxName);
    // Return newest first
    return box.values.toList().reversed.toList();
  }

  Future<void> addTerm(String term) async {
    final cleanTerm = term.trim().toLowerCase();
    if (cleanTerm.isEmpty) return;

    final box = Hive.box<String>(OfflineService.searchHistoryBoxName);
    
    // Remove if already exists to move to top
    final Map<dynamic, String> entries = box.toMap();
    dynamic existingKey;
    entries.forEach((key, value) {
      if (value.toLowerCase() == cleanTerm) {
        existingKey = key;
      }
    });

    if (existingKey != null) {
      await box.delete(existingKey);
    }

    // Add new term
    await box.add(term.trim());

    // Enforce limit
    if (box.length > _maxItems) {
      final firstKey = box.keys.first;
      await box.delete(firstKey);
    }

    state = box.values.toList().reversed.toList();
  }

  Future<void> removeTerm(String term) async {
    final box = Hive.box<String>(OfflineService.searchHistoryBoxName);
    final Map<dynamic, String> entries = box.toMap();
    
    dynamic targetKey;
    entries.forEach((key, value) {
      if (value == term) {
        targetKey = key;
      }
    });

    if (targetKey != null) {
      await box.delete(targetKey);
      state = box.values.toList().reversed.toList();
    }
  }

  Future<void> clearAll() async {
    final box = Hive.box<String>(OfflineService.searchHistoryBoxName);
    await box.clear();
    state = [];
  }
}

final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);
