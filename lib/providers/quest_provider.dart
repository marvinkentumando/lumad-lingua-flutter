import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final quests = ref.read(dailyQuestsProvider).value ?? [];
    for (final quest in quests) {
      if (quest.type == type && !quest.isCompleted) {
        await ref
            .read(firebaseServiceProvider)
            .updateQuestProgress(user.uid, quest.id, amount);
      }
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
    final currentQuests = ref.read(dailyQuestsProvider).value ?? [];
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final types = [QuestType.flashcard, QuestType.pronunciation, QuestType.lesson];
    final todayIds = types.map((t) => 'dyn_${t.name}_$dateStr').toSet();

    // 1. Cleanup old or duplicate quests (Aggressive purge)
    await fbService.purgeLegacyQuests(user.uid, todayIds);

    // 2. Add new unique quests for today
    // We want 3 specific types of quests every day
    
    for (final type in types) {
      final questId = 'dyn_${type.name}_$dateStr';
      
      // Check if this specific quest already exists in currentQuests
      final exists = currentQuests.any((q) => q.id == questId);
      if (exists) continue;

      Quest? quest;
      if (type == QuestType.flashcard) {
        quest = Quest(
          id: questId,
          title: 'Forest Memory',
          description: 'Review 5 words from the Highlands.',
          target: 5,
          reward: 15,
          type: QuestType.flashcard,
          isDynamic: true,
        );
      } else if (type == QuestType.pronunciation) {
        quest = Quest(
          id: questId,
          title: 'Tribal Voice',
          description: 'Record 2 phrases to preserve our dialect.',
          target: 2,
          reward: 20,
          type: QuestType.pronunciation,
          isDynamic: true,
        );
      } else if (type == QuestType.lesson) {
        quest = Quest(
          id: questId,
          title: 'Path of Wisdom',
          description: 'Complete 1 lesson to advance your journey.',
          target: 1,
          reward: 30,
          type: QuestType.lesson,
          isDynamic: true,
        );
      }

      if (quest != null) {
        await fbService.addQuest(user.uid, quest);
      }
    }
  }
}

final questActionProvider = NotifierProvider<QuestNotifier, void>(
  () => QuestNotifier(),
);


