import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../models/lesson.dart';
import '../models/lesson_task.dart';
import '../models/dictionary_entry.dart';
import '../models/artifact.dart';

class OfflineService {
  static const String lessonsBoxName = 'offline_lessons';
  static const String dictionaryBoxName = 'offline_dictionary';
  static const String artifactsBoxName = 'offline_artifacts';
  static const String draftLessonsBoxName = 'draft_lessons';
  static const String searchHistoryBoxName = 'search_history';
  static const String progressBoxName = 'offline_progress';

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
      _safeRegisterAdapter(ArtifactTierAdapter());
      _safeRegisterAdapter(ArtifactRequirementTypeAdapter());
      _safeRegisterAdapter(ArtifactAdapter());

      // Pre-open boxes for performance
      await Hive.openBox<Lesson>(lessonsBoxName);
      await Hive.openBox<DictionaryEntry>(dictionaryBoxName);
      await Hive.openBox<Artifact>(artifactsBoxName);
      await Hive.openBox<Lesson>(draftLessonsBoxName);
      await Hive.openBox<String>(searchHistoryBoxName);
      await Hive.openBox<Map>(progressBoxName);

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

  Future<DictionaryEntry?> getRandomCachedWord() async {
    final box = await _getBox<DictionaryEntry>(dictionaryBoxName);
    if (box.isEmpty) return null;
    final random = math.Random();
    final index = random.nextInt(box.length);
    return box.getAt(index);
  }

  // Artifact Methods
  Future<void> saveArtifacts(List<Artifact> artifacts) async {
    final box = await _getBox<Artifact>(artifactsBoxName);
    final Map<String, Artifact> artifactMap = {for (var a in artifacts) a.id: a};
    await box.putAll(artifactMap);
  }

  Future<List<Artifact>> getCachedArtifacts() async {
    final box = await _getBox<Artifact>(artifactsBoxName);
    return box.values.toList();
  }

  Future<int> getArtifactCount() async {
    final box = await _getBox<Artifact>(artifactsBoxName);
    return box.length;
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

  // Progress Methods
  Future<void> saveOfflineProgress(String lessonId, Map<String, dynamic> progress) async {
    final box = await _getBox<Map>(progressBoxName);
    await box.put(lessonId, progress);
  }

  Future<Map<String, dynamic>?> getOfflineProgress(String lessonId) async {
    final box = await _getBox<Map>(progressBoxName);
    final data = box.get(lessonId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<List<Map<String, dynamic>>> getAllOfflineProgress() async {
    final box = await _getBox<Map>(progressBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> removeOfflineProgress(String lessonId) async {
    final box = await _getBox<Map>(progressBoxName);
    await box.delete(lessonId);
  }

  Future<void> clearCache() async {
    final lessonBox = await _getBox<Lesson>(lessonsBoxName);
    final dictionaryBox = await _getBox<DictionaryEntry>(dictionaryBoxName);
    final artifactBox = await _getBox<Artifact>(artifactsBoxName);
    await lessonBox.clear();
    await dictionaryBox.clear();
    await artifactBox.clear();
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

final offlineArtifactCountProvider = FutureProvider<int>((ref) {
  return ref.watch(offlineServiceProvider).getArtifactCount();
});

final cachedArtifactsProvider = FutureProvider<List<Artifact>>((ref) {
  return ref.watch(offlineServiceProvider).getCachedArtifacts();
});



