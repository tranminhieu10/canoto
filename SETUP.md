# Hướng dẫn Cài đặt Môi trường Phát triển Canoto

## A. Môi trường phát triển (Dev Environment)

### 1. Visual Studio Code
**Tải xuống:** https://code.visualstudio.com/

**Extensions cần thiết:**
- Flutter (Dart-Code.flutter)
- Dart (Dart-Code.dart-code)
- Azure Tools Extension (ms-vscode.vscode-node-azure-pack)
- Azure Data Studio (ms-azuretools.vscode-azuredatastudio)
- Azure Storage Explorer (ms-azuretools.vscode-azurestorage)

**Cài đặt Extensions:**
```bash
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension ms-vscode.vscode-node-azure-pack
```

### 2. Flutter SDK
**Tải xuống:** https://flutter.dev/docs/get-started/install/windows

**Cài đặt:**
```bash
# Tải Flutter SDK và giải nén vào C:\src\flutter
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter

# Thêm vào PATH
# System Properties > Environment Variables > Path > Add: C:\src\flutter\bin

# Kiểm tra cài đặt
flutter doctor
```

### 3. Azure CLI
**Tải xuống:** https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows

**Cài đặt:**
```bash
# Sử dụng winget
winget install Microsoft.AzureCLI

# Đăng nhập Azure
az login

# Kiểm tra
az --version
```

### 4. Azure Data Studio
**Tải xuống:** https://docs.microsoft.com/en-us/sql/azure-data-studio/download

**Cài đặt:** Download và chạy installer
**Mục đích:** Quản lý Azure SQL Database

### 5. Azure Storage Explorer
**Tải xuống:** https://azure.microsoft.com/en-us/features/storage-explorer/

**Cài đặt:** Download và chạy installer
**Mục đích:** Xem, xóa, quản lý file ảnh trong Blob Storage

---

## B. Thư viện lập trình (Libraries)

### Flutter (Desktop/Mobile)

#### 1. mqtt_client (Kết nối IoT Hub)
```yaml
dependencies:
  mqtt_client: ^10.2.0
```

**Sử dụng:**
```dart
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final client = MqttServerClient('your-iot-hub.azure-devices.net', 'clientId');
client.port = 8883;
client.secure = true;
await client.connect('username', 'password');
```

#### 2. signalr_netcore (Nhận thông báo real-time)
```yaml
dependencies:
  signalr_netcore: ^1.3.4
```

**Sử dụng:**
```dart
import 'package:signalr_netcore/signalr_client.dart';

final hubConnection = HubConnectionBuilder()
    .withUrl('https://your-api.azurewebsites.net/notificationHub')
    .build();
    
await hubConnection.start();
hubConnection.on('ReceiveNotification', (message) {
  print('Received: $message');
});
```

#### 3. http (Upload ảnh)
```yaml
dependencies:
  http: ^1.2.0
```

**Sử dụng:**
```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> uploadImage(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://your-api.azurewebsites.net/api/upload'),
  );
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
  var response = await request.send();
}
```

### Azure Function (C#)

#### 1. Microsoft.Azure.WebJobs.Extensions.SignalRService
```xml
<PackageReference Include="Microsoft.Azure.WebJobs.Extensions.SignalRService" Version="1.10.0" />
```

**Sử dụng:**
```csharp
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;

[FunctionName("SendNotification")]
public static async Task Run(
    [HttpTrigger] HttpRequest req,
    [SignalR(HubName = "notificationHub")] IAsyncCollector<SignalRMessage> signalRMessages)
{
    await signalRMessages.AddAsync(new SignalRMessage
    {
        Target = "ReceiveNotification",
        Arguments = new[] { "Truck entered the scale" }
    });
}
```

#### 2. System.Data.SqlClient (Kết nối SQL)
```xml
<PackageReference Include="System.Data.SqlClient" Version="4.8.5" />
```

**Sử dụng:**
```csharp
using System.Data.SqlClient;

var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString");
using (var connection = new SqlConnection(connectionString))
{
    await connection.OpenAsync();
    var command = new SqlCommand("SELECT * FROM WeighingTickets WHERE IsSynced = 0", connection);
    var reader = await command.ExecuteReaderAsync();
}
```

---

## C. Cài đặt Project

### 1. Clone Repository
```bash
git clone https://github.com/tranminhieu10/canoto.git
cd canoto
```

### 2. Cài đặt Dependencies
```bash
flutter pub get
```

### 3. Cấu hình Azure
Tạo file `lib/core/constants/azure_config.dart`:
```dart
class AzureConfig {
  // Azure Functions API
  static const String apiBaseUrl = 'https://canoto-api.azurewebsites.net/api';
  static const String functionKey = 'YOUR_FUNCTION_KEY_HERE';
  
  // Azure SQL Database
  static const String sqlConnectionString = 'YOUR_SQL_CONNECTION_STRING';
  
  // Azure Storage
  static const String storageAccountName = 'canotostorage';
  static const String storageAccountKey = 'YOUR_STORAGE_KEY';
  static const String blobContainerName = 'weighing-images';
  
  // SignalR Hub
  static const String signalRHubUrl = 'https://canoto-api.azurewebsites.net/notificationHub';
  
  // IoT Hub
  static const String iotHubConnectionString = 'YOUR_IOT_HUB_CONNECTION_STRING';
}
```

