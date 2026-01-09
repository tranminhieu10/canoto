-- =====================================================
-- Sample Queries for Azure Functions API Testing
-- Database: sql-tramcan-hieu
-- =====================================================

-- =====================================================
-- 1. WEIGHING TICKETS QUERIES
-- =====================================================

-- Get all tickets (paginated)
SELECT TOP 50 * 
FROM WeighingTickets 
WHERE IsDeleted = 0 
ORDER BY CreatedAt DESC;

-- Get ticket by ID
SELECT * FROM WeighingTickets WHERE Id = 'your-ticket-id';

-- Get tickets by date range
SELECT * FROM WeighingTickets 
WHERE CreatedAt >= '2026-01-01' 
AND CreatedAt <= '2026-01-31'
AND IsDeleted = 0
ORDER BY CreatedAt DESC;

-- Get pending tickets (waiting for second weigh)
SELECT * FROM WeighingTickets 
WHERE Status = 'pending' AND IsDeleted = 0
ORDER BY FirstWeighTime DESC;

-- Get tickets by vehicle plate
SELECT * FROM WeighingTickets 
WHERE VehiclePlate LIKE '%29A%' AND IsDeleted = 0;

-- Get unsynced tickets (need to upload to cloud)
SELECT * FROM WeighingTickets 
WHERE IsSynced = 0 AND IsDeleted = 0;

-- Count tickets by status
SELECT 
    Status,
    COUNT(*) AS Count,
    SUM(NetWeight) AS TotalWeight,
    SUM(TotalAmount) AS TotalAmount
FROM WeighingTickets
WHERE IsDeleted = 0
GROUP BY Status;

-- =====================================================
-- 2. CUSTOMERS QUERIES
-- =====================================================

-- Get all active customers
SELECT * FROM Customers 
WHERE IsActive = 1 AND IsDeleted = 0 
ORDER BY Name;

-- Search customers by name or phone
SELECT * FROM Customers 
WHERE (Name LIKE '%Thủy sản%' OR Phone LIKE '%0909%')
AND IsDeleted = 0;

-- Get customer with ticket history
SELECT 
    c.Id, c.Name, c.Phone,
    COUNT(t.Id) AS TicketCount,
    SUM(t.NetWeight) AS TotalWeight
FROM Customers c
LEFT JOIN WeighingTickets t ON c.Id = t.CustomerId AND t.IsDeleted = 0
WHERE c.IsDeleted = 0
GROUP BY c.Id, c.Name, c.Phone
ORDER BY TotalWeight DESC;

-- =====================================================
-- 3. VEHICLES QUERIES
-- =====================================================

-- Get all active vehicles
SELECT * FROM Vehicles 
WHERE IsActive = 1 AND IsDeleted = 0 
ORDER BY LicensePlate;

-- Get vehicle by license plate
SELECT * FROM Vehicles 
WHERE LicensePlate = '29A-12345' AND IsDeleted = 0;

-- Get vehicles with tare weight
SELECT Id, LicensePlate, VehicleType, TareWeight, CustomerName
FROM Vehicles 
WHERE TareWeight IS NOT NULL AND IsDeleted = 0;

-- =====================================================
-- 4. PRODUCTS QUERIES
-- =====================================================

-- Get all active products
SELECT * FROM Products 
WHERE IsActive = 1 AND IsDeleted = 0 
ORDER BY Name;

-- Get products by category
SELECT * FROM Products 
WHERE Category = N'Thủy sản' AND IsDeleted = 0;

-- Get products with price
SELECT Id, Code, Name, Unit, UnitPrice, Category
FROM Products 
WHERE UnitPrice IS NOT NULL AND IsDeleted = 0
ORDER BY Category, Name;

-- =====================================================
-- 5. REPORTS QUERIES
-- =====================================================

-- Daily summary
SELECT 
    CAST(CreatedAt AS DATE) AS [Date],
    COUNT(*) AS Tickets,
    COUNT(CASE WHEN Status = 'completed' THEN 1 END) AS Completed,
    SUM(NetWeight) AS TotalWeight,
    SUM(TotalAmount) AS Revenue
