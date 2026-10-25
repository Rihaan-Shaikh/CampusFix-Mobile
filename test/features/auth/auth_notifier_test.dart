import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/features/auth/data/models/user_model.dart';
import 'package:campusfix/features/auth/data/repositories/auth_repository.dart';
import 'package:campusfix/features/auth/presentation/auth_notifier.dart';
import 'package:campusfix/features/auth/presentation/auth_state.dart';
import 'package:campusfix/features/auth/data/services/google_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockGoogleAuthService implements GoogleAuthService {
  _MockGoogleAuthService({this.idToken, this.error});
  final String? idToken;
  final Exception? error;
  bool signedOut = false;

  @override
  Future<String?> getGoogleIdToken() async {
    if (error != null) throw error!;
    return idToken;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _MockAuthRepo implements AuthRepository {
  _MockAuthRepo({
    this.signInResult,
    this.signInError,
    this.restoreResult,
    this.restoreError,
  });

  UserModel? signInResult;
  Exception? signInError;
  UserModel? restoreResult;
  Exception? restoreError;
  bool signedOut = false;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return signInResult!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<UserModel?> restoreSession() async {
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<UserModel> getCurrentUser({String? customToken}) async {
    return signInResult!;
  }

  @override
  Future<UserModel> signInWithOAuthToken(String token) async {
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<UserModel> signInWithGoogleIdToken(String idToken) async {
    if (signInError != null) throw signInError!;
    return signInResult!;
  }
}

void main() {
  group('AuthNotifier lifecycle & state transitions', () {
    const testUser = UserModel(
      id: 'usr_test',
      name: 'Taylor Swift',
      email: 'taylor@campus.edu',
      role: 'MEMBER',
    );

    test('restores active session successfully to AuthAuthenticated', () async {
      final mockRepo = _MockAuthRepo(restoreResult: testUser);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.restoreSession();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.email, 'taylor@campus.edu');
    });

    test(
      'transitions to AuthUnauthenticated when no stored token exists',
      () async {
        final mockRepo = _MockAuthRepo(restoreResult: null);
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.restoreSession();

        final state = container.read(authNotifierProvider);
        expect(state, isA<AuthUnauthenticated>());
      },
    );

    test('transitions to AuthNetworkOffline when restore fails with network timeout', () async {
      final mockRepo = _MockAuthRepo(
        restoreError: const NetworkException('Connection timed out.'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.restoreSession();

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthNetworkOffline>());
      expect((state as AuthNetworkOffline).message, 'Connection timed out.');
    });

    test('successful signIn transitions state to AuthAuthenticated', () async {
      final mockRepo = _MockAuthRepo(signInResult: testUser);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signIn(
        email: 'taylor@campus.edu',
        password: 'password123',
      );

      expect(success, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.name, 'Taylor Swift');
    });

    test('failed signIn transitions state to AuthUnauthenticated with error message', () async {
      final mockRepo = _MockAuthRepo(
        signInError: const UnauthorizedException(
          message: 'Invalid email or password.',
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signIn(
        email: 'bad@campus.edu',
        password: 'wrong',
      );

      expect(success, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).errorMessage,
        'Invalid email or password.',
      );
    });

    test(
      'signOut revokes session and resets state to AuthUnauthenticated',
      () async {
        final mockRepo = _MockAuthRepo(signInResult: testUser);
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signIn(
          email: 'taylor@campus.edu',
          password: 'password123',
        );

        await notifier.signOut();

        expect(mockRepo.signedOut, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state, isA<AuthUnauthenticated>());
      },
    );

    test(
      'handleOAuthCallback authenticates user when token is valid',
      () async {
        final mockRepo = _MockAuthRepo(signInResult: testUser);
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        final success = await notifier.handleOAuthCallback(
          'oauth_valid_jwt_token',
        );

        expect(success, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state, isA<AuthAuthenticated>());
        expect((state as AuthAuthenticated).user.id, 'usr_test');
      },
    );

    test(
      'handleOAuthCallback transitions to AuthUnauthenticated on error',
      () async {
        final mockRepo = _MockAuthRepo(
          signInError: const ApiException(
            message: 'OAuth state parameter mismatch',
          ),
        );
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        final success = await notifier.handleOAuthCallback('invalid_token');

        expect(success, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state, isA<AuthUnauthenticated>());
        expect(
          (state as AuthUnauthenticated).errorMessage,
          'OAuth state parameter mismatch',
        );
      },
    );

    test(
      'signInWithGoogle authenticates user when ID token is valid',
      () async {
        final mockRepo = _MockAuthRepo(signInResult: testUser);
        final mockGoogle = _MockGoogleAuthService(
          idToken: 'valid_google_id_token',
        );
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            googleAuthServiceProvider.overrideWithValue(mockGoogle),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        final success = await notifier.signInWithGoogle();

        expect(success, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state, isA<AuthAuthenticated>());
        final auth = state as AuthAuthenticated;
        expect(auth.user.id, 'usr_test');
        expect(auth.user.email, 'taylor@campus.edu');
      },
    );

    test('signInWithGoogle handles user cancellation cleanly without error message', () async {
      final mockRepo = _MockAuthRepo(signInResult: testUser);
      final mockGoogle = _MockGoogleAuthService(idToken: null); // Cancelled
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          googleAuthServiceProvider.overrideWithValue(mockGoogle),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithGoogle();

      expect(success, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).errorMessage, isNull);
    });

    test('signInWithGoogle transitions to AuthUnauthenticated on backend token rejection', () async {
      final mockRepo = _MockAuthRepo(
        signInError: const UnauthorizedException(
          message: 'Google ID token verification failed on server.',
        ),
      );
      final mockGoogle = _MockGoogleAuthService(idToken: 'rejected_id_token');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          googleAuthServiceProvider.overrideWithValue(mockGoogle),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithGoogle();

      expect(success, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).errorMessage,
        'Google ID token verification failed on server.',
      );
    });

    test('signInWithGoogle transitions to AuthUnauthenticated on Google SDK exception', () async {
      final mockRepo = _MockAuthRepo(signInResult: testUser);
      final mockGoogle = _MockGoogleAuthService(
        error: const ApiException(
          message: 'Google Play Services not available',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          googleAuthServiceProvider.overrideWithValue(mockGoogle),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.signInWithGoogle();

      expect(success, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).errorMessage,
        'Google Play Services not available',
      );
    });

    test(
      'signOut revokes both auth repo session and GoogleAuthService session',
      () async {
        final mockRepo = _MockAuthRepo(signInResult: testUser);
        final mockGoogle = _MockGoogleAuthService(idToken: 'valid_id_token');
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            googleAuthServiceProvider.overrideWithValue(mockGoogle),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signInWithGoogle();
        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

        await notifier.signOut();
        expect(mockRepo.signedOut, isTrue);
        expect(mockGoogle.signedOut, isTrue);
        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
      },
    );
  });
}