### 4. Chạy ứng dụng
```bash
# Windows Desktop
flutter run -d windows

# Android
flutter run -d <device_id>

# iOS
flutter run -d <device_id>
```

---

## D. Cấu hình Azure Resources

### 1. Tạo Azure SQL Database
```bash
# Tạo Resource Group
az group create --name canoto-rg --location southeastasia

# Tạo SQL Server
az sql server create \
  --name canoto-sql-server \
  --resource-group canoto-rg \
  --location southeastasia \
  --admin-user sqladmin \
  --admin-password YourPassword123!

# Tạo Database
az sql db create \
  --resource-group canoto-rg \
  --server canoto-sql-server \
  --name canoto-db \
  --service-objective S0

# Mở Firewall
az sql server firewall-rule create \
  --resource-group canoto-rg \
  --server canoto-sql-server \
  --name AllowAllIps \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255
```

### 2. Tạo Azure Functions
```bash
# Tạo Storage Account
az storage account create \
  --name canotostorage \
  --resource-group canoto-rg \
  --location southeastasia \
  --sku Standard_LRS

# Tạo Function App
az functionapp create \
  --resource-group canoto-rg \
  --consumption-plan-location southeastasia \
  --runtime dotnet \
  --functions-version 4 \
  --name canoto-api \
  --storage-account canotostorage
```

### 3. Tạo SignalR Service
```bash
az signalr create \
  --name canoto-signalr \
  --resource-group canoto-rg \
  --location southeastasia \
  --sku Free_F1
```

### 4. Tạo Blob Storage Container
```bash
az storage container create \
  --name weighing-images \
  --account-name canotostorage \
  --public-access blob
```

---

## E. Database Schema

Chạy script sau trong Azure Data Studio:

```sql
-- Weighing Tickets Table
CREATE TABLE WeighingTickets (
    Id INT PRIMARY KEY IDENTITY(1,1),
    TicketNumber NVARCHAR(50) UNIQUE NOT NULL,
    LicensePlate NVARCHAR(20) NOT NULL,
    VehicleType NVARCHAR(50),
    DriverName NVARCHAR(100),
    DriverPhone NVARCHAR(20),
    CustomerId INT,
    CustomerName NVARCHAR(200),
    ProductId INT,
    ProductName NVARCHAR(200),
    FirstWeight FLOAT,
    FirstWeightTime DATETIME2,
    SecondWeight FLOAT,
    SecondWeightTime DATETIME2,
    NetWeight FLOAT,
    Deduction FLOAT,
    ActualWeight FLOAT,
    UnitPrice MONEY,
    TotalAmount MONEY,
    WeighingType NVARCHAR(20) DEFAULT 'incoming',
    Status NVARCHAR(20) DEFAULT 'pending',
    Note NVARCHAR(MAX),
    FirstWeightImage NVARCHAR(500),
    SecondWeightImage NVARCHAR(500),
    LicensePlateImage NVARCHAR(500),
    ScaleId INT,
    OperatorId NVARCHAR(50),
    OperatorName NVARCHAR(100),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    IsSynced BIT DEFAULT 0,
    AzureId INT,
    SyncedAt DATETIME2,
    INDEX IX_LicensePlate (LicensePlate),
    INDEX IX_CreatedAt (CreatedAt),
    INDEX IX_IsSynced (IsSynced)
);

-- Vehicles Table
CREATE TABLE Vehicles (
    Id INT PRIMARY KEY IDENTITY(1,1),
    LicensePlate NVARCHAR(20) UNIQUE NOT NULL,
    VehicleType NVARCHAR(50),
    Brand NVARCHAR(50),
    Model NVARCHAR(50),
    Color NVARCHAR(30),
    TareWeight FLOAT,
    CustomerId INT,
    CustomerName NVARCHAR(200),
    DriverName NVARCHAR(100),
    DriverPhone NVARCHAR(20),
    Note NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Customers Table
CREATE TABLE Customers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Code NVARCHAR(50) UNIQUE NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    Address NVARCHAR(500),
    TaxCode NVARCHAR(20),
    BankAccount NVARCHAR(50),
    BankName NVARCHAR(100),
    Note NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Products Table
CREATE TABLE Products (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Code NVARCHAR(50) UNIQUE NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100),
    Unit NVARCHAR(20),
    UnitPrice MONEY,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);
```

---

## F. Testing

### Kiểm tra kết nối
```bash
# Test Azure SQL
flutter test test/database_test.dart

# Test Azure Functions API
flutter test test/api_test.dart

# Test Sync Service
flutter test test/sync_test.dart
```

---

## G. Troubleshooting

### Lỗi thường gặp:

1. **Flutter doctor issues:**
```bash
flutter doctor --android-licenses
flutter doctor -v
```

2. **Azure CLI login issues:**
```bash
az logout
az login --use-device-code
```

3. **SQL Connection timeout:**
- Kiểm tra firewall rules
- Verify connection string
- Check network connectivity

4. **SignalR connection failed:**
- Verify SignalR service is running
- Check CORS settings
- Validate connection URL

---

## H. Deployment

### Deploy Azure Functions:
```bash
cd azure-functions
func azure functionapp publish canoto-api
```

### Build Flutter Release:
```bash
# Windows
flutter build windows --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## Liên hệ

- **Email:** tranminhieu10@gmail.com
- **GitHub:** https://github.com/tranminhieu10/canoto