FROM WeighingTickets
WHERE IsDeleted = 0
AND CreatedAt >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(CreatedAt AS DATE)
ORDER BY [Date] DESC;

-- Monthly summary
SELECT 
    YEAR(CreatedAt) AS [Year],
    MONTH(CreatedAt) AS [Month],
    COUNT(*) AS Tickets,
    SUM(NetWeight) AS TotalWeight,
    SUM(TotalAmount) AS Revenue
FROM WeighingTickets
WHERE IsDeleted = 0 AND Status = 'completed'
GROUP BY YEAR(CreatedAt), MONTH(CreatedAt)
ORDER BY [Year] DESC, [Month] DESC;

-- Top 10 customers by weight
SELECT TOP 10
    CustomerName,
    COUNT(*) AS Tickets,
    SUM(NetWeight) AS TotalWeight,
    SUM(TotalAmount) AS TotalAmount
FROM WeighingTickets
WHERE IsDeleted = 0 AND Status = 'completed' AND CustomerName IS NOT NULL
GROUP BY CustomerName
ORDER BY TotalWeight DESC;

-- Top 10 products by weight
SELECT TOP 10
    ProductName,
    COUNT(*) AS Tickets,
    SUM(NetWeight) AS TotalWeight,
    SUM(TotalAmount) AS TotalAmount
FROM WeighingTickets
WHERE IsDeleted = 0 AND Status = 'completed' AND ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY TotalWeight DESC;

-- Hourly distribution
SELECT 
    DATEPART(HOUR, FirstWeighTime) AS [Hour],
    COUNT(*) AS Tickets,
    SUM(NetWeight) AS TotalWeight
FROM WeighingTickets
WHERE IsDeleted = 0 
AND FirstWeighTime >= DATEADD(DAY, -30, GETDATE())
GROUP BY DATEPART(HOUR, FirstWeighTime)
ORDER BY [Hour];

-- =====================================================
-- 6. SYNC STATUS QUERIES
-- =====================================================

-- Check sync status
SELECT 
    CASE WHEN IsSynced = 1 THEN 'Synced' ELSE 'Pending' END AS SyncStatus,
    COUNT(*) AS Count
FROM WeighingTickets
WHERE IsDeleted = 0
GROUP BY IsSynced;

-- Get records to sync (from local to cloud)
SELECT * FROM WeighingTickets 
WHERE IsSynced = 0 AND IsDeleted = 0
ORDER BY CreatedAt;

-- Get recent sync logs
SELECT TOP 20 * FROM SyncLogs ORDER BY StartedAt DESC;

-- =====================================================
-- 7. INSERT SAMPLE DATA
-- =====================================================

-- Insert a new weighing ticket (first weigh - pending)
INSERT INTO WeighingTickets (
    Id, TicketNumber, VehiclePlate, VehicleId, 
    CustomerId, CustomerName, ProductId, ProductName,
    FirstWeight, SecondWeight, NetWeight, UnitPrice, TotalAmount,
    FirstWeighTime, Status, OperatorId, OperatorName, StationId,
    IsSynced, CreatedAt, UpdatedAt
)
VALUES (
    NEWID(), -- Id
    'PC' + FORMAT(GETDATE(), 'yyyyMMdd') + '001', -- TicketNumber
    '29A-12345', -- VehiclePlate
    NULL, -- VehicleId
    NULL, -- CustomerId
    N'Công ty Thủy sản ABC', -- CustomerName
    NULL, -- ProductId  
    N'Tôm sú', -- ProductName
    15500, -- FirstWeight (kg)
    0, -- SecondWeight
    0, -- NetWeight
    150000, -- UnitPrice (VND/kg)
    0, -- TotalAmount
    GETUTCDATE(), -- FirstWeighTime
    'pending', -- Status
    'operator-01', -- OperatorId
    'Admin', -- OperatorName
    'scale-station-01', -- StationId
    0, -- IsSynced
    GETUTCDATE(), -- CreatedAt
    GETUTCDATE() -- UpdatedAt
);

