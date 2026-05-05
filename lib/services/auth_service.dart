import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(username);

          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'username': username,
                'email': email,
                'location': location ?? 'Unknown',
                'tribe': tribe ?? 'General Learner',
                'avatar': avatar ?? '👤',
                'nativeLanguage': nativeLanguage ?? 'English',
                'learningGoal': learningGoal ?? 'Culture',
                'role': 'learner',
                'xp': 0,
                'mistCrystals': 0,
                'streak': 0,
                'wordCount': 0,
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
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


