# TramCanFunctions - Azure Functions Backend

Azure Functions backend cho hệ thống Trạm Cân (Weighing Station).

## 📋 Danh sách API Endpoints

### SignalR Functions
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/negotiate` | Lấy connection info cho SignalR |
| POST | `/api/broadcast` | Gửi message đến tất cả clients |
| POST | `/api/sendToGroup/{groupName}` | Gửi message đến group |
| POST | `/api/notify/weighing-ticket` | Thông báo cập nhật phiếu cân |
| POST | `/api/notify/sync` | Thông báo sync dữ liệu |

### Weighing Tickets API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/weighing-tickets` | Lấy danh sách phiếu cân (có phân trang) |
| GET | `/api/weighing-tickets/{id}` | Lấy phiếu cân theo ID |
| POST | `/api/weighing-tickets` | Tạo phiếu cân mới |
| PUT | `/api/weighing-tickets/{id}` | Cập nhật phiếu cân |
| DELETE | `/api/weighing-tickets/{id}` | Xóa phiếu cân (soft delete) |

### Customers API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/customers` | Lấy danh sách khách hàng |
| GET | `/api/customers/{id}` | Lấy khách hàng theo ID |
| POST | `/api/customers` | Tạo khách hàng mới |
| PUT | `/api/customers/{id}` | Cập nhật khách hàng |
| DELETE | `/api/customers/{id}` | Xóa khách hàng |

### Vehicles API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/vehicles` | Lấy danh sách xe |
| GET | `/api/vehicles/{id}` | Lấy xe theo ID |
| GET | `/api/vehicles/plate/{plateNumber}` | Lấy xe theo biển số |
| POST | `/api/vehicles` | Tạo xe mới |
| PUT | `/api/vehicles/{id}` | Cập nhật xe |
| DELETE | `/api/vehicles/{id}` | Xóa xe |

### Products API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/products` | Lấy danh sách sản phẩm |
| GET | `/api/products/{id}` | Lấy sản phẩm theo ID |
| POST | `/api/products` | Tạo sản phẩm mới |
| PUT | `/api/products/{id}` | Cập nhật sản phẩm |
| DELETE | `/api/products/{id}` | Xóa sản phẩm |

### Blob Storage API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/images/upload` | Upload hình ảnh |
| GET | `/api/images/{blobPath}` | Lấy URL hình ảnh |
| DELETE | `/api/images/{blobPath}` | Xóa hình ảnh |
| GET | `/api/images` | Liệt kê hình ảnh |

### Sync API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/sync/changes` | Lấy thay đổi từ server |
| POST | `/api/sync/push` | Đẩy thay đổi lên server |
| POST | `/api/sync/full` | Sync hai chiều |

### Reports API
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/api/reports/daily` | Báo cáo theo ngày |
| GET | `/api/reports/statistics` | Thống kê tổng hợp |
| GET | `/api/reports/customer/{customerId}` | Báo cáo theo khách hàng |

## 🚀 Deploy lên Azure

### Yêu cầu
- Azure CLI đã đăng nhập
- Azure Subscription
- Resource Group đã tạo

### Các bước deploy

1. **Tạo Azure Resources** (nếu chưa có):
```bash
# Tạo Resource Group
az group create --name rg-tramcan-hieu --location southeastasia

# Tạo Storage Account
az storage account create --name sttramcanhieu --resource-group rg-tramcan-hieu --location southeastasia --sku Standard_LRS

# Tạo Function App
az functionapp create --resource-group rg-tramcan-hieu --consumption-plan-location southeastasia --runtime dotnet-isolated --runtime-version 8 --functions-version 4 --name func-tramcan-hieu --storage-account sttramcanhieu

# Tạo SignalR Service
az signalr create --name sig-tramcan-hieu --resource-group rg-tramcan-hieu --sku Free_F1 --service-mode Serverless

