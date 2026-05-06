import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/role_provider.dart';
import 'learner_profile_screen.dart';
import 'staff_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    if (currentRole == UserRole.learner) {
      return const LearnerProfileScreen();
    } else {
      return const StaffProfileScreen();
    }
  }
}
