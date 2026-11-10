import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';

enum UserRole { learner, staff, educator, admin }

final isSimulatingProvider = StateProvider<bool>((ref) => false);

class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final isSimulating = ref.watch(isSimulatingProvider);
    final role = _computeRole(isSimulating);
    HapticService.currentRole = role.toString().split('.').last;
    return role;
  }

  UserRole _computeRole(bool isSimulating) {
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

  void setRole(UserRole role) {
    state = role;
    HapticService.currentRole = role.toString().split('.').last;
  }
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);



