# Azure SQL Database - Canoto Weighing Station

## 📋 Thông tin kết nối

| Property | Value |
|----------|-------|
| **Server** | `sql-tramcan-hieu.database.windows.net` |
| **Database** | `sql-tramcan-hieu` |
| **Port** | 1433 |
| **User** | `tramcan_admin` |

## 🗂️ Cấu trúc Database

### Tables (Bảng dữ liệu)

| Bảng | Mô tả | Số cột |
|------|-------|--------|
| `WeighingTickets` | Phiếu cân - bảng giao dịch chính | 26 |
| `Customers` | Khách hàng | 14 |
| `Vehicles` | Phương tiện/Xe | 14 |
| `Products` | Sản phẩm/Hàng hóa | 12 |
| `WeighingStations` | Trạm cân | 10 |
| `Operators` | Nhân viên vận hành | 10 |
| `SyncLogs` | Lịch sử đồng bộ | 9 |

### Sơ đồ quan hệ

```
┌─────────────────┐     ┌─────────────────┐
│   Customers     │────<│    Vehicles     │
│                 │     │                 │
│ - Id (PK)       │     │ - Id (PK)       │
│ - Code          │     │ - LicensePlate  │
│ - Name          │     │ - CustomerId(FK)│
│ - Phone         │     │ - TareWeight    │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │    ┌──────────────────┘
         │    │
         ▼    ▼
┌─────────────────────────────────────────┐
│           WeighingTickets                │
│                                          │
│ - Id (PK)          - FirstWeight         │
│ - TicketNumber     - SecondWeight        │
│ - VehiclePlate     - NetWeight           │
│ - CustomerId (FK)  - UnitPrice           │
│ - ProductId (FK)   - TotalAmount         │
│ - Status           - IsSynced            │
└─────────────────────────────────────────┘
         ▲
         │
┌────────┴────────┐
│    Products     │
│                 │
│ - Id (PK)       │
│ - Code          │
│ - Name          │
│ - UnitPrice     │
└─────────────────┘
```

## 📊 Chi tiết các bảng

### 1. WeighingTickets (Phiếu cân)

```sql
-- Các trạng thái (Status)
-- 'pending'    : Đang chờ cân lần 2
-- 'completed'  : Hoàn thành
-- 'cancelled'  : Đã hủy

-- Cột quan trọng
Id              NVARCHAR(50)   -- GUID, Primary Key
TicketNumber    NVARCHAR(50)   -- Số phiếu: PC20260109001
VehiclePlate    NVARCHAR(20)   -- Biển số: 29A-12345
FirstWeight     FLOAT          -- Cân lần 1 (kg)
SecondWeight    FLOAT          -- Cân lần 2 (kg)
NetWeight       FLOAT          -- = |FirstWeight - SecondWeight|
UnitPrice       FLOAT          -- Đơn giá (VND/kg)
TotalAmount     FLOAT          -- = NetWeight × UnitPrice
IsSynced        BIT            -- 0: Chưa đồng bộ, 1: Đã đồng bộ
```

### 2. Customers (Khách hàng)

```sql
Id              NVARCHAR(50)   -- GUID
Code            NVARCHAR(50)   -- Mã: KH001
Name            NVARCHAR(200)  -- Tên khách hàng
Phone           NVARCHAR(20)   -- Số điện thoại
CustomerType    NVARCHAR(20)   -- 'individual' / 'company'
```

### 3. Vehicles (Phương tiện)

```sql
Id              NVARCHAR(50)   -- GUID
LicensePlate    NVARCHAR(20)   -- Biển số (UNIQUE)
VehicleType     NVARCHAR(50)   -- 'truck' / 'trailer' / 'container'
TareWeight      FLOAT          -- Trọng lượng bì mặc định (kg)
CustomerId      NVARCHAR(50)   -- FK → Customers
```

### 4. Products (Sản phẩm)

```sql
Id              NVARCHAR(50)   -- GUID
Code            NVARCHAR(50)   -- Mã: SP001
Name            NVARCHAR(200)  -- Tên sản phẩm
Unit            NVARCHAR(20)   -- 'kg' / 'tan' / 'm3'
UnitPrice       FLOAT          -- Đơn giá mặc định
Category        NVARCHAR(100)  -- Danh mục
```

## 🔧 Cách sử dụng

### 1. Tạo Database mới

```bash
# Mở Azure Portal → SQL Database → Query editor
# Chạy file: create_database.sql
```

### 2. Test queries

```bash
# Chạy file: sample_queries.sql
```

### 3. Kết nối từ Flutter App

Connection string:
```
Server=tcp:sql-tramcan-hieu.database.windows.net,1433;
Initial Catalog=sql-tramcan-hieu;
User ID=tramcan_admin;
Password=YOUR_PASSWORD;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
```

### 4. Kết nối từ Azure Functions

Thêm vào `local.settings.json`:
```json
{
  "Values": {
    "SqlConnectionString": "Server=tcp:sql-tramcan-hieu.database.windows.net,1433;Initial Catalog=sql-tramcan-hieu;User ID=tramcan_admin;Password=YOUR_PASSWORD;Encrypt=True;"
  }
}
```

## 📈 Stored Procedures

| Procedure | Mô tả |
|-----------|-------|
| `sp_GetDailyStats` | Thống kê theo ngày |
| `sp_GetMonthlyStats` | Thống kê theo tháng |
| `sp_GetTopCustomers` | Top khách hàng |
| `sp_GetTopProducts` | Top sản phẩm |

### Ví dụ gọi Stored Procedure

```sql
-- Thống kê hôm nay
EXEC sp_GetDailyStats;

-- Thống kê ngày cụ thể
EXEC sp_GetDailyStats @Date = '2026-01-09';

-- Top 10 khách hàng trong 30 ngày
EXEC sp_GetTopCustomers @TopN = 10;
```

## 🔄 Sync Flow (Quy trình đồng bộ)

```
┌─────────────┐                    ┌─────────────┐
│ Flutter App │                    │ Azure SQL   │
│ (Local DB)  │                    │ (Cloud)     │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │ 1. Create ticket (IsSynced=0)    │
       ├──────────────────────────────────>
       │                                  │
       │ 2. POST /weighing-tickets        │
       ├─────────────────────────────────>│
       │                                  │
       │ 3. Azure Functions insert        │
       │<─────────────────────────────────┤
       │                                  │
       │ 4. Update local (IsSynced=1)     │
       ├──────────────────────────────────>
       │                                  │
```

## 🔐 Bảo mật

1. **SQL Firewall**: Chỉ cho phép Azure services và IP cố định
2. **Connection String**: Lưu trong Azure Key Vault hoặc App Settings
3. **Soft Delete**: Không xóa vĩnh viễn, chỉ đánh dấu `IsDeleted = 1`
4. **Audit Trail**: Mọi bản ghi có `CreatedAt`, `UpdatedAt`

## 📝 Files trong thư mục này

| File | Mô tả |
|------|-------|
| `create_database.sql` | Script tạo database đầy đủ |
| `sample_queries.sql` | Các query mẫu để test |
| `schema.sql` | Schema cũ (backup) |
| `README.md` | File này |
