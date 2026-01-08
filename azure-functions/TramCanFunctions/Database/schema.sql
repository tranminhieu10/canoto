-- Azure SQL Database Schema for Weighing Station (Trạm Cân)
-- Run this script to create all required tables

-- Weighing Tickets Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='WeighingTickets' AND xtype='U')
CREATE TABLE WeighingTickets (
    Id NVARCHAR(50) PRIMARY KEY,
    TicketNumber NVARCHAR(50) NOT NULL,
    VehiclePlate NVARCHAR(20) NOT NULL,
    VehicleId NVARCHAR(50) NULL,
    CustomerId NVARCHAR(50) NULL,
    CustomerName NVARCHAR(200) NULL,
    ProductId NVARCHAR(50) NULL,
    ProductName NVARCHAR(200) NULL,
    FirstWeight FLOAT NOT NULL DEFAULT 0,
    SecondWeight FLOAT NOT NULL DEFAULT 0,
    NetWeight FLOAT NOT NULL DEFAULT 0,
    UnitPrice FLOAT NULL,
    TotalAmount FLOAT NULL,
    FirstWeighTime DATETIME2 NOT NULL,
    SecondWeighTime DATETIME2 NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'pending',
    Notes NVARCHAR(MAX) NULL,
    FirstWeighImageUrl NVARCHAR(500) NULL,
    SecondWeighImageUrl NVARCHAR(500) NULL,
    OperatorId NVARCHAR(50) NULL,
    OperatorName NVARCHAR(200) NULL,
    StationId NVARCHAR(50) NOT NULL DEFAULT 'scale-station-01',
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    IsSynced BIT NOT NULL DEFAULT 1
);
GO

-- Indexes for WeighingTickets
CREATE INDEX IX_WeighingTickets_TicketNumber ON WeighingTickets(TicketNumber);
CREATE INDEX IX_WeighingTickets_VehiclePlate ON WeighingTickets(VehiclePlate);
CREATE INDEX IX_WeighingTickets_CustomerId ON WeighingTickets(CustomerId);
CREATE INDEX IX_WeighingTickets_Status ON WeighingTickets(Status);
CREATE INDEX IX_WeighingTickets_CreatedAt ON WeighingTickets(CreatedAt);
CREATE INDEX IX_WeighingTickets_UpdatedAt ON WeighingTickets(UpdatedAt);
GO

-- Customers Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Customers' AND xtype='U')
CREATE TABLE Customers (
    Id NVARCHAR(50) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(200) NULL,
    Address NVARCHAR(500) NULL,
    TaxCode NVARCHAR(50) NULL,
    ContactPerson NVARCHAR(200) NULL,
    Notes NVARCHAR(MAX) NULL,
    CustomerType NVARCHAR(20) NOT NULL DEFAULT 'individual',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0
);
GO

-- Indexes for Customers
CREATE UNIQUE INDEX IX_Customers_Code ON Customers(Code) WHERE IsDeleted = 0;
CREATE INDEX IX_Customers_Name ON Customers(Name);
CREATE INDEX IX_Customers_Phone ON Customers(Phone);
CREATE INDEX IX_Customers_UpdatedAt ON Customers(UpdatedAt);
GO

-- Vehicles Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Vehicles' AND xtype='U')
CREATE TABLE Vehicles (
    Id NVARCHAR(50) PRIMARY KEY,
    PlateNumber NVARCHAR(20) NOT NULL,
    VehicleType NVARCHAR(50) NULL,
    TareWeight FLOAT NULL,
    CustomerId NVARCHAR(50) NULL,
    CustomerName NVARCHAR(200) NULL,
    DriverName NVARCHAR(200) NULL,
    DriverPhone NVARCHAR(20) NULL,
    Notes NVARCHAR(MAX) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Vehicles_Customers FOREIGN KEY (CustomerId) REFERENCES Customers(Id)
);
GO

