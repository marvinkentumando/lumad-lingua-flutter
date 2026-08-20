import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artifact.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'student_provider.dart';

final userArtifactsProvider = StreamProvider<List<Artifact>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(firebaseServiceProvider).getUserArtifacts(user.uid);
});

final otherUserArtifactsProvider = StreamProvider.family<List<Artifact>, String>((ref, userId) {
  return ref.watch(firebaseServiceProvider).getUserArtifacts(userId);
});

final artifactStatsProvider = Provider((ref) {
  final artifacts = ref.watch(userArtifactsProvider).value ?? [];
  final earnedCount = artifacts.where((a) => a.isEarned).length;
  final totalCount = artifacts.length;

  return {'earned': earnedCount, 'total': totalCount};
});

class ArtifactProgressNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> syncArtifactProgress() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final student = ref.read(studentProvider);
    final artifactsAsync = ref.read(userArtifactsProvider);
    final artifacts = artifactsAsync.value ?? [];

    for (final artifact in artifacts) {
      if (artifact.isEarned) continue;

      int progress = 0;
      switch (artifact.requirementType) {
        case ArtifactRequirementType.xp:
          progress = student.xp;
          break;
        case ArtifactRequirementType.lessons:
          progress = student.lessonProgress.values.where((p) => p['completed'] == true).length;
          break;
        case ArtifactRequirementType.words:
          // Mastered words count
          final wordsCount = ref.read(masteredWordsCountProvider(user.uid)).value ?? 0;
          progress = wordsCount;
          break;
        case ArtifactRequirementType.streak:
          progress = student.dailyStreak;
          break;
        case ArtifactRequirementType.mistCrystals:
          progress = student.mistCrystals;
          break;
      }

      if (progress > artifact.currentProgress) {
        final isNewlyEarned = progress >= artifact.targetValue;
        await ref.read(firebaseServiceProvider).updateArtifactProgress(
              user.uid,
              artifact.id,
              progress,
              isEarned: isNewlyEarned,
            );
        
        if (isNewlyEarned) {
          // Add notification
          await ref.read(firebaseServiceProvider).addNotification(user.uid, {
            'title': 'New Artifact Recovered! 🏺',
            'message': 'You have recovered the ${artifact.title}. Visit the archives to see it!',
            'type': 'achievement',
          });
        }
      }
    }
  }
}

final artifactProgressProvider = NotifierProvider<ArtifactProgressNotifier, void>(() {
  return ArtifactProgressNotifier();
});



