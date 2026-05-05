import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artifact.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

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