-- Indexes for Vehicles
CREATE UNIQUE INDEX IX_Vehicles_PlateNumber ON Vehicles(PlateNumber) WHERE IsDeleted = 0;
CREATE INDEX IX_Vehicles_CustomerId ON Vehicles(CustomerId);
CREATE INDEX IX_Vehicles_UpdatedAt ON Vehicles(UpdatedAt);
GO

-- Products Table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Products' AND xtype='U')
CREATE TABLE Products (
    Id NVARCHAR(50) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Unit NVARCHAR(20) NULL DEFAULT 'kg',
    DefaultPrice FLOAT NULL,
    Category NVARCHAR(100) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0
);
GO

-- Indexes for Products
CREATE UNIQUE INDEX IX_Products_Code ON Products(Code) WHERE IsDeleted = 0;
CREATE INDEX IX_Products_Name ON Products(Name);
CREATE INDEX IX_Products_Category ON Products(Category);
CREATE INDEX IX_Products_UpdatedAt ON Products(UpdatedAt);
GO

-- Operators Table (Optional - for user management)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Operators' AND xtype='U')
CREATE TABLE Operators (
    Id NVARCHAR(50) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NULL,
    Phone NVARCHAR(20) NULL,
    Role NVARCHAR(50) NOT NULL DEFAULT 'operator',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsDeleted BIT NOT NULL DEFAULT 0
);
GO

CREATE UNIQUE INDEX IX_Operators_Username ON Operators(Username) WHERE IsDeleted = 0;
GO

-- Sync Log Table (for tracking sync operations)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SyncLogs' AND xtype='U')
CREATE TABLE SyncLogs (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    StationId NVARCHAR(50) NOT NULL,
    SyncType NVARCHAR(20) NOT NULL, -- 'push', 'pull', 'full'
    StartTime DATETIME2 NOT NULL,
    EndTime DATETIME2 NULL,
    Status NVARCHAR(20) NOT NULL, -- 'started', 'completed', 'failed'
    ItemsProcessed INT NOT NULL DEFAULT 0,
    ErrorMessage NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

CREATE INDEX IX_SyncLogs_StationId ON SyncLogs(StationId);
CREATE INDEX IX_SyncLogs_CreatedAt ON SyncLogs(CreatedAt);
GO

-- Insert sample data
INSERT INTO Customers (Id, Code, Name, Phone, CustomerType, CreatedAt, UpdatedAt)
VALUES 
    (NEWID(), 'KH001', N'Công ty TNHH Thủy Sản ABC', '0901234567', 'company', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), 'KH002', N'Nguyễn Văn A', '0912345678', 'individual', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), 'KH003', N'Trần Thị B', '0923456789', 'individual', GETUTCDATE(), GETUTCDATE());
GO

INSERT INTO Products (Id, Code, Name, Unit, DefaultPrice, Category, CreatedAt, UpdatedAt)
VALUES 
    (NEWID(), 'SP001', N'Cá Tra', 'kg', 25000, N'Thủy sản', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), 'SP002', N'Cá Basa', 'kg', 28000, N'Thủy sản', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), 'SP003', N'Tôm Sú', 'kg', 150000, N'Thủy sản', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), 'SP004', N'Cá Điêu Hồng', 'kg', 45000, N'Thủy sản', GETUTCDATE(), GETUTCDATE());
GO

INSERT INTO Vehicles (Id, PlateNumber, VehicleType, TareWeight, DriverName, CreatedAt, UpdatedAt)
VALUES 
    (NEWID(), '51C-12345', N'Xe tải 5 tấn', 3500, N'Nguyễn Văn Tài', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), '51C-67890', N'Xe tải 10 tấn', 5000, N'Trần Văn Lái', GETUTCDATE(), GETUTCDATE()),
    (NEWID(), '62C-11111', N'Xe tải 2.5 tấn', 2000, N'Lê Văn Xe', GETUTCDATE(), GETUTCDATE());
GO

PRINT 'Database schema created successfully!';
