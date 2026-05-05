import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

enum UserRole { learner, contributor, validator, educator, admin }

class RoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final profile = ref.watch(userProfileProvider).value;
    final roleString = profile?['role']?.toString().toLowerCase();

    switch (roleString) {
      case 'admin':
        return UserRole.admin;
      case 'validator':
        return UserRole.validator;
      case 'contributor':
        return UserRole.contributor;
      case 'educator':
        return UserRole.educator;
      default:
        return UserRole.learner;
    }
  }

  void setRole(UserRole role) => state = role;
}

final roleProvider = NotifierProvider<RoleNotifier, UserRole>(RoleNotifier.new);


