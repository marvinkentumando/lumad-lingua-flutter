import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';

class SavedWordsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return {};

    final bookmarksAsync = ref.watch(userBookmarksStreamProvider(user.uid));

    return bookmarksAsync.maybeWhen(
      data: (ids) => ids.toSet(),
      // Use maybeData to preserve state if it's already there (for subsequent builds)
      orElse: () => <String>{},
    );
  }

  Future<void> toggleSave(
    String wordId, {
    required BuildContext context,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save words'),
          backgroundColor: AppColors.semanticRed,
        ),
      );
      return;
    }

    final isCurrentlySaved = state.contains(wordId);

    if (isCurrentlySaved) {
      HapticService.light();
    } else {
      HapticService.success();
    }

    // Optimistic Update
    final previousState = state;
    if (isCurrentlySaved) {
      state = {...state}..remove(wordId);
    } else {
      state = {...state, wordId};
    }

    try {
      await ref.read(firebaseServiceProvider).toggleBookmark(user.uid, wordId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlySaved
                  ? 'Removed from saved words'
                  : 'Word saved successfully!',
            ),
            backgroundColor: isCurrentlySaved
                ? AppColors.forest700
                : AppColors.semanticBlue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Rollback on error
      state = previousState;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save word: ${e.toString()}'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  bool isSaved(String wordId) => state.contains(wordId);
}

final savedWordsProvider = NotifierProvider<SavedWordsNotifier, Set<String>>(
  () {
    return SavedWordsNotifier();
  },
);



