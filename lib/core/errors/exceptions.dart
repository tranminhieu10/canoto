/// Error types for the application
enum ErrorType {
  network,
  database,
  device,
  validation,
  authentication,
  unknown,
}

/// Custom exception class
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.type = ErrorType.unknown,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (Type: $type)';
}

/// Device related exceptions
class DeviceException extends AppException {
  final String deviceName;

  DeviceException({
    required String message,
    required this.deviceName,
    dynamic originalError,
  }) : super(
          message: message,
          type: ErrorType.device,
          originalError: originalError,
        );
}

/// Network related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException({
    required String message,
    this.statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          type: ErrorType.network,
          originalError: originalError,
        );
}

/// Database related exceptions
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    dynamic originalError,
  }) : super(
          message: message,
          type: ErrorType.database,
          originalError: originalError,
        );
}
