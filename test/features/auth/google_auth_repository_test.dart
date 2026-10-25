import 'package:campusfix/core/config/app_config.dart';
import 'package:campusfix/core/config/app_environment.dart';
import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:campusfix/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}

class _MockInterceptor extends Interceptor {
  _MockInterceptor({required this.handler});

  final Future<Response<dynamic>> Function(RequestOptions options) handler;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler chain,
  ) async {
    try {
      final response = await handler(options);
      chain.resolve(response);
    } on DioException catch (e) {
      chain.reject(e);
    } catch (e) {
      chain.reject(DioException(requestOptions: options, error: e));
    }
  }
}

void main() {
  group('BetterAuthRepository.signInWithGoogleIdToken', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://campusfixed.netlify.app/api/v1',
    );

    late _InMemorySecureStorage storage;

    setUp(() {
      storage = _InMemorySecureStorage();
    });

    test(
      'successfully exchanges valid Google ID token for session and user',
      () async {
        final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
        dio.interceptors.add(
          _MockInterceptor(
            handler: (options) async {
              if (options.path.contains('/sign-in/social')) {
                expect(options.data, {
                  'provider': 'google',
                  'idToken': {'token': 'valid_google_id_token'},
                });
                return Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'token': 'session_token_xyz',
                    'user': {
                      'id': 'usr_google_123',
                      'name': 'Google Student',
                      'email': 'student@campus.edu',
                      'role': 'STUDENT',
                    },
                  },
                );
              }
              throw DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
              );
            },
          ),
        );

        final repo = BetterAuthRepository(
          dio: dio,
          config: config,
          storage: storage,
        );

        final user = await repo.signInWithGoogleIdToken(
          'valid_google_id_token',
        );

        expect(user.id, 'usr_google_123');
        expect(user.name, 'Google Student');
        expect(user.email, 'student@campus.edu');
        expect(user.role, 'STUDENT');

        // Verify token persisted in secure storage
        final storedToken = await storage.read(BetterAuthRepository.tokenKey);
        expect(storedToken, 'session_token_xyz');
      },
    );

    test('extracts session token from Set-Cookie header when response body has no token field', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/sign-in/social')) {
              return Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'set-cookie': [
                    'better-auth.session_token=cookie_token_999; Path=/; HttpOnly; SameSite=Lax',
                  ],
                }),
                data: {
                  'user': {
                    'id': 'usr_google_456',
                    'name': 'Cookie Student',
                    'email': 'cookie@campus.edu',
                    'role': 'MEMBER',
                  },
                },
              );
            }
            throw DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404),
            );
          },
        ),
      );

      final repo = BetterAuthRepository(
        dio: dio,
        config: config,
        storage: storage,
      );

      final user = await repo.signInWithGoogleIdToken('cookie_flow_id_token');

      expect(user.id, 'usr_google_456');
      final storedToken = await storage.read(BetterAuthRepository.tokenKey);
      expect(storedToken, 'cookie_token_999');
    });

    test(
      'throws UnauthorizedException when backend rejects ID token (401)',
      () async {
        final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
        dio.interceptors.add(
          _MockInterceptor(
            handler: (options) async {
              throw DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Invalid token', 'code': 'INVALID_TOKEN'},
                ),
              );
            },
          ),
        );

        final repo = BetterAuthRepository(
          dio: dio,
          config: config,
          storage: storage,
        );

        expect(
          () => repo.signInWithGoogleIdToken('invalid_or_expired_token'),
          throwsA(
            isA<UnauthorizedException>().having(
              (e) => e.message,
              'message',
              'Invalid token',
            ),
          ),
        );

        // Verify no token was stored
        final storedToken = await storage.read(BetterAuthRepository.tokenKey);
        expect(storedToken, isNull);
      },
    );

    test('throws ServerException on 500 server error', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            throw DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'Internal Server Error'},
              ),
            );
          },
        ),
      );

      final repo = BetterAuthRepository(
        dio: dio,
        config: config,
        storage: storage,
      );

      expect(
        () => repo.signInWithGoogleIdToken('token_triggering_server_error'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws NetworkException on connection timeout', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
              error: 'Connection timeout',
            );
          },
        ),
      );

      final repo = BetterAuthRepository(
        dio: dio,
        config: config,
        storage: storage,
      );

      expect(
        () => repo.signInWithGoogleIdToken('any_token'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
