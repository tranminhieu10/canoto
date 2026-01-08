/// Azure Configuration Constants
/// 
/// IMPORTANT: Security Notice
/// ========================
/// This file contains placeholder values for Azure secrets.
/// In production, use one of these approaches:
/// 
/// 1. Environment Variables (Recommended for Desktop):
///    - Create a .env file (add to .gitignore!)
///    - Use flutter_dotenv package to load values
///    - Example: String.fromEnvironment('STORAGE_KEY')
/// 
/// 2. Secure Storage:
///    - Use flutter_secure_storage for sensitive data
///    - Load credentials at runtime, never hardcode
/// 
/// 3. Azure Key Vault:
///    - For enterprise apps, fetch secrets from Key Vault
///    - Use Azure AD authentication to access
/// 
/// Never commit actual secrets to version control!
/// 
class AzureConfig {
  AzureConfig._();

  // ============================================================
  // Azure Functions API Configuration
  // ============================================================
  
  /// Base URL for Azure Functions API
  static const String apiBaseUrl = 'https://func-tramcan-hieu.azurewebsites.net/api';
  
  /// Azure Functions Host Key (for function-level authorization)
  /// IMPORTANT: Load from environment or secure storage in production!
  static const String functionHostKey = String.fromEnvironment(
    'AZURE_FUNCTION_KEY',
    defaultValue: '', // Set via --dart-define or .env file
  );
  
  /// API Version
  static const String apiVersion = 'v1';
  
  /// API Timeout in seconds
  static const int apiTimeout = 30;

  // ============================================================
  // Azure SQL Database Configuration
  // ============================================================
  
  /// SQL Server hostname
  static const String sqlServerHost = 'sql-tramcan-hieu.database.windows.net';
  
  /// SQL Database name
  static const String sqlDatabaseName = 'sql-tramcan-hieu';
  
  /// SQL Server port
  static const int sqlServerPort = 1433;
  
  /// SQL Connection String (for reference - use secure storage in production)
  /// Server=tcp:sql-tramcan-hieu.database.windows.net,1433;Initial Catalog=sql-tramcan-hieu;...

  // ============================================================
  // Azure Blob Storage Configuration
  // ============================================================
  
  /// Storage Account Name
  static const String storageAccountName = 'strtramcanhieu';
  
  /// Storage Account Key (keep secure! - load from environment in production)
  static const String storageAccountKey = String.fromEnvironment(
    'AZURE_STORAGE_KEY',
    defaultValue: '', // Set via --dart-define or .env file
  );
  
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
  
  /// SignalR Hub URL (connect through Azure Functions for negotiate)
  static const String signalRHubUrl = 
      'https://func-tramcan-hieu.azurewebsites.net/api/notificationHub';
  
  /// SignalR Service Endpoint
  static const String signalREndpoint = 'https://sig-tramcan-hieu.service.signalr.net';
  
  /// SignalR Access Key
  static const String signalRAccessKey = String.fromEnvironment(
    'AZURE_SIGNALR_KEY',
    defaultValue: '', // Set via --dart-define or .env file
  );

  // ============================================================
  // Azure IoT Hub Configuration
  // ============================================================
  
  /// IoT Hub Hostname
  static const String iotHubHostname = 'iot-tramcan-hieu.azure-devices.net';
  
  /// IoT Hub Device Connection String
  static const String iotHubConnectionString = String.fromEnvironment(
    'AZURE_IOT_CONNECTION_STRING',
    defaultValue: '', // Set via --dart-define or .env file
  );
  
  /// Device ID for this weighing station
  static const String iotDeviceId = 'scale-station-01';
  
  /// Shared Access Key for device
  static const String iotDeviceKey = String.fromEnvironment(
    'AZURE_IOT_DEVICE_KEY',
    defaultValue: '', // Set via --dart-define or .env file
  );
  
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
