import 'package:campusfix/features/auth/data/models/user_model.dart';
import 'package:campusfix/features/auth/presentation/auth_notifier.dart';
import 'package:campusfix/features/auth/presentation/auth_state.dart';
import 'package:campusfix/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);
  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

void main() {
  group('ProfileScreen appearance & layout', () {
    testWidgets('renders unauthenticated state and interactive sign-in', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(const AuthUnauthenticated()),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      expect(find.text('Unauthenticated Session'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets(
      'renders authenticated state with user role and sign-out button',
      (tester) async {
        const testUser = UserModel(
          id: 'usr_123',
          name: 'Alex Morgan',
          email: 'alex@campus.edu',
          role: 'ADMIN',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(const AuthAuthenticated(testUser)),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        expect(find.text('Alex Morgan'), findsOneWidget);
        expect(find.text('ADMIN'), findsOneWidget);
        expect(find.text('alex@campus.edu'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets(
      'renders About CampusFix section without overflow on narrow width',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 600 * 2);
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
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        expect(find.text('About CampusFix'), findsOneWidget);
        expect(find.text('Release Version'), findsOneWidget);
        expect(find.text('1.0.0 (Build 1)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
