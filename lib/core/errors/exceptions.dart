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
    required super.message,
    required this.deviceName,
    super.originalError,
  }) : super(
          type: ErrorType.device,
        );
}

/// Network related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException({
    required super.message,
    this.statusCode,
    super.originalError,
  }) : super(
          type: ErrorType.network,
        );
}

/// Database related exceptions
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.originalError,
  }) : super(
          type: ErrorType.database,
        );
}
