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

    test('throws Exception with diagnostic hint on TypeError (Pigeon force-unwrap null check)', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = TypeError();
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Check Google Play Services, app signing certificate (SHA-1), and OAuth configuration'),
          ),
        ),
      );
    });

    test('throws Exception with diagnostic hint on Null check operator used on a null value', () async {
      final fakeGoogleSignIn = TestGoogleSignIn()
        ..errorToThrow = Exception('Null check operator used on a null value');
      final authService = AuthService(googleSignIn: fakeGoogleSignIn);

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Check Google Play Services, app signing certificate (SHA-1), and OAuth configuration'),
          ),
        ),
      );
    });
  });
}
