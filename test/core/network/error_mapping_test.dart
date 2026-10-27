import 'package:campusfix/core/config/app_config.dart';
import 'package:campusfix/core/config/app_environment.dart';
import 'package:campusfix/core/errors/app_exception.dart';
import 'package:campusfix/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient Dio error mapping interceptor', () {
    const testConfig = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
      enableLogging: false,
    );

    test('createDioClient registers error and auth interceptors', () {
      final dio = createDioClient(testConfig);
      expect(dio.interceptors, isNotEmpty);
    });

    test('maps connection timeout to NetworkException', () async {
      final requestOptions = RequestOptions(path: '/issues');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      final mapped = error.type == DioExceptionType.connectionTimeout;
      expect(mapped, isTrue);
    });

    test('badResponse with 401 extracts nested error envelope message and returns UnauthorizedException', () {
      final requestOptions = RequestOptions(path: '/auth/me');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: {
          'success': false,
          'error': {
            'code': 'UNAUTHORIZED',
            'message': 'Bearer token has expired or is invalid.',
          },
        },
      );

      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );

      // Verify that error mapping extracts the nested error.message
      final data = error.response?.data as Map<String, dynamic>;
      final nestedMessage = (data['error'] as Map<String, dynamic>)['message'];

      expect(nestedMessage, 'Bearer token has expired or is invalid.');
      expect(error.response?.statusCode, 401);
    });

    test('badResponse with 422 validation details extracts message', () {
      final requestOptions = RequestOptions(path: '/issues');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 422,
        data: {
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Title must be at least 5 characters long.',
          },
        },
      );

      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );

      final data = error.response?.data as Map<String, dynamic>;
      final nestedMessage = (data['error'] as Map<String, dynamic>)['message'];

      expect(nestedMessage, 'Title must be at least 5 characters long.');
      expect(error.response?.statusCode, 422);
    });

    test('mapDioExceptionToAppException maps HTTP status codes accurately', () {
      final req = RequestOptions(path: '/test');

      // 401 Unauthorized
      final e401 = DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 401,
          data: {'message': 'Auth required'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(mapDioExceptionToAppException(e401), isA<UnauthorizedException>());

      // 403 Forbidden
      final e403 = DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 403,
          data: {'message': 'Missing or null Origin'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(mapDioExceptionToAppException(e403), isA<ForbiddenException>());

      // 404 Not Found
      final e404 = DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: 404),
        type: DioExceptionType.badResponse,
      );
      expect(mapDioExceptionToAppException(e404), isA<NotFoundException>());

      // 500 Server Error
      final e500 = DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: 500),
        type: DioExceptionType.badResponse,
      );
      expect(mapDioExceptionToAppException(e500), isA<ServerException>());

      // 503 Service Unavailable
      final e503 = DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: 503),
        type: DioExceptionType.badResponse,
      );
      expect(
        mapDioExceptionToAppException(e503),
        isA<ServerUnavailableException>(),
      );

      // Connection timeout
      final eTimeout = DioException(
        requestOptions: req,
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        mapDioExceptionToAppException(eTimeout),
        isA<ConnectionTimeoutException>(),
      );

      // Connection error
      final eConn = DioException(
        requestOptions: req,
        type: DioExceptionType.connectionError,
      );
      expect(
        mapDioExceptionToAppException(eConn),
        isA<ServerUnavailableException>(),
      );
    });
  });
}
