import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_service.dart';

class UploadQueueService extends Notifier<bool> {
  OfflineService get _offlineService => ref.read(offlineServiceProvider);

  StreamSubscription? _connectivitySubscription;

  @override
  bool build() {
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

    return false; // isSyncing
  }

  bool get isSyncing => state;

  Future<void> processQueue() async {
    if (state) return;

    final drafts = await _offlineService.getDraftLessons();
    if (drafts.isEmpty) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    state = true;

    debugPrint('Starting Upload Queue processing: ${drafts.length} items');

    for (var lesson in drafts) {
      try {
        // await _firebaseService.saveLesson(lesson);

        // Simulate upload
        await Future.delayed(const Duration(seconds: 1));

        await _offlineService.removeDraftLesson(lesson.id);
        debugPrint('Successfully synced lesson: ${lesson.id}');
      } catch (e) {
        debugPrint('Failed to sync lesson ${lesson.id}: $e');
      }
    }

    state = false;
  }
}

final uploadQueueProvider = NotifierProvider<UploadQueueService, bool>(() {
  return UploadQueueService();
});



