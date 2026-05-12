import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_models.dart';
import '../services/firebase_service.dart';

class UserPaginationState {
  final List<AdminUser> users;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  UserPaginationState({
    required this.users,
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });

  UserPaginationState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) {
    return UserPaginationState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class UserPaginationNotifier extends StateNotifier<UserPaginationState> {
  final FirebaseService _firebaseService;

  UserPaginationNotifier(this._firebaseService)
      : super(UserPaginationState(users: [])) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final snapshot = await _firebaseService.getUsersPaginated(
        limit: 20,
        startAfter: state.lastDoc,
      );

      final newUsers = snapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc.data(), doc.id))
          .toList();

      state = state.copyWith(
        users: [...state.users, ...newUsers],
        isLoading: false,
        hasMore: newUsers.length == 20,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error
    }
  }

  Future<void> refresh() async {
    state = UserPaginationState(users: []);
    await loadUsers();
  }
}

final adminUsersProvider =
    StateNotifierProvider<UserPaginationNotifier, UserPaginationState>((ref) {
  return UserPaginationNotifier(ref.watch(firebaseServiceProvider));
});
