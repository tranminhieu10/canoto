namespace TramCanFunctions.Models;

/// <summary>
/// Weighing ticket model
/// </summary>
public class WeighingTicket
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string TicketNumber { get; set; } = string.Empty;
    public string VehiclePlate { get; set; } = string.Empty;
    public string? VehicleId { get; set; }
    public string? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public string? ProductId { get; set; }
    public string? ProductName { get; set; }
    public double FirstWeight { get; set; }
    public double SecondWeight { get; set; }
    public double NetWeight { get; set; }
    public double? UnitPrice { get; set; }
    public double? TotalAmount { get; set; }
    public DateTime FirstWeighTime { get; set; }
    public DateTime? SecondWeighTime { get; set; }
    public string Status { get; set; } = "pending"; // pending, completed, cancelled
    public string? Notes { get; set; }
    public string? FirstWeighImageUrl { get; set; }
    public string? SecondWeighImageUrl { get; set; }
    public string? OperatorId { get; set; }
    public string? OperatorName { get; set; }
    public string StationId { get; set; } = "scale-station-01";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    public bool IsSynced { get; set; } = true;
}

/// <summary>
/// Customer model
/// </summary>
public class Customer
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? TaxCode { get; set; }
    public string? ContactPerson { get; set; }
    public string? Notes { get; set; }
    public string CustomerType { get; set; } = "individual"; // individual, company
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
}

/// <summary>
/// Vehicle model
/// </summary>
public class Vehicle
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string PlateNumber { get; set; } = string.Empty;
    public string? VehicleType { get; set; }
    public double? TareWeight { get; set; }
    public string? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public string? DriverName { get; set; }
    public string? DriverPhone { get; set; }
    public string? Notes { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
}

/// <summary>
/// Product model
/// </summary>
public class Product
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Unit { get; set; } = "kg";
    public double? DefaultPrice { get; set; }
    public string? Category { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
}

/// <summary>
/// API Response wrapper
/// </summary>
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public T? Data { get; set; }
    public int? TotalCount { get; set; }
    public int? Page { get; set; }
    public int? PageSize { get; set; }
    
    public static ApiResponse<T> Ok(T data, string? message = null)
    {
        return new ApiResponse<T> { Success = true, Data = data, Message = message };
    }
    
    public static ApiResponse<T> Ok(T data, int totalCount, int page, int pageSize)
    {
        return new ApiResponse<T> 
        { 
            Success = true, 
            Data = data, 
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }
    
    public static ApiResponse<T> Error(string message)
    {
        return new ApiResponse<T> { Success = false, Message = message };
    }
}

/// <summary>
/// SignalR notification message
/// </summary>
public class NotificationMessage
{
    public string Type { get; set; } = string.Empty;
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public object? Data { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? StationId { get; set; }
}

/// <summary>
/// Sync request model
/// </summary>
public class SyncRequest
{
    public DateTime? LastSyncTime { get; set; }
    public string? StationId { get; set; }
    public List<WeighingTicket>? WeighingTickets { get; set; }
    public List<Customer>? Customers { get; set; }
    public List<Vehicle>? Vehicles { get; set; }
    public List<Product>? Products { get; set; }
}

/// <summary>
/// Sync response model
/// </summary>
public class SyncResponse
{
    public DateTime SyncTime { get; set; } = DateTime.UtcNow;
    public List<WeighingTicket> WeighingTickets { get; set; } = new();
    public List<Customer> Customers { get; set; } = new();
    public List<Vehicle> Vehicles { get; set; } = new();
    public List<Product> Products { get; set; } = new();
    public int TotalChanges { get; set; }
}