# Tạo Azure SQL Database
az sql server create --name sql-tramcan-hieu --resource-group rg-tramcan-hieu --location southeastasia --admin-user sqladmin --admin-password YourPassword123!
az sql db create --resource-group rg-tramcan-hieu --server sql-tramcan-hieu --name tramcan-db --edition Basic
```

2. **Cấu hình App Settings**:
```bash
# Lấy SignalR connection string
az signalr key list --name sig-tramcan-hieu --resource-group rg-tramcan-hieu --query primaryConnectionString -o tsv

# Cấu hình settings
az functionapp config appsettings set --name func-tramcan-hieu --resource-group rg-tramcan-hieu --settings "AzureSignalRConnectionString=YOUR_SIGNALR_CONNECTION_STRING"
az functionapp config appsettings set --name func-tramcan-hieu --resource-group rg-tramcan-hieu --settings "SqlConnectionString=YOUR_SQL_CONNECTION_STRING"
az functionapp config appsettings set --name func-tramcan-hieu --resource-group rg-tramcan-hieu --settings "AzureBlobStorage=YOUR_STORAGE_CONNECTION_STRING"
```

3. **Build và Publish**:
```bash
cd azure-functions/TramCanFunctions
dotnet publish -c Release -o ./publish
```

4. **Deploy lên Azure**:
```bash
# Zip deploy
cd publish
Compress-Archive -Path * -DestinationPath ../deploy.zip -Force
cd ..
az functionapp deployment source config-zip --resource-group rg-tramcan-hieu --name func-tramcan-hieu --src deploy.zip
```

5. **Tạo Database Schema**:
- Kết nối Azure SQL Database bằng SSMS hoặc Azure Portal Query Editor
- Chạy script `Database/schema.sql`

## 🔧 Chạy Local

1. Cài đặt Azure Functions Core Tools:
```bash
npm install -g azure-functions-core-tools@4
```

2. Cập nhật `local.settings.json` với connection strings thực

3. Chạy Functions:
```bash
cd azure-functions/TramCanFunctions
func start
```

## 📝 Query Parameters

### Weighing Tickets
- `page`: Số trang (mặc định: 1)
- `pageSize`: Số item/trang (mặc định: 50)
- `fromDate`: Từ ngày (ISO format)
- `toDate`: Đến ngày (ISO format)
- `status`: Trạng thái (pending, completed, cancelled)
- `vehiclePlate`: Lọc theo biển số

### Customers/Vehicles/Products
- `page`: Số trang
- `pageSize`: Số item/trang
- `search`: Từ khóa tìm kiếm

### Sync
- `lastSyncTime`: Thời điểm sync cuối (ISO format)
- `stationId`: ID trạm cân

## 📊 Response Format

```json
{
  "success": true,
  "message": "Optional message",
  "data": { ... },
  "totalCount": 100,
  "page": 1,
  "pageSize": 50
}
```

## 🔐 Security Notes

- Các endpoints hiện đang sử dụng `AuthorizationLevel.Anonymous` cho development
- Production cần thay đổi thành `AuthorizationLevel.Function` hoặc sử dụng Azure AD authentication
- Cần cấu hình CORS cho domain của Flutter app

## 📁 Project Structure

```
TramCanFunctions/
├── Functions/
│   ├── SignalRFunctions.cs      # SignalR real-time
│   ├── WeighingTicketFunctions.cs # Phiếu cân CRUD
│   ├── CustomerFunctions.cs     # Khách hàng CRUD
│   ├── VehicleFunctions.cs      # Xe CRUD
│   ├── ProductFunctions.cs      # Sản phẩm CRUD
│   ├── BlobFunctions.cs         # Upload/download hình
│   ├── SyncFunctions.cs         # Sync dữ liệu
│   └── ReportFunctions.cs       # Báo cáo thống kê
├── Models/
│   └── Models.cs                # Data models
├── Services/
│   └── DatabaseService.cs       # Database operations
├── Database/
│   └── schema.sql               # SQL schema
├── Program.cs                   # Entry point
├── host.json                    # Host configuration
└── local.settings.json          # Local settings
```
