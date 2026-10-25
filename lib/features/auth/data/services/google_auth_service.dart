import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';

abstract class GoogleAuthService {
  /// Prompts the user with native Google Sign-In and returns the verified OIDC ID Token.
  /// Returns `null` if the user cancels or dismisses the account picker.
  Future<String?> getGoogleIdToken();

  /// Revokes or signs out the local Google session.
  Future<void> signOut();
}

class NativeGoogleAuthService implements GoogleAuthService {
  NativeGoogleAuthService({required this.config, GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final AppConfig config;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _googleSignIn.initialize(
        serverClientId: config.googleServerClientId,
        clientId: config.googleClientId,
      );
      _initialized = true;
    } catch (_) {
      // In case initialize was already called or platform specific
      _initialized = true;
    }
  }

  @override
  Future<String?> getGoogleIdToken() async {
    await _ensureInitialized();

    try {
      if (_googleSignIn.supportsAuthenticate()) {
        final GoogleSignInAccount account = await _googleSignIn.authenticate();
        final GoogleSignInAuthentication auth = account.authentication;
        final idToken = auth.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const ApiException(
            message: 'Google Sign-In completed, but no ID token was returned. Ensure Google Web Client ID is configured.',
          );
        }
        return idToken;
      } else {
        throw const ApiException(
          message: 'Google Sign-In is not supported on this platform.',
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw ApiException(
        message: 'Google Sign-In error: ${e.description ?? e.code.name}',
      );
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('cancel') ||
          code == '12501' ||
          msg.contains('canceled') ||
          msg.contains('cancelled')) {
        return null;
      }
      if (code == 'network_error' || code == '7') {
        throw const NetworkException(
          'Network error during Google Sign-In. Please check your internet connection.',
        );
      }
      throw ApiException(
        message: e.message ?? 'Google Sign-In failed ($code).',
      );
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('cancel') || str.contains('12501')) {
        return null;
      }
      if (e is AppException) rethrow;
      throw ApiException(message: 'Google Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort sign-out
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return NativeGoogleAuthService(config: config);
});
