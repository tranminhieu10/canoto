/// Các hằng số chung của ứng dụng
class AppConstants {
  // Tên ứng dụng
  static const String appName = 'Cân Ô Tô';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'canoto.db';
  static const int databaseVersion = 1;

  // API Endpoints
  static const String baseUrl = 'http://localhost:8080/api';

  // Timeout settings (milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Cân
  static const double maxWeight = 100000; // kg
  static const double minWeight = 0; // kg
  static const double weightTolerance = 10; // kg

  // Camera
  static const int defaultCameraFps = 30;
  static const int snapshotQuality = 85;

  // Barrier
  static const int barrierOpenTime = 5000; // ms
  static const int barrierCloseDelay = 3000; // ms
}