-- Complete a ticket (second weigh)
UPDATE WeighingTickets SET
    SecondWeight = 4500, -- Tare weight
    NetWeight = FirstWeight - 4500, -- Calculate net
    TotalAmount = (FirstWeight - 4500) * UnitPrice,
    SecondWeighTime = GETUTCDATE(),
    Status = 'completed',
    UpdatedAt = GETUTCDATE()
WHERE TicketNumber = 'PC20260109001';

-- =====================================================
-- 8. MAINTENANCE QUERIES
-- =====================================================

-- Check table sizes
SELECT 
    t.name AS TableName,
    p.rows AS RowCount,
    SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name, p.rows
ORDER BY TotalSpaceMB DESC;

-- Find duplicate ticket numbers
SELECT TicketNumber, COUNT(*) as Count
FROM WeighingTickets
WHERE IsDeleted = 0
GROUP BY TicketNumber
HAVING COUNT(*) > 1;

-- Find orphaned records (vehicles without customers)
SELECT v.* FROM Vehicles v
LEFT JOIN Customers c ON v.CustomerId = c.Id
WHERE v.CustomerId IS NOT NULL 
AND c.Id IS NULL 
AND v.IsDeleted = 0;

-- Clean up old deleted records (older than 90 days)
DELETE FROM WeighingTickets 
WHERE IsDeleted = 1 
AND UpdatedAt < DATEADD(DAY, -90, GETDATE());

-- =====================================================
-- 9. STORED PROCEDURE CALLS
-- =====================================================

-- Get today's statistics
EXEC sp_GetDailyStats;

-- Get statistics for specific date
EXEC sp_GetDailyStats @Date = '2026-01-09';

-- Get monthly statistics
EXEC sp_GetMonthlyStats @Year = 2026, @Month = 1;

-- Get top 10 customers
EXEC sp_GetTopCustomers @TopN = 10;

-- Get top products for last 30 days
EXEC sp_GetTopProducts @TopN = 10, @FromDate = '2026-01-01', @ToDate = '2026-01-31';

-- =====================================================
-- 10. AZURE FUNCTIONS API ENDPOINTS MAPPING
-- =====================================================
/*
Azure Functions API Endpoints:

Base URL: https://func-tramcan-hieu.azurewebsites.net/api

WeighingTickets:
- GET  /weighing-tickets                 - List with pagination
- GET  /weighing-tickets/{id}            - Get by ID
- POST /weighing-tickets                 - Create new
- PUT  /weighing-tickets/{id}            - Update
- DELETE /weighing-tickets/{id}          - Soft delete

Customers:
- GET  /customers                        - List with pagination
- GET  /customers/{id}                   - Get by ID
- POST /customers                        - Create new
- PUT  /customers/{id}                   - Update
- DELETE /customers/{id}                 - Soft delete

Vehicles:
- GET  /vehicles                         - List with pagination
- GET  /vehicles/{id}                    - Get by ID
- GET  /vehicles/plate/{plateNumber}     - Get by plate
- POST /vehicles                         - Create new
- PUT  /vehicles/{id}                    - Update
- DELETE /vehicles/{id}                  - Soft delete

Products:
- GET  /products                         - List with pagination
- GET  /products/{id}                    - Get by ID
- POST /products                         - Create new
- PUT  /products/{id}                    - Update
- DELETE /products/{id}                  - Soft delete

Reports:
- GET  /reports/daily?date=2026-01-09    - Daily stats
- GET  /reports/monthly?year=2026&month=1 - Monthly stats
- GET  /reports/customers                - Top customers
- GET  /reports/products                 - Top products

Sync:
- POST /sync                             - Full sync
- GET  /sync/status                      - Check sync status

Headers required:
- x-functions-key: YOUR_FUNCTION_KEY
*/
