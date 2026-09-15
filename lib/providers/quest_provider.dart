import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quest.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

final dailyQuestsProvider = StreamProvider<List<Quest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return ref.watch(firebaseServiceProvider).getUserQuests(user.uid);
});

class QuestNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> updateProgress(QuestType type, int amount) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final questsAsync = ref.read(dailyQuestsProvider);
    final quests = questsAsync.value ?? [];
    
    // Use a batch update if possible (though updateQuestProgress is individual)
    // To minimize awaits, we can trigger all updates and then await them
    final updateFutures = <Future>[];
    
    for (final quest in quests) {
      if (quest.type == type && !quest.isCompleted && !quest.isClaimed) {
        updateFutures.add(
          ref.read(firebaseServiceProvider).updateQuestProgress(
                user.uid,
                quest.id,
                amount,
              ),
        );
      }
    }
    
    if (updateFutures.isNotEmpty) {
      await Future.wait(updateFutures);
    }
  }

  Future<void> claimReward(Quest quest) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    if (quest.isCompleted && !quest.isClaimed) {
      await ref
          .read(firebaseServiceProvider)
          .claimQuestReward(user.uid, quest.id, quest.reward);

      // Handle Quest Chain
      if (quest.nextQuestId != null) {
        final newQuest = Quest(
          id: quest.nextQuestId!,
          title: '${quest.title} II',
          description: 'Keep going! Double the effort, increased rewards.',
          target: quest.target * 2,
          reward: (quest.reward * 1.5).round(),
          type: quest.type,
          isDynamic: true,
          metadata: quest.metadata,
        );
        await ref.read(firebaseServiceProvider).addQuest(user.uid, newQuest);
      }
    }
  }

  Future<void> generateDynamicQuests() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final fbService = ref.read(firebaseServiceProvider);
    final profile = ref.read(userProfileProvider).value;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

    // Check if quests were already generated today to save on Firestore writes
    final lastGen = (profile?['lastQuestGeneration'] as Timestamp?)?.toDate();
    if (lastGen != null) {
      final lastGenDate = DateTime(lastGen.year, lastGen.month, lastGen.day);
      if (lastGenDate.isAtSameMomentAs(todayDate)) {
        return;
      }
    }

    final types = [
      QuestType.flashcard,
      QuestType.pronunciation,
      QuestType.lesson,
      QuestType.duel,
    ];
    final todayIds = types.map((t) => 'dyn_${t.name}_$dateStr').toSet();

    // 1. Cleanup old dynamic quests
    await fbService.purgeLegacyQuests(user.uid, todayIds);

    // 2. Add new unique quests for today with variety based on day of month
    final dayOffset = now.day;
    for (final type in types) {
      final questId = 'dyn_${type.name}_$dateStr';
      Quest? quest;

      switch (type) {
        case QuestType.flashcard:
          final varieties = [
            {'title': 'Forest Memory', 'desc': 'Review 5 words from the Highlands.', 'target': 5, 'reward': 15},
            {'title': 'Ancient Echoes', 'desc': 'Review 8 words to sharpen your mind.', 'target': 8, 'reward': 25},
            {'title': 'Quick Recall', 'desc': 'Perfect 3 flashcards in a row.', 'target': 3, 'reward': 10},
          ];
          final v = varieties[dayOffset % varieties.length];
          quest = Quest(
            id: questId,
            title: v['title'] as String,
            description: v['desc'] as String,
            target: v['target'] as int,
            reward: v['reward'] as int,
            type: QuestType.flashcard,
            isDynamic: true,
          );
          break;
        case QuestType.pronunciation:
          final varieties = [
            {'title': 'Tribal Voice', 'desc': 'Record 2 phrases to preserve our dialect.', 'target': 2, 'reward': 20},
            {'title': 'Oral Tradition', 'desc': 'Share 3 recordings from your region.', 'target': 3, 'reward': 30},
            {'title': 'Clear Chant', 'desc': 'Record 1 new term with perfect clarity.', 'target': 1, 'reward': 15},
          ];
          final v = varieties[dayOffset % varieties.length];
          quest = Quest(
            id: questId,
            title: v['title'] as String,
            description: v['desc'] as String,
            target: v['target'] as int,
            reward: v['reward'] as int,
            type: QuestType.pronunciation,
            isDynamic: true,
          );
          break;
        case QuestType.lesson:
          final varieties = [
            {'title': 'Path of Wisdom', 'desc': 'Complete 1 lesson to advance your journey.', 'target': 1, 'reward': 30},
            {'title': 'Scholar\'s Trail', 'desc': 'Complete 2 lessons today.', 'target': 2, 'reward': 50},
            {'title': 'Ritual Master', 'desc': 'Achieve 3 stars in any lesson.', 'target': 1, 'reward': 40},
          ];
          final v = varieties[dayOffset % varieties.length];
          quest = Quest(
            id: questId,
            title: v['title'] as String,
            description: v['desc'] as String,
            target: v['target'] as int,
            reward: v['reward'] as int,
            type: QuestType.lesson,
            isDynamic: true,
          );
          break;
        case QuestType.duel:
          final varieties = [
            {'title': 'Warrior Challenge', 'desc': 'Win 1 Lingua Duel against a peer.', 'target': 1, 'reward': 50},
            {'title': 'Tribe Protector', 'desc': 'Participate in 3 duels.', 'target': 3, 'reward': 75},
            {'title': 'Swift Strike', 'desc': 'Win a duel with more than 50% HP.', 'target': 1, 'reward': 60},
          ];
          final v = varieties[dayOffset % varieties.length];
          quest = Quest(
            id: questId,
            title: v['title'] as String,
            description: v['desc'] as String,
            target: v['target'] as int,
            reward: v['reward'] as int,
            type: QuestType.duel,
            isDynamic: true,
          );
          break;
        case QuestType.xp:
          break;
      }

      if (quest != null) {
        await fbService.addQuest(user.uid, quest);
      }
    }

    // 3. Update the last generation timestamp
    await fbService.updateUserProfile(user.uid, {
      'lastQuestGeneration': FieldValue.serverTimestamp(),
    });
  }
}

final questActionProvider = NotifierProvider<QuestNotifier, void>(
  () => QuestNotifier(),
);



