import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lumad_lingua/services/offline_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/models/lesson.dart';

class SyncConflict {
  final String lessonId;
  final String lessonTitle;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;

  SyncConflict({
    required this.lessonId,
    required this.lessonTitle,
    required this.localData,
    required this.serverData,
  });
}

class UploadQueueState {
  final bool isSyncing;
  final List<SyncConflict> conflicts;

  UploadQueueState({
    this.isSyncing = false,
    this.conflicts = const [],
  });

  UploadQueueState copyWith({
    bool? isSyncing,
    List<SyncConflict>? conflicts,
  }) {
    return UploadQueueState(
      isSyncing: isSyncing ?? this.isSyncing,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

class UploadQueueService extends Notifier<UploadQueueState> {
  OfflineService get _offlineService => ref.read(offlineServiceProvider);

  StreamSubscription? _connectivitySubscription;

  @override
  UploadQueueState build() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        processQueue();
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    // Start processing if online
    Future.microtask(() => processQueue());

    return UploadQueueState();
  }

  bool get isSyncing => state.isSyncing;

  Future<void> processQueue() async {
    if (state.isSyncing) return;

    final drafts = await _offlineService.getDraftLessons();
    final progressItems = await _offlineService.getAllOfflineProgress();
    
    if (drafts.isEmpty && progressItems.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    state = state.copyWith(isSyncing: true);

    debugPrint('Starting Upload Queue processing: ${drafts.length} drafts, ${progressItems.length} progress items');

    // Process Drafts (Lessons)
    for (var lesson in drafts) {
      try {
        // await ref.read(firebaseServiceProvider).saveLesson(lesson);
        await Future.delayed(const Duration(seconds: 1)); // Simulate
        await _offlineService.removeDraftLesson(lesson.id);
        debugPrint('Successfully synced lesson: ${lesson.id}');
      } catch (e) {
        debugPrint('Failed to sync lesson ${lesson.id}: $e');
      }
    }

    // Process Progress Items
    final List<SyncConflict> newConflicts = [];
    
    for (var progress in progressItems) {
      final lessonId = progress['lessonId'];
      try {
        final serverProgress = await _fetchServerProgress(lessonId);
        
        if (serverProgress != null) {
          // Conflict detection
          final localStars = progress['stars'] as int;
          final serverStars = serverProgress['stars'] as int;
          
          if (localStars != serverStars || progress['score'] != serverProgress['bestScore']) {
            // It's a conflict if scores are different
            final lesson = await _offlineService.getCachedLessons().then(
              (list) => list.firstWhere((l) => l.id == lessonId, orElse: () => Lesson(id: lessonId, title: 'Unknown Lesson', description: '', category: '', language: '', level: 1, unitNumber: 1, tasks: []))
            );
            
            newConflicts.add(SyncConflict(
              lessonId: lessonId,
              lessonTitle: lesson.title,
              localData: progress,
              serverData: serverProgress,
            ));
            continue; // Wait for resolution
          }
        }
        
        // No conflict or server is behind, just sync
        await _syncProgress(progress);
        await _offlineService.removeOfflineProgress(lessonId);
      } catch (e) {
        debugPrint('Failed to sync progress for $lessonId: $e');
      }
    }

    state = state.copyWith(isSyncing: false, conflicts: [...state.conflicts, ...newConflicts]);
  }

  Future<Map<String, dynamic>?> _fetchServerProgress(String lessonId) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return null;
    return ref.read(firebaseServiceProvider).getUserLessonProgress(user.uid, lessonId);
  }

  Future<void> _syncProgress(Map<String, dynamic> progress) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    await ref.read(firebaseServiceProvider).completeLesson(
      user.uid,
      progress['lessonId'],
      progress['score'],
      progress['stars'],
      taskPerformance: Map<String, int>.from(progress['taskPerformance'] ?? {}),
      bonusXp: progress['bonusXp'] ?? 0,
    );
  }

  Future<void> resolveConflict(String lessonId, bool keepLocal) async {
    final conflict = state.conflicts.firstWhere((c) => c.lessonId == lessonId);
    
    if (keepLocal) {
      await _syncProgress(conflict.localData);
    }
    
    await _offlineService.removeOfflineProgress(lessonId);
    state = state.copyWith(
      conflicts: state.conflicts.where((c) => c.lessonId != lessonId).toList(),
    );
  }
}

final uploadQueueProvider = NotifierProvider<UploadQueueService, UploadQueueState>(() {
  return UploadQueueService();
});
