import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/daily_challenge.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

final dailyChallengeProvider = FutureProvider<DailyChallenge?>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Try to get today's challenge
  var challenge = await firebaseService.getDailyChallenge(today);

  if (challenge == null) {
    // Generate new one if it doesn't exist
    final randomTasks = await firebaseService.getRandomTasks(5);
    if (randomTasks.isEmpty) return null;

    challenge = DailyChallenge(
      id: today,
      tasks: randomTasks,
      xpReward: 50,
      crystalReward: 10,
    );

    // Save it so all users get the same challenge for today
    await firebaseService.saveDailyChallenge(challenge);
  }

  return challenge;
});

final dailyChallengeStatusProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null) return false;

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final completed = List<String>.from(userProfile['completedChallenges'] ?? []);

  return completed.contains(today);
});

class DailyChallengeNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  DailyChallengeNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> completeChallenge(DailyChallenge challenge) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception("User not logged in");

      await ref.read(firebaseServiceProvider).completeDailyChallenge(
        user.uid,
        challenge.id,
        challenge.xpReward,
        challenge.crystalReward,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dailyChallengeCompletionProvider =
    StateNotifierProvider<DailyChallengeNotifier, AsyncValue<void>>((ref) {
      return DailyChallengeNotifier(ref);
    });
