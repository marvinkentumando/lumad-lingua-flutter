import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContributionImpact {
  final int studentsHelpedToday;
  final int totalReach;
  final double accuracyRate;
  final int validatedWords;

  ContributionImpact({
    required this.studentsHelpedToday,
    required this.totalReach,
    required this.accuracyRate,
    required this.validatedWords,
  });
}

final contributionImpactProvider = StreamProvider<ContributionImpact>((ref) {
  // In a real app, this would stream from Firestore tracking collections
  // For now, returning mocked data that updates periodically
  return Stream.periodic(const Duration(hours: 1), (count) {
    return ContributionImpact(
      studentsHelpedToday: 450 + (count % 50),
      totalReach: 12540,
      accuracyRate: 0.98,
      validatedWords: 156,
    );
  }).asBroadcastStream();
});
