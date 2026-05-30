import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lesson.dart';
import '../models/lesson_task.dart';
import '../models/dictionary_entry.dart';

class OfflineService {
  static const String lessonsBoxName = 'offline_lessons';
  static const String dictionaryBoxName = 'offline_dictionary';
  static const String draftLessonsBoxName = 'draft_lessons';
  static const String searchHistoryBoxName = 'search_history';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // Register Adapters (ignore if already registered)
      _safeRegisterAdapter(PartOfSpeechAdapter());
      _safeRegisterAdapter(ValidationStatusAdapter());
      _safeRegisterAdapter(DictionaryEntryAdapter());
      _safeRegisterAdapter(LessonAdapter());
      _safeRegisterAdapter(TaskTypeAdapter());
      _safeRegisterAdapter(LessonTaskAdapter());

      // Pre-open boxes for performance
      await Hive.openBox<Lesson>(lessonsBoxName);
      await Hive.openBox<DictionaryEntry>(dictionaryBoxName);
      await Hive.openBox<Lesson>(draftLessonsBoxName);
      await Hive.openBox<String>(searchHistoryBoxName);

      _initialized = true;
    } catch (e) {
      debugPrint("OfflineService init error: $e");
      // Don't rethrow, let the lazy loading handle it if possible
    }
  }

  void _safeRegisterAdapter<T>(TypeAdapter<T> adapter) {
    try {
      Hive.registerAdapter(adapter);
    } catch (e) {
      // Already registered or other error
    }
  }

  Future<Box<T>> _getBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }

  // Lesson Methods
  Future<void> saveLessons(List<Lesson> lessons) async {
    final box = await _getBox<Lesson>(lessonsBoxName);
    final Map<String, Lesson> lessonMap = {for (var l in lessons) l.id: l};
    await box.putAll(lessonMap);
  }

  Future<List<Lesson>> getCachedLessons() async {
    final box = await _getBox<Lesson>(lessonsBoxName);
    return box.values.toList();
  }

  Stream<List<Lesson>> watchCachedLessons() async* {
    final box = await _getBox<Lesson>(lessonsBoxName);
    yield box.values.toList();
    yield* box.watch().map((_) => box.values.toList());
  }

  // Dictionary Methods
  Future<void> saveDictionaryEntries(List<DictionaryEntry> entries) async {
    final box = await _getBox<DictionaryEntry>(dictionaryBoxName);
    final Map<String, DictionaryEntry> entryMap = {
      for (var e in entries) e.id: e,
    };
    await box.putAll(entryMap);
  }

  Future<List<DictionaryEntry>> getCachedDictionary() async {
    final box = await _getBox<DictionaryEntry>(dictionaryBoxName);
    return box.values.toList();
  }

  // Draft Methods (Upload Queue)
  Future<void> saveDraftLesson(Lesson lesson) async {
    final box = await _getBox<Lesson>(draftLessonsBoxName);
    await box.put(lesson.id, lesson);
  }

  Future<List<Lesson>> getDraftLessons() async {
    final box = await _getBox<Lesson>(draftLessonsBoxName);
    return box.values.toList();
  }

  Future<void> removeDraftLesson(String id) async {
    final box = await _getBox<Lesson>(draftLessonsBoxName);
    await box.delete(id);
  }

  Future<void> clearCache() async {
    final lessonBox = await _getBox<Lesson>(lessonsBoxName);
    final dictionaryBox = await _getBox<DictionaryEntry>(dictionaryBoxName);
    await lessonBox.clear();
    await dictionaryBox.clear();
  }

  Future<int> getLessonCount() async {
    final box = await _getBox<Lesson>(lessonsBoxName);
    return box.length;
  }

  Future<int> getDictionaryCount() async {
    final box = await _getBox<DictionaryEntry>(dictionaryBoxName);
    return box.length;
  }
}

final offlineServiceProvider = Provider((ref) => OfflineService());

final offlineLessonCountProvider = FutureProvider<int>((ref) {
  return ref.watch(offlineServiceProvider).getLessonCount();
});

final offlineDictionaryCountProvider = FutureProvider<int>((ref) {
  return ref.watch(offlineServiceProvider).getDictionaryCount();
});



