/// Azure Configuration Constants
/// Replace these values with your actual Azure resource configurations
class AzureConfig {
  AzureConfig._();

  // ============================================================
  // Azure Functions API Configuration
  // ============================================================
  
  /// Base URL for Azure Functions API
  static const String apiBaseUrl = 'https://canoto-api.azurewebsites.net/api';
  
  /// Azure Functions Host Key (for function-level authorization)
  static const String functionHostKey = 'YOUR_FUNCTION_HOST_KEY';
  
  /// API Version
  static const String apiVersion = 'v1';
  
  /// API Timeout in seconds
  static const int apiTimeout = 30;

  // ============================================================
  // Azure SQL Database Configuration
  // ============================================================
  
  /// SQL Server hostname
  static const String sqlServerHost = 'canoto-sql-server.database.windows.net';
  
  /// SQL Database name
  static const String sqlDatabaseName = 'canoto-db';
  
  /// SQL Server port
  static const int sqlServerPort = 1433;

  // ============================================================
  // Azure Blob Storage Configuration
  // ============================================================
  
  /// Storage Account Name
  static const String storageAccountName = 'canotostorage';
  
  /// Storage Account Key (keep secure!)
  static const String storageAccountKey = 'YOUR_STORAGE_ACCOUNT_KEY';
  
  /// Blob Container for weighing images
  static const String blobContainerImages = 'weighing-images';
  
  /// Blob Container for license plate images
  static const String blobContainerLicensePlates = 'license-plates';
  
  /// Blob Storage Base URL
  static String get blobBaseUrl => 
      'https://$storageAccountName.blob.core.windows.net';
  
  /// Get full URL for image blob
  static String getImageUrl(String containerName, String blobName) =>
      '$blobBaseUrl/$containerName/$blobName';

  // ============================================================
  // Azure SignalR Service Configuration
  // ============================================================
  
  /// SignalR Hub URL
  static const String signalRHubUrl = 
      'https://canoto-api.azurewebsites.net/notificationHub';
  
  /// SignalR Connection String (for server-side)
  static const String signalRConnectionString = 'YOUR_SIGNALR_CONNECTION_STRING';

  // ============================================================
  // Azure IoT Hub Configuration
  // ============================================================
  
  /// IoT Hub Hostname
  static const String iotHubHostname = 'canoto-iothub.azure-devices.net';
  
  /// IoT Hub Connection String
  static const String iotHubConnectionString = 'YOUR_IOT_HUB_CONNECTION_STRING';
  
  /// Device ID for this weighing station
  static const String iotDeviceId = 'weighing-station-01';
  
  /// MQTT Port for IoT Hub
  static const int iotHubMqttPort = 8883;

  // ============================================================
  // Azure Application Insights (Logging/Monitoring)
  // ============================================================
  
  /// Instrumentation Key
  static const String appInsightsKey = 'YOUR_APP_INSIGHTS_INSTRUMENTATION_KEY';
  
  /// Enable telemetry
  static const bool enableTelemetry = true;

  // ============================================================
  // Authentication Configuration
  // ============================================================
  
  /// Azure AD Tenant ID
  static const String tenantId = 'YOUR_TENANT_ID';
  
  /// Azure AD Client ID (App Registration)
  static const String clientId = 'YOUR_CLIENT_ID';
  
  /// API Scope for authentication
  static const String apiScope = 'api://canoto-api/.default';

  // ============================================================
  // Environment Configuration
  // ============================================================
  
  /// Current environment
  static const Environment environment = Environment.development;
  
  /// Is production environment
  static bool get isProduction => environment == Environment.production;
  
  /// Is development environment
  static bool get isDevelopment => environment == Environment.development;

  // ============================================================
  // Helper Methods
  // ============================================================
  
  /// Get API endpoint URL
  static String getApiEndpoint(String endpoint) {
    return '$apiBaseUrl/$apiVersion/$endpoint';
  }
  
  /// Get function URL with key
  static String getFunctionUrl(String functionName) {
    return '$apiBaseUrl/$functionName?code=$functionHostKey';
  }
}

/// Environment types
enum Environment {
  development,
  staging,
  production,
}

/// API Endpoints
class ApiEndpoints {
  ApiEndpoints._();
  
  // Weighing Tickets
  static const String weighingTickets = 'weighing-tickets';
  static const String syncWeighingTickets = 'sync/weighing-tickets';
  
  // Vehicles
  static const String vehicles = 'vehicles';
  static const String vehicleByPlate = 'vehicles/by-plate';
  
  // Customers
  static const String customers = 'customers';
  
  // Products
  static const String products = 'products';
  
  // Images
  static const String uploadImage = 'images/upload';
  static const String getImage = 'images';
  
  // Reports
  static const String dailyReport = 'reports/daily';
  static const String monthlyReport = 'reports/monthly';
  static const String vehicleReport = 'reports/vehicle';
  
  // Notifications
  static const String notifications = 'notifications';
  static const String notificationSettings = 'notifications/settings';
  
  // Device Status
  static const String deviceStatus = 'devices/status';
  static const String deviceHeartbeat = 'devices/heartbeat';
}
