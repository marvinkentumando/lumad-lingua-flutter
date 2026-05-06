import 'dart:io';

void main() {
  // Fix learner_profile_screen.dart
  final learnerFile = File('lib/screens/learner_profile_screen.dart');
  var learnerCode = learnerFile.readAsStringSync();
  learnerCode = learnerCode.replaceAll('class ProfileScreen', 'class LearnerProfileScreen');
  learnerCode = learnerCode.replaceAll('_buildContributionImpact', '_unusedImpact'); // prevent usage
  learnerFile.writeAsStringSync(learnerCode);

  // Fix staff_profile_screen.dart
  final staffFile = File('lib/screens/staff_profile_screen.dart');
  var staffCode = staffFile.readAsStringSync();
  staffCode = staffCode.replaceAll('class ProfileScreen', 'class StaffProfileScreen');
  staffFile.writeAsStringSync(staffCode);

  // Re-write profile_screen.dart to be just a router
  final routerCode = '''
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
''';
  File('lib/screens/profile_screen.dart').writeAsStringSync(routerCode);
}
