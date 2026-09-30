import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lumad_lingua/services/auth_service.dart';

class TestGoogleSignIn implements GoogleSignIn {
  GoogleSignInAccount? mockAccount;
  Object? errorToThrow;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockAccount;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthService Google Sign-In Unit Tests', () {
    test('returns null on true user cancellation (signIn returns null)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()..mockAccount = null;
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      final result = await authService.signInWithGoogle();
      expect(result, isNull);
    });

    test('returns null on PlatformException sign_in_canceled code', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: GoogleSignIn.kSignInCanceledError,
          message: 'User cancelled',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      final result = await authService.signInWithGoogle();
      expect(result, isNull);
    });

    test('returns null on PlatformException sign_in_canceled string', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: 'sign_in_canceled',
          message: 'User cancelled',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      final result = await authService.signInWithGoogle();
      expect(result, isNull);
    });

    test('returns null on PlatformException 12501 (Google API cancel code)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: '12501',
          message: 'User cancelled sign-in flow',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      final result = await authService.signInWithGoogle();
      expect(result, isNull);
    });

    test('throws Exception on PlatformException null-error', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: 'null-error',
          message: 'Host platform returned null value for non-null return value.',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('[null-error]'),
          ),
        ),
      );
    });

    test('throws Exception on native PlatformException failure (e.g. network_error)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: 'network_error',
          message: 'Connection failed',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('[network_error]: Connection failed'),
          ),
        ),
      );
    });

    test('throws Exception on native PlatformException failure (e.g. sign_in_failed)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('[sign_in_failed]: com.google.android.gms.common.api.ApiException: 10'),
          ),
        ),
      );
    });

    test('throws Exception on TypeError (Pigeon platform channel force-unwrap failure)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = TypeError();
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google sign-in failed due to native plugin response'),
          ),
        ),
      );
    });

    test('throws Exception on Null check operator used on a null value', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = Exception('Null check operator used on a null value');
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Google sign-in failed: Null check operator used on a null value'),
          ),
        ),
      );
    });

    test('rethrows FirebaseAuthException', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The credential is bad.',
        );
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            equals('invalid-credential'),
          ),
        ),
      );
    });
  });
}
