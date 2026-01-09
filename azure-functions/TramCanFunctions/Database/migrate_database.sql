-- =====================================================
-- ALTER TABLES - Add missing columns (safe migration)
-- Run this to update existing tables without data loss
-- =====================================================

-- =====================================================
-- 1. Add missing columns to WeighingTickets
-- =====================================================

-- Check and add SyncedAt column
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('WeighingTickets') AND name = 'SyncedAt')
BEGIN
    ALTER TABLE WeighingTickets ADD SyncedAt DATETIME2 NULL;
    PRINT 'Added SyncedAt to WeighingTickets';
END
GO

-- =====================================================
-- 2. Add missing columns to Vehicles
-- =====================================================

-- Ensure LicensePlate exists (Azure Functions uses this)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'LicensePlate')
BEGIN
    ALTER TABLE Vehicles ADD LicensePlate NVARCHAR(20) NULL;
    -- Copy from PlateNumber if exists
    UPDATE Vehicles SET LicensePlate = PlateNumber WHERE LicensePlate IS NULL AND PlateNumber IS NOT NULL;
    PRINT 'Added LicensePlate to Vehicles';
END
GO

-- Add DriverName if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'DriverName')
BEGIN
    ALTER TABLE Vehicles ADD DriverName NVARCHAR(100) NULL;
    PRINT 'Added DriverName to Vehicles';
END
GO

-- Add DriverPhone if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'DriverPhone')
BEGIN
    ALTER TABLE Vehicles ADD DriverPhone NVARCHAR(20) NULL;
    PRINT 'Added DriverPhone to Vehicles';
END
GO

-- Add Notes if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'Notes')
BEGIN
    ALTER TABLE Vehicles ADD Notes NVARCHAR(1000) NULL;
    PRINT 'Added Notes to Vehicles';
END
GO

-- Add UpdatedAt if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE Vehicles ADD UpdatedAt DATETIME2 DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt to Vehicles';
END
GO

-- Add IsDeleted if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vehicles') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE Vehicles ADD IsDeleted BIT DEFAULT 0;
    PRINT 'Added IsDeleted to Vehicles';
END
GO

-- =====================================================
-- 3. Add missing columns to Customers
-- =====================================================

-- Add Code if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Code')
BEGIN
    ALTER TABLE Customers ADD Code NVARCHAR(50) NULL;
    PRINT 'Added Code to Customers';
END
GO

-- Add Email if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Email')
BEGIN
    ALTER TABLE Customers ADD Email NVARCHAR(100) NULL;
    PRINT 'Added Email to Customers';
END
GO

-- Add Address if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Address')
BEGIN
    ALTER TABLE Customers ADD Address NVARCHAR(500) NULL;
    PRINT 'Added Address to Customers';
END
GO

-- Add TaxCode if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'TaxCode')
BEGIN
    ALTER TABLE Customers ADD TaxCode NVARCHAR(20) NULL;
    PRINT 'Added TaxCode to Customers';
END
GO

-- Add ContactPerson if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'ContactPerson')
BEGIN
    ALTER TABLE Customers ADD ContactPerson NVARCHAR(100) NULL;
    PRINT 'Added ContactPerson to Customers';
END
GO

-- Add Notes if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Notes')
BEGIN
    ALTER TABLE Customers ADD Notes NVARCHAR(1000) NULL;
    PRINT 'Added Notes to Customers';
END
GO

-- Add CustomerType if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'CustomerType')
BEGIN
    ALTER TABLE Customers ADD CustomerType NVARCHAR(20) DEFAULT 'individual';
    PRINT 'Added CustomerType to Customers';
END
GO

-- Add UpdatedAt if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE Customers ADD UpdatedAt DATETIME2 DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt to Customers';
END
GO

-- Add IsDeleted if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE Customers ADD IsDeleted BIT DEFAULT 0;
    PRINT 'Added IsDeleted to Customers';
END
GO

-- =====================================================
-- 4. Add missing columns to Products
-- =====================================================

