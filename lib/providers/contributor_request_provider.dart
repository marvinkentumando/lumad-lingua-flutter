import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/contributor_request.dart';
import 'package:firebase_auth/firebase_auth.dart';

final contributorRequestsProvider = StreamProvider<List<ContributorRequest>>((
  ref,
) {
  return ref.read(firebaseServiceProvider).getContributorRequests();
});

final pendingRequestsCountProvider = StreamProvider<int>((ref) {
  return ref.read(firebaseServiceProvider).getPendingContributorRequestsCount();
});

final pendingContributorRequestProvider = StreamProvider<ContributorRequest?>((
  ref,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return ref
      .read(firebaseServiceProvider)
      .getPendingContributorRequest(user.uid);
});



