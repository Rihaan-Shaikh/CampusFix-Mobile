/// Base class for all application errors.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-level failure (no connection, timeout, handshake failure).
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// No active internet connection or socket unreachable.
class NoInternetException extends NetworkException {
  const NoInternetException([
    super.message =
        'No internet connection. Please check your network and try again.',
    super.cause,
  ]);
}

/// Request timed out connecting or receiving from server.
class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException([
    super.message = 'Connection timed out. Please check your internet connection and try again.',
    super.cause,
  ]);
}

/// Server could not be reached or is currently unreachable.
class ServerUnavailableException extends NetworkException {
  const ServerUnavailableException([
    super.message = 'CampusFix server is temporarily unreachable. Please try again in a few moments.',
    super.cause,
  ]);
}

/// API server response error with an HTTP status code.
class ApiException extends AppException {
  const ApiException({
    required String message,
    this.statusCode,
    this.responseData,
    Object? cause,
  }) : super(message, cause);

  final int? statusCode;
  final dynamic responseData;

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}

/// Authentication required or session expired (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired or authentication required. Please sign in to continue.',
    super.statusCode = 401,
    super.responseData,
    super.cause,
  });
}

/// Access forbidden or insufficient permissions (HTTP 403).
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message =
        'Access denied. You do not have permission to perform this action.',
    super.statusCode = 403,
    super.responseData,
    super.cause,
  });
}

/// Requested resource was not found (HTTP 404).
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested campus incident or resource was not found.',
    super.statusCode = 404,
    super.responseData,
    super.cause,
  });
}

/// Server error (HTTP 5xx).
class ServerException extends ApiException {
  const ServerException({
    super.message = 'CampusFix server encountered an unexpected error. Please try again later.',
    super.statusCode = 500,
    super.responseData,
    super.cause,
  });
}

/// Malformed response or JSON deserialization failure.
class InvalidResponseException extends AppException {
  const InvalidResponseException([
    super.message =
        'Received an invalid response from the server. Please try again later.',
    super.cause,
  ]);
}

/// Local storage failure (reading or writing secure storage).
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

/// Fallback for unexpected exceptions.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred. Please try again.',
    super.cause,
  ]);
}
