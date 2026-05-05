import 'package:flutter/foundation.dart';
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

    // 1. Cleanup old quests (>24h)
    for (final q in currentQuests) {
      if (q.isDynamic && q.id.startsWith('dyn_')) {
        try {
          final parts = q.id.split('_');
          if (parts.length >= 3) {
            final tsStr = parts[2].substring(0, 13);
            final created = DateTime.fromMillisecondsSinceEpoch(int.parse(tsStr));
            if (now.difference(created).inHours >= 24) {
              await fbService.deleteQuest(user.uid, q.id);
            }
          }
        } catch (e) {
          debugPrint("Quest cleanup error: $e");
        }
      }
    }

    // 2. Add new unique quests if needed
    final activeQuests = ref.read(dailyQuestsProvider).value ?? [];
    if (activeQuests.length >= 3) return;

    final existingTypes = activeQuests.map((q) => q.type).toSet();
    final needed = 3 - activeQuests.length;
    final timestamp = now.millisecondsSinceEpoch;
    
    final allTypes = [QuestType.flashcard, QuestType.pronunciation, QuestType.lesson];
    final availableTypes = allTypes.where((t) => !existingTypes.contains(t)).toList();

    for (int i = 0; i < needed && i < availableTypes.length; i++) {
      final type = availableTypes[i];
      Quest? quest;

      if (type == QuestType.flashcard) {
        quest = Quest(
          id: 'dyn_flash_$timestamp$i',
          title: 'Forest Memory',
          description: 'Review 5 words from the Highlands.',
          target: 5,
          reward: 15,
          type: QuestType.flashcard,
          isDynamic: true,
        );
      } else if (type == QuestType.pronunciation) {
        quest = Quest(
          id: 'dyn_mic_$timestamp$i',
          title: 'Tribal Voice',
          description: 'Record 2 phrases to preserve our dialect.',
          target: 2,
          reward: 20,
          type: QuestType.pronunciation,
          isDynamic: true,
        );
      } else if (type == QuestType.lesson) {
        quest = Quest(
          id: 'dyn_lesson_$timestamp$i',
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


