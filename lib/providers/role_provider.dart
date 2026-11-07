import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

enum UserRole { learner, staff, educator, admin }

final isSimulatingProvider = StateProvider<bool>((ref) => false);

class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final isSimulating = ref.watch(isSimulatingProvider);
    if (isSimulating) return UserRole.learner;

    final claimRole = ref.watch(userRoleClaimProvider).valueOrNull?.toLowerCase();
    final profileRole = ref.watch(userProfileProvider).valueOrNull?['role']?.toString().toLowerCase();

    final roleString = (claimRole != null && claimRole.isNotEmpty) ? claimRole : profileRole;

    switch (roleString) {
      case 'admin':
        return UserRole.admin;
      case 'validator':
      case 'contributor':
      case 'staff':
      case 'researcher':
        return UserRole.staff;
      case 'educator':
        return UserRole.educator;
      default:
        return UserRole.learner;
    }
  }

  void setRole(UserRole role) => state = role;
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);

final isRoleLoadingProvider = Provider<bool>((ref) {
  final isSimulating = ref.watch(isSimulatingProvider);
  if (isSimulating) return false;

  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;

  final profileState = ref.watch(userProfileProvider);
  final claimState = ref.watch(userRoleClaimProvider);

  return profileState.isLoading && claimState.isLoading;
});



