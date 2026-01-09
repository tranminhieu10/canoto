-- =====================================================
-- SQL Database Schema for Canoto - Weighing Station App
-- Azure SQL Database: sql-tramcan-hieu
-- Server: sql-tramcan-hieu.database.windows.net
-- Created: 2026-01-09
-- =====================================================

-- =====================================================
-- DROP existing tables (for fresh install)
-- =====================================================
IF OBJECT_ID('dbo.WeighingTickets', 'U') IS NOT NULL 
    DROP TABLE dbo.WeighingTickets;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL 
    DROP TABLE dbo.Customers;
IF OBJECT_ID('dbo.Vehicles', 'U') IS NOT NULL 
    DROP TABLE dbo.Vehicles;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL 
    DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.SyncLogs', 'U') IS NOT NULL 
    DROP TABLE dbo.SyncLogs;
IF OBJECT_ID('dbo.Operators', 'U') IS NOT NULL 
    DROP TABLE dbo.Operators;
IF OBJECT_ID('dbo.WeighingStations', 'U') IS NOT NULL 
    DROP TABLE dbo.WeighingStations;

GO

-- =====================================================
-- TABLE: Customers (Khách hàng)
-- =====================================================
CREATE TABLE dbo.Customers (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Business fields
    Code NVARCHAR(50) NULL,                      -- Mã khách hàng (KH001)
    Name NVARCHAR(200) NOT NULL,                 -- Tên khách hàng
    Phone NVARCHAR(20) NULL,                     -- Số điện thoại
    Email NVARCHAR(100) NULL,                    -- Email
    Address NVARCHAR(500) NULL,                  -- Địa chỉ
    TaxCode NVARCHAR(20) NULL,                   -- Mã số thuế
    ContactPerson NVARCHAR(100) NULL,            -- Người liên hệ
    Notes NVARCHAR(1000) NULL,                   -- Ghi chú
    CustomerType NVARCHAR(20) DEFAULT 'individual', -- Loại: individual, company
    
    -- Status fields
    IsActive BIT DEFAULT 1,                      -- Còn hoạt động
    IsDeleted BIT DEFAULT 0,                     -- Đã xóa (soft delete)
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Indexes for Customers
CREATE INDEX IX_Customers_Code ON dbo.Customers(Code);
CREATE INDEX IX_Customers_Name ON dbo.Customers(Name);
CREATE INDEX IX_Customers_Phone ON dbo.Customers(Phone);
CREATE INDEX IX_Customers_IsActive ON dbo.Customers(IsActive) WHERE IsDeleted = 0;

GO

-- =====================================================
-- TABLE: Vehicles (Phương tiện/Xe)
-- =====================================================
CREATE TABLE dbo.Vehicles (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Vehicle info - LicensePlate is used by Azure Functions
    LicensePlate NVARCHAR(20) NOT NULL,          -- Biển số xe (29A-12345)
    PlateNumber NVARCHAR(20) NULL,               -- Alias for LicensePlate (compatibility)
    VehicleType NVARCHAR(50) NULL,               -- Loại xe: truck, trailer, container
    TareWeight FLOAT NULL,                        -- Trọng lượng bì mặc định (kg)
    
    -- Owner info
    CustomerId NVARCHAR(50) NULL,                -- FK to Customers
    CustomerName NVARCHAR(200) NULL,             -- Denormalized for quick access
    DriverName NVARCHAR(100) NULL,               -- Tên tài xế mặc định
    DriverPhone NVARCHAR(20) NULL,               -- SĐT tài xế
    
    -- Additional info
    Notes NVARCHAR(1000) NULL,
    
    -- Status fields
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Indexes for Vehicles
CREATE UNIQUE INDEX IX_Vehicles_LicensePlate ON dbo.Vehicles(LicensePlate) WHERE IsDeleted = 0;
CREATE INDEX IX_Vehicles_CustomerId ON dbo.Vehicles(CustomerId);
CREATE INDEX IX_Vehicles_IsActive ON dbo.Vehicles(IsActive) WHERE IsDeleted = 0;

GO

-- =====================================================
-- TABLE: Products (Sản phẩm/Hàng hóa)
-- =====================================================
CREATE TABLE dbo.Products (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Product info
    Code NVARCHAR(50) NULL,                      -- Mã sản phẩm (SP001)
    Name NVARCHAR(200) NOT NULL,                 -- Tên sản phẩm
    Description NVARCHAR(1000) NULL,             -- Mô tả
    Unit NVARCHAR(20) DEFAULT 'kg',              -- Đơn vị: kg, tan, m3
    UnitPrice FLOAT NULL,                         -- Đơn giá mặc định
    DefaultPrice FLOAT NULL,                      -- Alias for UnitPrice
    Category NVARCHAR(100) NULL,                 -- Danh mục: thủy sản, nông sản, vật liệu
    
    -- Status fields
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Indexes for Products
CREATE INDEX IX_Products_Code ON dbo.Products(Code);
CREATE INDEX IX_Products_Name ON dbo.Products(Name);
CREATE INDEX IX_Products_Category ON dbo.Products(Category);
CREATE INDEX IX_Products_IsActive ON dbo.Products(IsActive) WHERE IsDeleted = 0;

GO

-- =====================================================
-- TABLE: WeighingStations (Trạm cân)
-- =====================================================
CREATE TABLE dbo.WeighingStations (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Station info
    Code NVARCHAR(50) NULL,                      -- Mã trạm (TC01)
    Name NVARCHAR(200) NOT NULL,                 -- Tên trạm
    Location NVARCHAR(500) NULL,                 -- Vị trí
    ScaleType NVARCHAR(50) NULL,                 -- Loại cân: NHB3000, A&D, Mettler
    MaxCapacity FLOAT NULL,                       -- Tải trọng tối đa (kg)
    
    -- IoT info
    IotDeviceId NVARCHAR(100) NULL,              -- Azure IoT Hub Device ID
    LastOnlineAt DATETIME2 NULL,                 -- Lần kết nối cuối
    
    -- Status fields
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

GO

-- =====================================================
-- TABLE: Operators (Nhân viên vận hành)
-- =====================================================
CREATE TABLE dbo.Operators (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Operator info
    Code NVARCHAR(50) NULL,                      -- Mã nhân viên (NV001)
    Name NVARCHAR(200) NOT NULL,                 -- Họ tên
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    Role NVARCHAR(50) DEFAULT 'operator',        -- operator, admin, viewer
    
    -- Status fields
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0,
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

GO

-- =====================================================
-- TABLE: WeighingTickets (Phiếu cân)
-- This is the main transaction table
-- =====================================================
CREATE TABLE dbo.WeighingTickets (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY,
    
    -- Ticket identification
    TicketNumber NVARCHAR(50) NOT NULL,          -- Số phiếu (PC20260109001)
    
    -- Vehicle info
    VehiclePlate NVARCHAR(20) NOT NULL,          -- Biển số xe
    VehicleId NVARCHAR(50) NULL,                 -- FK to Vehicles (optional)
    
    -- Customer info (denormalized for performance)
    CustomerId NVARCHAR(50) NULL,                -- FK to Customers
    CustomerName NVARCHAR(200) NULL,             -- Tên khách hàng
    
    -- Product info (denormalized)
    ProductId NVARCHAR(50) NULL,                 -- FK to Products
    ProductName NVARCHAR(200) NULL,              -- Tên hàng hóa
    
    -- Weight measurements (in kg)
    FirstWeight FLOAT DEFAULT 0,                  -- Cân lần 1 (Gross/Tare)
    SecondWeight FLOAT DEFAULT 0,                 -- Cân lần 2 (Tare/Gross)
    NetWeight FLOAT DEFAULT 0,                    -- Trọng lượng hàng = |FirstWeight - SecondWeight|
    
    -- Pricing
    UnitPrice FLOAT NULL,                         -- Đơn giá (VND/kg)
    TotalAmount FLOAT NULL,                       -- Thành tiền = NetWeight * UnitPrice
    
    -- Timestamps
    FirstWeighTime DATETIME2 NULL,               -- Thời gian cân lần 1
    SecondWeighTime DATETIME2 NULL,              -- Thời gian cân lần 2
    
    -- Status
    Status NVARCHAR(20) DEFAULT 'pending',       -- pending, completed, cancelled
    
    -- Notes and images
    Notes NVARCHAR(2000) NULL,                   -- Ghi chú
    FirstWeighImageUrl NVARCHAR(500) NULL,       -- URL ảnh cân lần 1 (Azure Blob)
    SecondWeighImageUrl NVARCHAR(500) NULL,      -- URL ảnh cân lần 2
    
    -- Operator info
    OperatorId NVARCHAR(50) NULL,                -- FK to Operators
    OperatorName NVARCHAR(100) NULL,             -- Tên nhân viên cân
    
    -- Station info
    StationId NVARCHAR(50) DEFAULT 'scale-station-01', -- FK to WeighingStations
    
    -- Sync status
    IsSynced BIT DEFAULT 0,                      -- Đã đồng bộ lên cloud
    SyncedAt DATETIME2 NULL,                     -- Thời gian đồng bộ
    
    -- Status fields
    IsDeleted BIT DEFAULT 0,                     -- Soft delete
    
    -- Audit fields
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
);

-- Indexes for WeighingTickets
CREATE UNIQUE INDEX IX_WeighingTickets_TicketNumber ON dbo.WeighingTickets(TicketNumber) WHERE IsDeleted = 0;
CREATE INDEX IX_WeighingTickets_VehiclePlate ON dbo.WeighingTickets(VehiclePlate);
CREATE INDEX IX_WeighingTickets_CustomerId ON dbo.WeighingTickets(CustomerId);
CREATE INDEX IX_WeighingTickets_ProductId ON dbo.WeighingTickets(ProductId);
CREATE INDEX IX_WeighingTickets_Status ON dbo.WeighingTickets(Status) WHERE IsDeleted = 0;
CREATE INDEX IX_WeighingTickets_CreatedAt ON dbo.WeighingTickets(CreatedAt DESC);
CREATE INDEX IX_WeighingTickets_FirstWeighTime ON dbo.WeighingTickets(FirstWeighTime);
CREATE INDEX IX_WeighingTickets_IsSynced ON dbo.WeighingTickets(IsSynced) WHERE IsDeleted = 0;
CREATE INDEX IX_WeighingTickets_StationId ON dbo.WeighingTickets(StationId);

GO

-- =====================================================
-- TABLE: SyncLogs (Lịch sử đồng bộ)
-- =====================================================
CREATE TABLE dbo.SyncLogs (
    -- Primary Key
    Id NVARCHAR(50) NOT NULL PRIMARY KEY DEFAULT NEWID(),
    
    -- Sync info
    StationId NVARCHAR(50) NOT NULL,             -- Trạm cân
    SyncType NVARCHAR(50) NOT NULL,              -- upload, download, full
    EntityType NVARCHAR(50) NULL,                -- WeighingTickets, Customers, etc.
    RecordsCount INT DEFAULT 0,                  -- Số bản ghi đồng bộ
    
    -- Result
    Status NVARCHAR(20) NOT NULL,                -- success, failed, partial
    ErrorMessage NVARCHAR(2000) NULL,
    
    -- Timing
    StartedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CompletedAt DATETIME2 NULL,
    DurationMs INT NULL                          -- Thời gian xử lý (ms)
);

-- Index for SyncLogs
CREATE INDEX IX_SyncLogs_StationId ON dbo.SyncLogs(StationId);
CREATE INDEX IX_SyncLogs_StartedAt ON dbo.SyncLogs(StartedAt DESC);

GO

-- =====================================================
-- INSERT Default Data
-- =====================================================

-- Default Weighing Station
INSERT INTO dbo.WeighingStations (Id, Code, Name, Location, ScaleType, MaxCapacity)
VALUES ('scale-station-01', 'TC01', 'Trạm cân chính', 'Cảng cá Phan Thiết', 'A&D GF-40K', 40000);

-- Sample Customers
INSERT INTO dbo.Customers (Id, Code, Name, Phone, CustomerType)
VALUES 
    (NEWID(), 'KH001', 'Công ty TNHH Thủy sản Bình Thuận', '0252-123456', 'company'),
    (NEWID(), 'KH002', 'Hợp tác xã Nuôi trồng Thủy sản', '0252-234567', 'company'),
    (NEWID(), 'KH003', 'Nguyễn Văn A', '0909123456', 'individual');

-- Sample Products
INSERT INTO dbo.Products (Id, Code, Name, Unit, UnitPrice, Category)
VALUES 
    (NEWID(), 'SP001', 'Tôm sú', 'kg', 150000, 'Thủy sản'),
    (NEWID(), 'SP002', 'Cá tra', 'kg', 45000, 'Thủy sản'),
    (NEWID(), 'SP003', 'Cá basa', 'kg', 40000, 'Thủy sản'),
    (NEWID(), 'SP004', 'Nghêu', 'kg', 35000, 'Thủy sản'),
    (NEWID(), 'SP005', 'Ốc hương', 'kg', 200000, 'Thủy sản');

-- Sample Vehicles
INSERT INTO dbo.Vehicles (Id, LicensePlate, PlateNumber, VehicleType, TareWeight)
VALUES 
    (NEWID(), '29A-12345', '29A-12345', 'truck', 3500),
    (NEWID(), '51C-98765', '51C-98765', 'trailer', 5200),
    (NEWID(), '86B-55555', '86B-55555', 'truck', 2800);

-- Default Operator
INSERT INTO dbo.Operators (Id, Code, Name, Role)
VALUES ('operator-01', 'NV001', 'Admin', 'admin');

GO

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Get daily statistics
CREATE OR ALTER PROCEDURE sp_GetDailyStats
    @Date DATE = NULL,
    @StationId NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Date IS NULL SET @Date = CAST(GETDATE() AS DATE);
    
    SELECT 
        @Date AS ReportDate,
        COUNT(*) AS TotalTickets,
        COUNT(CASE WHEN Status = 'completed' THEN 1 END) AS CompletedTickets,
        COUNT(CASE WHEN Status = 'pending' THEN 1 END) AS PendingTickets,
        COUNT(CASE WHEN Status = 'cancelled' THEN 1 END) AS CancelledTickets,
        ISNULL(SUM(NetWeight), 0) AS TotalNetWeight,
        ISNULL(SUM(TotalAmount), 0) AS TotalRevenue,
        ISNULL(AVG(NetWeight), 0) AS AvgNetWeight
    FROM dbo.WeighingTickets
    WHERE CAST(CreatedAt AS DATE) = @Date
    AND IsDeleted = 0
    AND (@StationId IS NULL OR StationId = @StationId);
END
GO

-- Get monthly statistics
CREATE OR ALTER PROCEDURE sp_GetMonthlyStats
    @Year INT = NULL,
    @Month INT = NULL,
    @StationId NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Year IS NULL SET @Year = YEAR(GETDATE());
    IF @Month IS NULL SET @Month = MONTH(GETDATE());
    
    SELECT 
        CAST(CreatedAt AS DATE) AS ReportDate,
        COUNT(*) AS TotalTickets,
        ISNULL(SUM(NetWeight), 0) AS TotalNetWeight,
        ISNULL(SUM(TotalAmount), 0) AS TotalRevenue
    FROM dbo.WeighingTickets
    WHERE YEAR(CreatedAt) = @Year 
    AND MONTH(CreatedAt) = @Month
    AND IsDeleted = 0
    AND Status = 'completed'
    AND (@StationId IS NULL OR StationId = @StationId)
    GROUP BY CAST(CreatedAt AS DATE)
    ORDER BY ReportDate;
END
GO

-- Get top customers by weight
CREATE OR ALTER PROCEDURE sp_GetTopCustomers
    @TopN INT = 10,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @FromDate IS NULL SET @FromDate = DATEADD(MONTH, -1, GETDATE());
    IF @ToDate IS NULL SET @ToDate = GETDATE();
    
    SELECT TOP (@TopN)
        CustomerId,
        CustomerName,
        COUNT(*) AS TicketCount,
        SUM(NetWeight) AS TotalWeight,
        SUM(TotalAmount) AS TotalAmount
    FROM dbo.WeighingTickets
    WHERE CreatedAt BETWEEN @FromDate AND @ToDate
    AND IsDeleted = 0
    AND Status = 'completed'
    AND CustomerId IS NOT NULL
    GROUP BY CustomerId, CustomerName
    ORDER BY TotalWeight DESC;
END
GO

-- Get top products by weight
CREATE OR ALTER PROCEDURE sp_GetTopProducts
    @TopN INT = 10,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @FromDate IS NULL SET @FromDate = DATEADD(MONTH, -1, GETDATE());
    IF @ToDate IS NULL SET @ToDate = GETDATE();
    
    SELECT TOP (@TopN)
        ProductId,
        ProductName,
        COUNT(*) AS TicketCount,
        SUM(NetWeight) AS TotalWeight,
        SUM(TotalAmount) AS TotalAmount
    FROM dbo.WeighingTickets
    WHERE CreatedAt BETWEEN @FromDate AND @ToDate
    AND IsDeleted = 0
    AND Status = 'completed'
    AND ProductId IS NOT NULL
    GROUP BY ProductId, ProductName
    ORDER BY TotalWeight DESC;
END
GO

-- =====================================================
-- VIEWS for Reporting
-- =====================================================

-- View: Today's tickets
CREATE OR ALTER VIEW vw_TodayTickets
AS
SELECT 
    Id, TicketNumber, VehiclePlate, CustomerName, ProductName,
    FirstWeight, SecondWeight, NetWeight, TotalAmount, Status,
    FirstWeighTime, SecondWeighTime, OperatorName, StationId
FROM dbo.WeighingTickets
WHERE CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE)
AND IsDeleted = 0;
GO

-- View: Pending tickets
CREATE OR ALTER VIEW vw_PendingTickets
AS
SELECT 
    Id, TicketNumber, VehiclePlate, CustomerName, ProductName,
    FirstWeight, FirstWeighTime, OperatorName, StationId, CreatedAt
FROM dbo.WeighingTickets
WHERE Status = 'pending'
AND IsDeleted = 0;
GO

-- View: Active customers with vehicle count
CREATE OR ALTER VIEW vw_CustomersWithVehicles
AS
SELECT 
    c.Id, c.Code, c.Name, c.Phone, c.CustomerType,
    COUNT(v.Id) AS VehicleCount
FROM dbo.Customers c
LEFT JOIN dbo.Vehicles v ON c.Id = v.CustomerId AND v.IsDeleted = 0
WHERE c.IsDeleted = 0 AND c.IsActive = 1
GROUP BY c.Id, c.Code, c.Name, c.Phone, c.CustomerType;
GO

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update UpdatedAt timestamp
CREATE OR ALTER TRIGGER tr_WeighingTickets_UpdatedAt
ON dbo.WeighingTickets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.WeighingTickets
    SET UpdatedAt = GETUTCDATE()
    FROM dbo.WeighingTickets t
    INNER JOIN inserted i ON t.Id = i.Id;
END
GO

CREATE OR ALTER TRIGGER tr_Customers_UpdatedAt
ON dbo.Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Customers
    SET UpdatedAt = GETUTCDATE()
    FROM dbo.Customers c
    INNER JOIN inserted i ON c.Id = i.Id;
END
GO

CREATE OR ALTER TRIGGER tr_Vehicles_UpdatedAt
ON dbo.Vehicles
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Vehicles
    SET UpdatedAt = GETUTCDATE()
    FROM dbo.Vehicles v
    INNER JOIN inserted i ON v.Id = i.Id;
END
GO

CREATE OR ALTER TRIGGER tr_Products_UpdatedAt
ON dbo.Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Products
    SET UpdatedAt = GETUTCDATE()
    FROM dbo.Products p
    INNER JOIN inserted i ON p.Id = i.Id;
END
GO

-- =====================================================
-- PRINT Summary
-- =====================================================
PRINT '================================================='
PRINT 'Database schema created successfully!'
PRINT '================================================='
PRINT 'Tables created:'
PRINT '  - Customers'
PRINT '  - Vehicles'
PRINT '  - Products'
PRINT '  - WeighingStations'
PRINT '  - Operators'
PRINT '  - WeighingTickets'
PRINT '  - SyncLogs'
PRINT ''
PRINT 'Stored Procedures:'
PRINT '  - sp_GetDailyStats'
PRINT '  - sp_GetMonthlyStats'
PRINT '  - sp_GetTopCustomers'
PRINT '  - sp_GetTopProducts'
PRINT ''
PRINT 'Views:'
PRINT '  - vw_TodayTickets'
PRINT '  - vw_PendingTickets'
PRINT '  - vw_CustomersWithVehicles'
PRINT '================================================='
GO
