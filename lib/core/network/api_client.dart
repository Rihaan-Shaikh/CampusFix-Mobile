import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';

/// Provider for the configured Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return createDioClient(config, storageService: storage);
});

/// Factory function to construct and configure a Dio instance based on AppConfig.
Dio createDioClient(AppConfig config, {SecureStorageService? storageService}) {
  final options = BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.receiveTimeout,
    headers: <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Origin': config.origin,
    },
  );

  final dio = Dio(options);

  // 1. Authorization, Cookie, and Origin header injection
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Always ensure Origin header is provided for Better Auth CSRF validation
        if (!options.headers.containsKey('Origin') ||
            options.headers['Origin'] == null ||
            (options.headers['Origin'] as String).isEmpty) {
          options.headers['Origin'] = config.origin;
        }

        if (storageService != null) {
          try {
            final token = await storageService.read('campusfix_auth_token');
            if (token != null && token.isNotEmpty) {
              if (!options.headers.containsKey('Authorization')) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              if (!options.headers.containsKey('Cookie')) {
                options.headers['Cookie'] =
                    'better-auth.session_token=$token; __Secure-better-auth.session_token=$token; campusfix_authorization=$token';
              }
            }
          } catch (_) {}
        }
        return handler.next(options);
      },
    ),
  );

  // 2. Safe idempotent GET retry interceptor for transient glitches
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        final requestOptions = error.requestOptions;
        // Strictly only retry idempotent GET requests
        final isGet = requestOptions.method.toUpperCase() == 'GET';
        final isRetryable =
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError;

        final hasAlreadyRetried =
            requestOptions.extra['kCampusRetried'] == true;

        if (isGet && isRetryable && !hasAlreadyRetried) {
          requestOptions.extra['kCampusRetried'] = true;
          try {
            await Future<void>.delayed(const Duration(milliseconds: 1000));
            final response = await dio.fetch<dynamic>(requestOptions);
            return handler.resolve(response);
          } catch (_) {
            // Fall through to error handler if retry also fails
          }
        }
        return handler.next(error);
      },
    ),
  );

  // 3. Application error mapping
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final appException = _mapDioException(error);
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: appException,
            message: appException.message,
          ),
        );
      },
    ),
  );

  // 4. Secure logging (sanitized, debug-only)
  if (config.enableLogging && kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false, // Prevent token header leak
        requestBody: false, // Avoid dumping credentials
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );
  }

  return dio;
}

@visibleForTesting
AppException mapDioExceptionToAppException(DioException error) =>
    _mapDioException(error);

AppException _mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return ConnectionTimeoutException(
        'Connection timed out. Please check your internet connection.',
        error,
      );
    case DioExceptionType.connectionError:
      final err = error.error;
      if (err is SocketException) {
        return ServerUnavailableException(
          'Unable to reach server. Please check your connection.',
          error,
        );
      }
      return ServerUnavailableException(
        'Unable to reach server. Please check your connection.',
        error,
      );
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      String message = 'Server returned error ($statusCode)';
      if (data is Map<String, dynamic>) {
        if (data['error'] is Map<String, dynamic> &&
            (data['error'] as Map<String, dynamic>)['message'] is String) {
          message =
              (data['error'] as Map<String, dynamic>)['message'] as String;
        } else if (data['error'] is String) {
          message = data['error'] as String;
        } else if (data['message'] is String) {
          message = data['message'] as String;
        }
      } else if (data is String && data.contains('<!DOCTYPE html>')) {
        if (statusCode == 404) {
          message = 'The requested campus endpoint was not found.';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'The server is experiencing temporary issues. Please try again later.';
        }
      }

      if (statusCode == 401) {
        return UnauthorizedException(
          message: message,
          statusCode: statusCode,
          responseData: data,
          cause: error,
        );
      }
      if (statusCode == 403) {
        return ForbiddenException(
          message: message,
          statusCode: statusCode,
          responseData: data,
          cause: error,
        );
      }
      if (statusCode == 404) {
        return NotFoundException(
          message: message,
          statusCode: statusCode,
          responseData: data,
          cause: error,
        );
      }
      if (statusCode == 503) {
        return ServerUnavailableException(
          message.isNotEmpty && message != 'Server returned error (503)'
              ? message
              : 'CampusFix server is temporarily unavailable. Please try again shortly.',
          error,
        );
      }
      if (statusCode != null && statusCode >= 500) {
        return ServerException(
          message: message,
          statusCode: statusCode,
          responseData: data,
          cause: error,
        );
      }
      return ApiException(
        message: message,
        statusCode: statusCode,
        responseData: data,
        cause: error,
      );
    case DioExceptionType.cancel:
      return const NetworkException('Request was cancelled.');
    case DioExceptionType.badCertificate:
      return NetworkException(
        'SSL/TLS certificate verification failed.',
        error,
      );
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return ServerUnavailableException(
          'Unable to reach server. Please check your network connection.',
          error,
        );
      }
      return NetworkException('Network error occurred.', error);
  }
}
