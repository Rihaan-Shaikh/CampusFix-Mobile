import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/draft_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/google_auth_service.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => restoreSession());
    return const AuthInitial();
  }

  Future<void> restoreSession() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.restoreSession();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } on NetworkException catch (e) {
      state = AuthNetworkOffline(message: e.message);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (state is AuthAuthenticating) return false;
    final repo = ref.read(authRepositoryProvider);
    state = const AuthAuthenticating();
    try {
      final user = await repo.signIn(email: email, password: password);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'Sign-in failed. Please verify your credentials.';
      state = AuthUnauthenticated(errorMessage: message);
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state is AuthAuthenticating) return false;
    final repo = ref.read(authRepositoryProvider);
    state = const AuthAuthenticating();
    try {
      final user = await repo.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final message = e is AppException ? e.message : 'Registration failed.';
      state = AuthUnauthenticated(errorMessage: message);
      return false;
    }
  }

  Future<bool> handleOAuthCallback(String token) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AuthAuthenticating();
    try {
      final user = await repo.signInWithOAuthToken(token);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'OAuth sign-in validation failed.';
      state = AuthUnauthenticated(errorMessage: message);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    final googleAuth = ref.read(googleAuthServiceProvider);
    final repo = ref.read(authRepositoryProvider);
    state = const AuthAuthenticating();
    try {
      final idToken = await googleAuth.getGoogleIdToken();
      if (idToken == null) {
        // User cancelled or dismissed account picker cleanly without error banner
        state = const AuthUnauthenticated();
        return false;
      }

      final user = await repo.signInWithGoogleIdToken(idToken);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'Google Sign-In failed. Please try again.';
      state = AuthUnauthenticated(errorMessage: message);
      return false;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    final googleAuth = ref.read(googleAuthServiceProvider);
    try {
      await repo.signOut();
      try {
        await googleAuth.signOut();
      } catch (_) {}
      try {
        await ref.read(draftStorageServiceProvider).clearDraft();
        await ref.read(notificationServiceProvider).unregisterOnSignOut();
      } catch (_) {}
    } finally {
      state = const AuthUnauthenticated();
    }
  }
}
