import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duel_models.dart';
import '../services/duel_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class DuelSessionState {
  final String? matchId;
  final DuelMatch? match;
  final bool isLoading;
  final String? error;

  DuelSessionState({
    this.matchId,
    this.match,
    this.isLoading = false,
    this.error,
  });

  DuelSessionState copyWith({
    String? matchId,
    DuelMatch? match,
    bool? isLoading,
    String? error,
  }) {
    return DuelSessionState(
      matchId: matchId ?? this.matchId,
      match: match ?? this.match,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DuelSessionNotifier extends Notifier<DuelSessionState> {
  StreamSubscription<DuelMatch?>? _subscription;

  @override
  DuelSessionState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return DuelSessionState();
  }

  Future<void> joinOrCreateMatch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userProfile = ref.read(userProfileProvider).value ?? {};
      final matchId = await ref.read(duelServiceProvider).findOrCreateMatch(
        userProfile: userProfile,
      );

      _subscription?.cancel();
      _subscription = ref.read(duelServiceProvider).streamMatch(matchId).listen((match) {
        state = state.copyWith(matchId: matchId, match: match, isLoading: false);
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyDamage(String targetPlayerId, double damage) async {
    if (state.matchId == null) return;
    await ref.read(duelServiceProvider).applyDamage(state.matchId!, targetPlayerId, damage);
  }

  Future<void> forfeit() async {
    if (state.matchId == null) return;
    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId != null) {
      await ref.read(duelServiceProvider).forfeitMatch(state.matchId!, userId);
    }
  }

  void reset() {
    _subscription?.cancel();
    state = DuelSessionState();
  }
}

final duelSessionProvider = NotifierProvider<DuelSessionNotifier, DuelSessionState>(() {
  return DuelSessionNotifier();
});
