import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/screens/login_screen.dart';
import 'package:lumad_lingua/screens/signup_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Google Authentication Widget Tests', () {
    testWidgets('LoginScreen renders Google Sign-In button and calls FakeAuthService on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        createTestWidgetApp(
          home: const LoginScreen(),
          fakeAuthService: fakeAuth,
          isLoggedIn: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();

      expect(fakeAuth.signInWithGoogleCalled, isTrue);
    });

    testWidgets('LoginScreen displays error message when Google Sign-In fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeAuthService(
        signInWithGoogleError: Exception('Google sign-in popup closed'),
      );

      await tester.pumpWidget(
        createTestWidgetApp(
          home: const LoginScreen(),
          fakeAuthService: fakeAuth,
          isLoggedIn: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeAuth.signInWithGoogleCalled, isTrue);
      expect(find.textContaining('Google sign-in popup closed'), findsOneWidget);
    });

    testWidgets('SignupScreen renders Quick Join with Google button and calls FakeAuthService on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeAuthService();

      await tester.pumpWidget(
        createTestWidgetApp(
          home: const SignupScreen(),
          fakeAuthService: fakeAuth,
          isLoggedIn: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final googleButton = find.text('Quick Join with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();

      expect(fakeAuth.signInWithGoogleCalled, isTrue);
    });

    testWidgets('SignupScreen displays error message when Quick Join with Google fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = FakeAuthService(
        signInWithGoogleError: Exception('Google sign-in network error'),
      );

      await tester.pumpWidget(
        createTestWidgetApp(
          home: const SignupScreen(),
          fakeAuthService: fakeAuth,
          isLoggedIn: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final googleButton = find.text('Quick Join with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeAuth.signInWithGoogleCalled, isTrue);
      expect(find.textContaining('Google sign-in network error'), findsOneWidget);
    });
  });
}