-- Add Description if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'Description')
BEGIN
    ALTER TABLE Products ADD Description NVARCHAR(1000) NULL;
    PRINT 'Added Description to Products';
END
GO

-- Add DefaultPrice if missing (alias for UnitPrice)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'DefaultPrice')
BEGIN
    ALTER TABLE Products ADD DefaultPrice FLOAT NULL;
    UPDATE Products SET DefaultPrice = UnitPrice WHERE DefaultPrice IS NULL AND UnitPrice IS NOT NULL;
    PRINT 'Added DefaultPrice to Products';
END
GO

-- Add UpdatedAt if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'UpdatedAt')
BEGIN
    ALTER TABLE Products ADD UpdatedAt DATETIME2 DEFAULT GETUTCDATE();
    PRINT 'Added UpdatedAt to Products';
END
GO

-- Add IsDeleted if missing
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE Products ADD IsDeleted BIT DEFAULT 0;
    PRINT 'Added IsDeleted to Products';
END
GO

-- =====================================================
-- 5. Create missing tables
-- =====================================================

-- Create SyncLogs if not exists
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SyncLogs')
BEGIN
    CREATE TABLE dbo.SyncLogs (
        Id NVARCHAR(50) NOT NULL PRIMARY KEY DEFAULT NEWID(),
        StationId NVARCHAR(50) NOT NULL,
        SyncType NVARCHAR(50) NOT NULL,
        EntityType NVARCHAR(50) NULL,
        RecordsCount INT DEFAULT 0,
        Status NVARCHAR(20) NOT NULL,
        ErrorMessage NVARCHAR(2000) NULL,
        StartedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CompletedAt DATETIME2 NULL,
        DurationMs INT NULL
    );
    CREATE INDEX IX_SyncLogs_StationId ON dbo.SyncLogs(StationId);
    CREATE INDEX IX_SyncLogs_StartedAt ON dbo.SyncLogs(StartedAt DESC);
    PRINT 'Created SyncLogs table';
END
GO

-- Create WeighingStations if not exists
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WeighingStations')
BEGIN
    CREATE TABLE dbo.WeighingStations (
        Id NVARCHAR(50) NOT NULL PRIMARY KEY,
        Code NVARCHAR(50) NULL,
        Name NVARCHAR(200) NOT NULL,
        Location NVARCHAR(500) NULL,
        ScaleType NVARCHAR(50) NULL,
        MaxCapacity FLOAT NULL,
        IotDeviceId NVARCHAR(100) NULL,
        LastOnlineAt DATETIME2 NULL,
        IsActive BIT DEFAULT 1,
        IsDeleted BIT DEFAULT 0,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    
    -- Insert default station
    INSERT INTO dbo.WeighingStations (Id, Code, Name, ScaleType)
    VALUES ('scale-station-01', 'TC01', 'Trạm cân chính', 'A&D GF-40K');
    
    PRINT 'Created WeighingStations table';
END
GO

-- Create Operators if not exists
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Operators')
BEGIN
    CREATE TABLE dbo.Operators (
        Id NVARCHAR(50) NOT NULL PRIMARY KEY,
        Code NVARCHAR(50) NULL,
        Name NVARCHAR(200) NOT NULL,
        Phone NVARCHAR(20) NULL,
        Email NVARCHAR(100) NULL,
        Role NVARCHAR(50) DEFAULT 'operator',
        IsActive BIT DEFAULT 1,
        IsDeleted BIT DEFAULT 0,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    
    -- Insert default operator
    INSERT INTO dbo.Operators (Id, Code, Name, Role)
    VALUES ('operator-01', 'NV001', 'Admin', 'admin');
    
    PRINT 'Created Operators table';
END
GO

-- =====================================================
-- 6. Verify table structure
-- =====================================================
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('WeighingTickets', 'Customers', 'Vehicles', 'Products', 'SyncLogs', 'WeighingStations', 'Operators')
ORDER BY t.name, c.column_id;

PRINT '';
PRINT '================================================';
PRINT 'Migration completed successfully!';
PRINT '================================================';
GO
