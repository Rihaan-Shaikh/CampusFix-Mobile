import 'package:campusfix/core/config/app_config.dart';
import 'package:campusfix/core/config/app_environment.dart';
import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:campusfix/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryStorage implements SecureStorageService {
  final Map<String, String> _map = {};

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);
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
  group('BetterAuthRepository unit tests', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://campusfixed.netlify.app/api/v1',
    );

    late _InMemoryStorage storage;

    setUp(() {
      storage = _InMemoryStorage();
    });

    test(
      'signIn succeeds when server returns top-level token and user object',
      () async {
        final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
        dio.interceptors.add(
          _MockInterceptor(
            handler: (options) async {
              if (options.path.contains('/sign-in/email')) {
                expect(options.data, {
                  'email': 'student@university.edu',
                  'password': 'password123',
                });
                return Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'token': 'session_token_123',
                    'user': {
                      'id': 'usr_1',
                      'name': 'Student One',
                      'email': 'student@university.edu',
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

        final user = await repo.signIn(
          email: 'student@university.edu',
          password: 'password123',
        );

        expect(user.id, 'usr_1');
        expect(user.name, 'Student One');
        expect(user.email, 'student@university.edu');
        expect(
          await storage.read(BetterAuthRepository.tokenKey),
          'session_token_123',
        );
      },
    );

    test('signIn extracts token from nested session.token when top-level token is omitted', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/sign-in/email')) {
              return Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'session': {
                    'token': 'nested_session_token_456',
                    'userId': 'usr_2',
                  },
                  'user': {
                    'id': 'usr_2',
                    'name': 'Student Two',
                    'email': 'student2@university.edu',
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

      final user = await repo.signIn(
        email: 'student2@university.edu',
        password: 'password123',
      );

      expect(user.id, 'usr_2');
      expect(
        await storage.read(BetterAuthRepository.tokenKey),
        'nested_session_token_456',
      );
    });

    test('signIn extracts token from Set-Cookie __Secure-better-auth.session_token header', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/sign-in/email')) {
              return Response(
                requestOptions: options,
                statusCode: 200,
                headers: Headers.fromMap({
                  'set-cookie': [
                    '__Secure-better-auth.session_token=cookie_token_789; Path=/; HttpOnly; Secure',
                  ],
                }),
                data: {
                  'user': {
                    'id': 'usr_cookie',
                    'name': 'Cookie Student',
                    'email': 'cookie@university.edu',
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

      final user = await repo.signIn(
        email: 'cookie@university.edu',
        password: 'password123',
      );

      expect(user.id, 'usr_cookie');
      expect(
        await storage.read(BetterAuthRepository.tokenKey),
        'cookie_token_789',
      );
    });

    test(
      'signIn throws ApiException when invalid credentials return 401',
      () async {
        final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
        dio.interceptors.add(
          _MockInterceptor(
            handler: (options) async {
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Invalid email or password'},
                ),
                message: 'Invalid email or password',
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
          () => repo.signIn(email: 'wrong@campus.edu', password: 'bad'),
          throwsA(isA<ApiException>()),
        );
        expect(await storage.read(BetterAuthRepository.tokenKey), isNull);
      },
    );

    test('signUp creates new account and persists session token', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/sign-up/email')) {
              expect(options.data, {
                'name': 'New Student',
                'email': 'new@university.edu',
                'password': 'password123',
              });
              return Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'token': 'signup_token_abc',
                  'user': {
                    'id': 'usr_new',
                    'name': 'New Student',
                    'email': 'new@university.edu',
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

      final user = await repo.signUp(
        name: 'New Student',
        email: 'new@university.edu',
        password: 'password123',
      );

      expect(user.id, 'usr_new');
      expect(
        await storage.read(BetterAuthRepository.tokenKey),
        'signup_token_abc',
      );
    });

    test('signUp throws when token is missing from response', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            return Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'message': 'Account created but email verification required',
              },
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
        () => repo.signUp(
          name: 'Pending Student',
          email: 'pending@university.edu',
          password: 'password123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('restoreSession returns null and clears storage when token is expired/unauthorized', () async {
      await storage.write(BetterAuthRepository.tokenKey, 'expired_token');

      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              error: const UnauthorizedException(message: 'Session expired'),
            );
          },
        ),
      );

      final repo = BetterAuthRepository(
        dio: dio,
        config: config,
        storage: storage,
      );

      final user = await repo.restoreSession();
      expect(user, isNull);
      expect(await storage.read(BetterAuthRepository.tokenKey), isNull);
    });

    test('restoreSession restores user when stored token is valid', () async {
      await storage.write(BetterAuthRepository.tokenKey, 'valid_saved_token');

      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/auth/me')) {
              expect(
                options.headers['Authorization'],
                'Bearer valid_saved_token',
              );
              expect(
                options.headers['Cookie'],
                contains('better-auth.session_token=valid_saved_token'),
              );
              return Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'id': 'usr_persisted',
                    'name': 'Persisted User',
                    'email': 'persisted@campus.edu',
                    'role': 'STAFF',
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

      final user = await repo.restoreSession();
      expect(user, isNotNull);
      expect(user!.name, 'Persisted User');
      expect(user.isStaff, isTrue);
    });

    test('getCurrentUser falls back to /api/auth/get-session when /api/v1/auth/me returns 404', () async {
      final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
      dio.interceptors.add(
        _MockInterceptor(
          handler: (options) async {
            if (options.path.contains('/api/v1/auth/me')) {
              throw DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
              );
            }
            if (options.path.contains('/api/auth/get-session')) {
              return Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'user': {
                    'id': 'usr_get_session',
                    'name': 'Fallback User',
                    'email': 'fallback@campus.edu',
                    'role': 'ADMIN',
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

      final user = await repo.getCurrentUser(customToken: 'fallback_token');
      expect(user.id, 'usr_get_session');
      expect(user.isAdmin, isTrue);
    });

    test(
      'signOut clears stored session token and sends remote revocation',
      () async {
        await storage.write(BetterAuthRepository.tokenKey, 'token_to_revoke');

        bool remoteSignOutCalled = false;
        final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl));
        dio.interceptors.add(
          _MockInterceptor(
            handler: (options) async {
              if (options.path.contains('/sign-out')) {
                remoteSignOutCalled = true;
                expect(
                  options.headers['Authorization'],
                  'Bearer token_to_revoke',
                );
                expect(
                  options.headers['Cookie'],
                  contains('better-auth.session_token=token_to_revoke'),
                );
                return Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'ok': true},
                );
              }
              return Response(requestOptions: options, statusCode: 200);
            },
          ),
        );

        final repo = BetterAuthRepository(
          dio: dio,
          config: config,
          storage: storage,
        );

        await repo.signOut();
        expect(remoteSignOutCalled, isTrue);
        expect(await storage.read(BetterAuthRepository.tokenKey), isNull);
      },
    );
  });
}
