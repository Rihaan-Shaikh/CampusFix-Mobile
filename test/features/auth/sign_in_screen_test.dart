import 'package:campusfix/core/widgets/campus_button.dart';
import 'package:campusfix/features/auth/presentation/auth_notifier.dart';
import 'package:campusfix/features/auth/presentation/auth_state.dart';
import 'package:campusfix/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);
  final AuthState _initialState;
  bool googleSignInCalled = false;

  @override
  AuthState build() => _initialState;

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalled = true;
    return false;
  }
}

void main() {
  group('SignInScreen layout & interaction', () {
    testWidgets('renders brand title, form fields, and sign in button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.text('Welcome to CampusFix'), findsOneWidget);
      expect(find.text('Campus Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('OR CONTINUE WITH'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('toggles password visibility icon on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('triggers inline validation when submitting empty fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('validates invalid email format and short password', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.enterText(
        find.byWidgetPredicate((w) => w is TextField && w.obscureText == true),
        '123',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error banner when authentication fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(
                const AuthUnauthenticated(
                  errorMessage: 'Invalid campus credentials provided.',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.text('Invalid campus credentials provided.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders button in loading state during authentication', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthAuthenticating()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CampusButton), findsOneWidget);
    });

    testWidgets('renders correctly on compact narrow screen without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 540 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: SignInScreen()),
        ),
      );

      expect(find.text('Welcome to CampusFix'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'triggers Google sign-in workflow when Google button is tapped',
      (tester) async {
        final fakeNotifier = _FakeAuthNotifier(const AuthUnauthenticated());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authNotifierProvider.overrideWith(() => fakeNotifier)],
            child: const MaterialApp(home: SignInScreen()),
          ),
        );

        final googleButton = find.byKey(const Key('google_sign_in_button'));
        expect(googleButton, findsOneWidget);

        await tester.tap(googleButton);
        await tester.pump();

        expect(fakeNotifier.googleSignInCalled, isTrue);
      },
    );

    testWidgets('shows informative snackbar when GitHub button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: SignInScreen())),
        ),
      );

      final githubButton = find.byKey(const Key('github_sign_in_button'));
      expect(githubButton, findsOneWidget);

      await tester.tap(githubButton);
      await tester.pump();

      expect(
        find.textContaining('GitHub OAuth requires web browser redirect'),
        findsOneWidget,
      );
    });
  });
}
