import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/warrior_friend.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

final userFriendsProvider = StreamProvider<List<WarriorFriend>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).getUserFriendsStream(user.uid);
});

final pendingFriendRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(firebaseServiceProvider)
      .getPendingFriendRequestsStream(user.uid);
});

final searchUsersProvider =
    FutureProvider.family<List<WarriorFriend>, String>((ref, query) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null || query.trim().isEmpty) return [];
  return ref
      .read(firebaseServiceProvider)
      .searchUsers(query, user.uid);
});
