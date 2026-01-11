/// Custom exception hierarchy for API errors
abstract class ApiException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  ApiException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'ApiException: [$code] $message';
}

/// Thrown when network request fails (no internet, timeout, etc.)
class NetworkException extends ApiException {
  NetworkException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown when server returns 4xx status
class ClientException extends ApiException {
  final int statusCode;

  ClientException({
    required String message,
    required this.statusCode,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown on 401 Unauthorized (token expired)
class UnauthorizedException extends ClientException {
  UnauthorizedException({String? message, StackTrace? stackTrace})
      : super(
          message: message ?? 'Unauthorized. Please login again.',
          statusCode: 401,
          code: 'UNAUTHORIZED',
          stackTrace: stackTrace,
        );
}

/// Thrown on 403 Forbidden
class ForbiddenException extends ClientException {
  ForbiddenException({String? message, StackTrace? stackTrace})
      : super(
          message: message ?? 'Access forbidden.',
          statusCode: 403,
          code: 'FORBIDDEN',
          stackTrace: stackTrace,
        );
}

/// Thrown on 404 Not Found
class NotFoundException extends ClientException {
  NotFoundException({String? message, StackTrace? stackTrace})
      : super(
          message: message ?? 'Resource not found.',
          statusCode: 404,
          code: 'NOT_FOUND',
          stackTrace: stackTrace,
        );
}

/// Thrown when server returns 5xx status
class ServerException extends ApiException {
  final int statusCode;

  ServerException({
    required String message,
    required this.statusCode,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

/// Thrown for parsing/serialization errors
class SerializationException extends ApiException {
  SerializationException({
    required String message,
    StackTrace? stackTrace,
  }) : super(message: message, code: 'SERIALIZATION_ERROR', stackTrace: stackTrace);
}
