import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user profile already exists
        final doc = await firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          // New user from Google, create profile
          await firestore.collection('users').doc(user.uid).set({
            'username': user.displayName ?? 'Tribe Member',
            'email': user.email,
            'location': 'Unknown',
            'tribe': 'General Learner',
            'avatar': user.photoURL ?? '👤',
            'nativeLanguage': 'English',
            'learningGoal': 'Culture',
            'role': 'learner',
            'xp': 0,
            'mistCrystals': 0,
            'streak': 0,
            'wordCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await firestore
              .collection('users')
              .doc(user.uid)
              .update({'lastLogin': FieldValue.serverTimestamp()});
        }
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) debugPrint("Google Sign-In Error: $e");
      throw Exception("Google sign-in failed: ${e.toString()}");
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Sign-In Auth Error: ${e.code} - ${e.message}");
      }
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint("Sign-In Database Error: ${e.code} - ${e.message}");
      }
      throw Exception("Database error: ${e.message}");
    } catch (e) {
      if (kDebugMode) debugPrint("Sign-In Generic Error: $e");
      throw Exception("An unexpected error occurred: ${e.toString()}");
    }
  }

  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String username, {
    String? location,
    String? tribe,
    String? avatar,
    String? nativeLanguage,
    String? learningGoal,
    String? villageCode,
    Map<String, dynamic>? assessment,
  }) async {
    try {
      // 1. Check for invitation
      String assignedRole = 'learner';
      String? assignedDialect;

      final inviteSnap = await firestore
          .collection('invitations')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      final pendingInvites = inviteSnap.docs.where((d) => d.data()['status'] == 'pending');

      if (pendingInvites.isNotEmpty) {
        final inviteData = pendingInvites.first.data();
        assignedRole = inviteData['role'] ?? 'learner';
        assignedDialect = inviteData['indigenousGroup'];
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(username);

          final profileData = {
            'username': username,
            'email': email,
            'location': location ?? 'Unknown',
            'tribe': tribe ?? 'General Learner',
            'avatar': avatar ?? '👤',
            'nativeLanguage': nativeLanguage ?? 'English',
            'learningGoal': learningGoal ?? 'Culture',
            'role': assignedRole,
            'indigenousGroup': assignedDialect,
            'xp': 0,
            'mistCrystals': 0,
            'streak': 0,
            'wordCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          };

          if (assignedRole == 'educator') {
            // Generate unique village code for new educator
            final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
            final rnd = math.Random();
            String code = '';
            bool isUnique = false;
            
            while (!isUnique) {
              code = String.fromCharCodes(
                Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
              );
              final check = await firestore.collection('users').where('villageCode', isEqualTo: code).limit(1).get();
              if (check.docs.isEmpty) isUnique = true;
            }
            profileData['villageCode'] = code;
          }

          if (assignedRole == 'learner' && villageCode != null && villageCode.isNotEmpty) {
            // Try to find educator by code
            final eduSnap = await firestore
                .collection('users')
                .where('role', isEqualTo: 'educator')
                .where('villageCode', isEqualTo: villageCode.trim().toUpperCase())
                .limit(1)
                .get();
            
            if (eduSnap.docs.isNotEmpty) {
              profileData['educatorId'] = eduSnap.docs.first.id;
            }
          }

          if (assessment != null) {
            profileData['onboardingAssessment'] = assessment;
          }

          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(profileData, SetOptions(merge: true));

          // 2. Mark invite as successful
          if (pendingInvites.isNotEmpty) {
            await pendingInvites.first.reference.update({
              'status': 'consumed',
              'consumedAt': FieldValue.serverTimestamp(),
              'userId': userCredential.user!.uid,
            });
          }
        } catch (e) {
          // Atomic Cleanup: If Firestore profile fails, delete the Auth user
          // so the user isn't stuck in a "registered but broken" state.
          await userCredential.user!.delete();
          rethrow;
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("Sign-Up Auth Error: ${e.code} - ${e.message}");
      }
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint("Sign-Up Database Error: ${e.code} - ${e.message}");
      }
      throw Exception("Database error: ${e.message}");
    } catch (e) {
      if (kDebugMode) debugPrint("Sign-Up Generic Error: $e");
      throw Exception("An unexpected error occurred: ${e.toString()}");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // 1. Delete Firestore profile
      await firestore.collection('users').doc(user.uid).delete();
      // 2. Delete Auth account
      await user.delete();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<bool> verifyPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint("Password verification failed: $e");
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;

  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});

final otherUserProfileProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) => snapshot.data());
    });



