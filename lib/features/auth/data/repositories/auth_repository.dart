import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<UserModel?> restoreSession();
  Future<UserModel> getCurrentUser({String? customToken});
  Future<UserModel> signInWithOAuthToken(String token);
  Future<UserModel> signInWithGoogleIdToken(String idToken);
}

class BetterAuthRepository implements AuthRepository {
  BetterAuthRepository({
    required this.dio,
    required this.config,
    required this.storage,
  });

  final Dio dio;
  final AppConfig config;
  final SecureStorageService storage;

  static const String tokenKey = 'campusfix_auth_token';

  /// Extracts the session token from a Better Auth response, checking:
  /// 1. Top-level `token` key
  /// 2. Nested `session.token` or `session.id`
  /// 3. `Set-Cookie` header (`better-auth.session_token`, `__Secure-better-auth.session_token`, `campusfix_authorization`)
  /// 4. `Authorization` response header
  String? _extractToken(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) return token;

      if (data['session'] is Map) {
        final session = data['session'] as Map<String, dynamic>;
        final sessionToken =
            session['token'] as String? ?? session['id'] as String?;
        if (sessionToken != null && sessionToken.isNotEmpty) {
          return sessionToken;
        }
      }
    }

    final setAuthToken = response.headers.value('set-auth-token');
    if (setAuthToken != null && setAuthToken.isNotEmpty) {
      final rawPart = setAuthToken.split('.').first;
      if (rawPart.isNotEmpty) return rawPart;
      return setAuthToken;
    }

    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final c in cookies) {
        final match =
            RegExp(r'(?:__Secure-)?better-auth\.session_token=([^;]+)')
                .firstMatch(c) ??
            RegExp(r'campusfix_authorization=([^;]+)').firstMatch(c);
        if (match != null) {
          final extracted = match.group(1);
          if (extracted != null && extracted.isNotEmpty) {
            return extracted;
          }
        }
      }
    }

    final authHeader = response.headers.value('authorization');
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7).trim();
    }

    return null;
  }

  /// Extracts user profile data from various response payload structures:
  /// 1. `data['user']` (standard Better Auth)
  /// 2. `data['data']` (versioned custom API wrapper)
  /// 3. Direct user map
  UserModel? _extractUser(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['user'] is Map<String, dynamic>) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    if (data['data'] is Map<String, dynamic>) {
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    if (data['id'] != null && data['email'] != null) {
      return UserModel.fromJson(data);
    }
    return null;
  }

  Map<String, dynamic> _buildAuthHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Cookie':
          'better-auth.session_token=$token; __Secure-better-auth.session_token=$token; campusfix_authorization=$token',
      'Origin': config.origin,
    };
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '${config.authBaseUrl}/sign-in/email',
        data: {'email': email.trim(), 'password': password},
        options: Options(headers: {'Origin': config.origin}),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(
          message: 'Empty response received from authentication server.',
        );
      }

      final token = _extractToken(response);
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Authentication token was not returned by server.',
        );
      }

      // Persist bearer token securely
      await storage.write(tokenKey, token);

      // If user profile is already returned in response, parse directly
      final directUser = _extractUser(data);
      if (directUser != null) {
        return directUser;
      }

      // Otherwise verify token immediately against authoritative /api/v1/auth/me profile
      return await getCurrentUser(customToken: token);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(message: e.message ?? 'Sign-in failed.', cause: e);
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '${config.authBaseUrl}/sign-up/email',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
        options: Options(headers: {'Origin': config.origin}),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(
          message: 'Empty response received from registration server.',
        );
      }

      final token = _extractToken(response);
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Authentication token was not returned after registration.',
        );
      }

      await storage.write(tokenKey, token);

      final directUser = _extractUser(data);
      if (directUser != null) {
        return directUser;
      }

      return await getCurrentUser(customToken: token);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw ApiException(
        message: e.message ?? 'Registration failed.',
        cause: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    final token = await storage.read(tokenKey);
    try {
      if (token != null && token.isNotEmpty) {
        await dio.post<dynamic>(
          '${config.authBaseUrl}/sign-out',
          options: Options(headers: _buildAuthHeaders(token)),
        );
      }
    } catch (_) {
      // Best-effort remote revocation; always clear client credentials
    } finally {
      await storage.delete(tokenKey);
    }
  }

  @override
  Future<UserModel?> restoreSession() async {
    final token = await storage.read(tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await getCurrentUser(customToken: token);
    } on UnauthorizedException {
      // Token expired or invalid; clear credentials cleanly
      await storage.delete(tokenKey);
      return null;
    } catch (e) {
      // On temporary network failure, rethrow so the app can distinguish offline from logged out
      rethrow;
    }
  }

  @override
  Future<UserModel> getCurrentUser({String? customToken}) async {
    final token = customToken ?? await storage.read(tokenKey);
    if (token == null || token.isEmpty) {
      throw const UnauthorizedException(
        message: 'No active session token available.',
      );
    }

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${config.v1BaseUrl}/auth/me',
        options: Options(headers: _buildAuthHeaders(token)),
      );

      final user = _extractUser(response.data);
      if (user == null) {
        throw const ApiException(
          message: 'Invalid user profile data received.',
        );
      }

      return user;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      if (e.response?.statusCode == 404) {
        // Fallback to /api/auth/get-session
        try {
          final fallbackResponse = await dio.get<Map<String, dynamic>>(
            '${config.authBaseUrl}/get-session',
            options: Options(headers: _buildAuthHeaders(token)),
          );
          final fallbackUser = _extractUser(fallbackResponse.data);
          if (fallbackUser != null) {
            return fallbackUser;
          }
        } catch (_) {}
      }
      throw ApiException(
        message: e.message ?? 'Failed to retrieve profile.',
        cause: e,
      );
    }
  }

  @override
  Future<UserModel> signInWithOAuthToken(String token) async {
    await storage.write(tokenKey, token);
    return await getCurrentUser(customToken: token);
  }

  @override
  Future<UserModel> signInWithGoogleIdToken(String idToken) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '${config.authBaseUrl}/sign-in/social',
        data: {
          'provider': 'google',
          'idToken': {'token': idToken},
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(
          message: 'Empty response received from authentication server.',
        );
      }

      final token = _extractToken(response);
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'No session token was granted after Google authentication.',
        );
      }

      // Persist bearer token securely
      await storage.write(tokenKey, token);

      // If user profile was returned directly in the response, parse it immediately
      final directUser = _extractUser(data);
      if (directUser != null) {
        return directUser;
      }

      // Otherwise verify token against authoritative /api/v1/auth/me profile
      return await getCurrentUser(customToken: token);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final responseMessage = (e.response?.data is Map)
            ? (e.response!.data as Map)['message']?.toString()
            : null;
        throw UnauthorizedException(
          message:
              responseMessage ??
              'Google ID token verification failed on server.',
          statusCode: e.response?.statusCode ?? 401,
          responseData: e.response?.data,
          cause: e,
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          e.message ?? 'Network connection error during Google sign-in.',
          e,
        );
      }
      final responseMessage = (e.response?.data is Map)
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      throw ApiException(
        message:
            responseMessage ?? e.message ?? 'Google Sign-In failed on server.',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return BetterAuthRepository(dio: dio, config: config, storage: storage);
});
