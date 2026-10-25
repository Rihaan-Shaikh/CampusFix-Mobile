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

/// Authentication or authorization failure (HTTP 401 / 403).
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired or unauthorized. Please sign in again.',
    super.statusCode = 401,
    super.responseData,
    super.cause,
  });
}

/// Local storage failure (reading or writing secure storage).
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

/// Fallback for unexpected exceptions.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred.',
    super.cause,
  ]);
}
