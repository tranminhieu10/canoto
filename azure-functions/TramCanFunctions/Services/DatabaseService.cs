using Microsoft.Data.SqlClient;
using System.Text.Json;
using TramCanFunctions.Models;

namespace TramCanFunctions.Services;

/// <summary>
/// Database service for Azure SQL operations
/// </summary>
public class DatabaseService
{
    private readonly string _connectionString;

    public DatabaseService()
    {
        _connectionString = Environment.GetEnvironmentVariable("SqlConnectionString") 
            ?? throw new InvalidOperationException("SqlConnectionString not configured");
    }

    #region WeighingTicket CRUD

    public async Task<List<WeighingTicket>> GetWeighingTicketsAsync(
        int page = 1, 
        int pageSize = 50, 
        DateTime? fromDate = null, 
        DateTime? toDate = null,
        string? status = null,
        string? vehiclePlate = null)
    {
        var tickets = new List<WeighingTicket>();
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT * FROM WeighingTickets 
            WHERE IsDeleted = 0
            AND (@FromDate IS NULL OR CreatedAt >= @FromDate)
            AND (@ToDate IS NULL OR CreatedAt <= @ToDate)
            AND (@Status IS NULL OR Status = @Status)
            AND (@VehiclePlate IS NULL OR VehiclePlate LIKE '%' + @VehiclePlate + '%')
            ORDER BY CreatedAt DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@FromDate", (object?)fromDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@ToDate", (object?)toDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Status", (object?)status ?? DBNull.Value);
        command.Parameters.AddWithValue("@VehiclePlate", (object?)vehiclePlate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Offset", (page - 1) * pageSize);
        command.Parameters.AddWithValue("@PageSize", pageSize);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            tickets.Add(MapWeighingTicket(reader));
        }
        
        return tickets;
    }

    public async Task<WeighingTicket?> GetWeighingTicketByIdAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "SELECT * FROM WeighingTickets WHERE Id = @Id AND IsDeleted = 0", 
            connection);
        command.Parameters.AddWithValue("@Id", id);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapWeighingTicket(reader);
        }
        return null;
    }

    public async Task<WeighingTicket> CreateWeighingTicketAsync(WeighingTicket ticket)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            INSERT INTO WeighingTickets 
            (Id, TicketNumber, VehiclePlate, VehicleId, CustomerId, CustomerName, ProductId, ProductName,
             FirstWeight, SecondWeight, NetWeight, UnitPrice, TotalAmount, FirstWeighTime, SecondWeighTime,
             Status, Notes, FirstWeighImageUrl, SecondWeighImageUrl, OperatorId, OperatorName, StationId,
             CreatedAt, UpdatedAt, IsDeleted, IsSynced)
            VALUES 
            (@Id, @TicketNumber, @VehiclePlate, @VehicleId, @CustomerId, @CustomerName, @ProductId, @ProductName,
             @FirstWeight, @SecondWeight, @NetWeight, @UnitPrice, @TotalAmount, @FirstWeighTime, @SecondWeighTime,
             @Status, @Notes, @FirstWeighImageUrl, @SecondWeighImageUrl, @OperatorId, @OperatorName, @StationId,
             @CreatedAt, @UpdatedAt, @IsDeleted, @IsSynced)";

        using var command = new SqlCommand(sql, connection);
        AddWeighingTicketParameters(command, ticket);
        await command.ExecuteNonQueryAsync();
        
        return ticket;
    }

    public async Task<WeighingTicket> UpdateWeighingTicketAsync(WeighingTicket ticket)
    {
        ticket.UpdatedAt = DateTime.UtcNow;
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            UPDATE WeighingTickets SET
                TicketNumber = @TicketNumber, VehiclePlate = @VehiclePlate, VehicleId = @VehicleId,
                CustomerId = @CustomerId, CustomerName = @CustomerName, ProductId = @ProductId, 
                ProductName = @ProductName, FirstWeight = @FirstWeight, SecondWeight = @SecondWeight,
                NetWeight = @NetWeight, UnitPrice = @UnitPrice, TotalAmount = @TotalAmount,
                FirstWeighTime = @FirstWeighTime, SecondWeighTime = @SecondWeighTime, Status = @Status,
                Notes = @Notes, FirstWeighImageUrl = @FirstWeighImageUrl, SecondWeighImageUrl = @SecondWeighImageUrl,
                OperatorId = @OperatorId, OperatorName = @OperatorName, UpdatedAt = @UpdatedAt, IsSynced = @IsSynced
            WHERE Id = @Id";

        using var command = new SqlCommand(sql, connection);
        AddWeighingTicketParameters(command, ticket);
        await command.ExecuteNonQueryAsync();
        
        return ticket;
    }

    public async Task DeleteWeighingTicketAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "UPDATE WeighingTickets SET IsDeleted = 1, UpdatedAt = @UpdatedAt WHERE Id = @Id", 
            connection);
        command.Parameters.AddWithValue("@Id", id);
        command.Parameters.AddWithValue("@UpdatedAt", DateTime.UtcNow);
        await command.ExecuteNonQueryAsync();
    }

    public async Task<int> GetWeighingTicketsCountAsync(DateTime? fromDate = null, DateTime? toDate = null, string? status = null)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT COUNT(*) FROM WeighingTickets 
            WHERE IsDeleted = 0
            AND (@FromDate IS NULL OR CreatedAt >= @FromDate)
            AND (@ToDate IS NULL OR CreatedAt <= @ToDate)
            AND (@Status IS NULL OR Status = @Status)";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@FromDate", (object?)fromDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@ToDate", (object?)toDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Status", (object?)status ?? DBNull.Value);
        
        return (int)await command.ExecuteScalarAsync();
    }

    #endregion

    #region Customer CRUD

    public async Task<List<Customer>> GetCustomersAsync(int page = 1, int pageSize = 50, string? search = null)
    {
        var customers = new List<Customer>();
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT * FROM Customers 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%' OR Phone LIKE '%' + @Search + '%')
            ORDER BY Name
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        command.Parameters.AddWithValue("@Offset", (page - 1) * pageSize);
        command.Parameters.AddWithValue("@PageSize", pageSize);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            customers.Add(MapCustomer(reader));
        }
        
        return customers;
    }

    public async Task<Customer?> GetCustomerByIdAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "SELECT * FROM Customers WHERE Id = @Id AND IsDeleted = 0", 
            connection);
        command.Parameters.AddWithValue("@Id", id);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapCustomer(reader);
        }
        return null;
    }

    public async Task<Customer> CreateCustomerAsync(Customer customer)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            INSERT INTO Customers 
            (Id, Code, Name, Phone, Email, Address, TaxCode, ContactPerson, Notes, CustomerType, IsActive, CreatedAt, UpdatedAt, IsDeleted)
            VALUES 
            (@Id, @Code, @Name, @Phone, @Email, @Address, @TaxCode, @ContactPerson, @Notes, @CustomerType, @IsActive, @CreatedAt, @UpdatedAt, @IsDeleted)";

        using var command = new SqlCommand(sql, connection);
        AddCustomerParameters(command, customer);
        await command.ExecuteNonQueryAsync();
        
        return customer;
    }

    public async Task<Customer> UpdateCustomerAsync(Customer customer)
    {
        customer.UpdatedAt = DateTime.UtcNow;
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            UPDATE Customers SET
                Code = @Code, Name = @Name, Phone = @Phone, Email = @Email, Address = @Address,
                TaxCode = @TaxCode, ContactPerson = @ContactPerson, Notes = @Notes, 
                CustomerType = @CustomerType, IsActive = @IsActive, UpdatedAt = @UpdatedAt
            WHERE Id = @Id";

        using var command = new SqlCommand(sql, connection);
        AddCustomerParameters(command, customer);
        await command.ExecuteNonQueryAsync();
        
        return customer;
    }

    public async Task DeleteCustomerAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "UPDATE Customers SET IsDeleted = 1, UpdatedAt = @UpdatedAt WHERE Id = @Id", 
            connection);
        command.Parameters.AddWithValue("@Id", id);
        command.Parameters.AddWithValue("@UpdatedAt", DateTime.UtcNow);
        await command.ExecuteNonQueryAsync();
    }

    public async Task<int> GetCustomersCountAsync(string? search = null)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT COUNT(*) FROM Customers 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%')";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        
        return (int)await command.ExecuteScalarAsync();
    }

    #endregion

    #region Vehicle CRUD

    public async Task<List<Vehicle>> GetVehiclesAsync(int page = 1, int pageSize = 50, string? search = null)
    {
        var vehicles = new List<Vehicle>();
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT * FROM Vehicles 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR PlateNumber LIKE '%' + @Search + '%' OR DriverName LIKE '%' + @Search + '%')
            ORDER BY PlateNumber
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        command.Parameters.AddWithValue("@Offset", (page - 1) * pageSize);
        command.Parameters.AddWithValue("@PageSize", pageSize);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            vehicles.Add(MapVehicle(reader));
        }
        
        return vehicles;
    }

    public async Task<Vehicle?> GetVehicleByIdAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "SELECT * FROM Vehicles WHERE Id = @Id AND IsDeleted = 0", 
            connection);
        command.Parameters.AddWithValue("@Id", id);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapVehicle(reader);
        }
        return null;
    }

    public async Task<Vehicle?> GetVehicleByPlateAsync(string plateNumber)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "SELECT * FROM Vehicles WHERE PlateNumber = @PlateNumber AND IsDeleted = 0", 
            connection);
        command.Parameters.AddWithValue("@PlateNumber", plateNumber);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapVehicle(reader);
        }
        return null;
    }

    public async Task<Vehicle> CreateVehicleAsync(Vehicle vehicle)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            INSERT INTO Vehicles 
            (Id, PlateNumber, VehicleType, TareWeight, CustomerId, CustomerName, DriverName, DriverPhone, Notes, IsActive, CreatedAt, UpdatedAt, IsDeleted)
            VALUES 
            (@Id, @PlateNumber, @VehicleType, @TareWeight, @CustomerId, @CustomerName, @DriverName, @DriverPhone, @Notes, @IsActive, @CreatedAt, @UpdatedAt, @IsDeleted)";

        using var command = new SqlCommand(sql, connection);
        AddVehicleParameters(command, vehicle);
        await command.ExecuteNonQueryAsync();
        
        return vehicle;
    }

    public async Task<Vehicle> UpdateVehicleAsync(Vehicle vehicle)
    {
        vehicle.UpdatedAt = DateTime.UtcNow;
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            UPDATE Vehicles SET
                PlateNumber = @PlateNumber, VehicleType = @VehicleType, TareWeight = @TareWeight,
                CustomerId = @CustomerId, CustomerName = @CustomerName, DriverName = @DriverName,
                DriverPhone = @DriverPhone, Notes = @Notes, IsActive = @IsActive, UpdatedAt = @UpdatedAt
            WHERE Id = @Id";

        using var command = new SqlCommand(sql, connection);
        AddVehicleParameters(command, vehicle);
        await command.ExecuteNonQueryAsync();
        
        return vehicle;
    }

    public async Task DeleteVehicleAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "UPDATE Vehicles SET IsDeleted = 1, UpdatedAt = @UpdatedAt WHERE Id = @Id", 
            connection);
        command.Parameters.AddWithValue("@Id", id);
        command.Parameters.AddWithValue("@UpdatedAt", DateTime.UtcNow);
        await command.ExecuteNonQueryAsync();
    }

    public async Task<int> GetVehiclesCountAsync(string? search = null)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT COUNT(*) FROM Vehicles 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR PlateNumber LIKE '%' + @Search + '%')";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        
        return (int)await command.ExecuteScalarAsync();
    }

    #endregion

    #region Product CRUD

    public async Task<List<Product>> GetProductsAsync(int page = 1, int pageSize = 50, string? search = null)
    {
        var products = new List<Product>();
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT * FROM Products 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%')
            ORDER BY Name
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        command.Parameters.AddWithValue("@Offset", (page - 1) * pageSize);
        command.Parameters.AddWithValue("@PageSize", pageSize);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            products.Add(MapProduct(reader));
        }
        
        return products;
    }

    public async Task<Product?> GetProductByIdAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "SELECT * FROM Products WHERE Id = @Id AND IsDeleted = 0", 
            connection);
        command.Parameters.AddWithValue("@Id", id);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapProduct(reader);
        }
        return null;
    }

    public async Task<Product> CreateProductAsync(Product product)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            INSERT INTO Products 
            (Id, Code, Name, Description, Unit, DefaultPrice, Category, IsActive, CreatedAt, UpdatedAt, IsDeleted)
            VALUES 
            (@Id, @Code, @Name, @Description, @Unit, @DefaultPrice, @Category, @IsActive, @CreatedAt, @UpdatedAt, @IsDeleted)";

        using var command = new SqlCommand(sql, connection);
        AddProductParameters(command, product);
        await command.ExecuteNonQueryAsync();
        
        return product;
    }

    public async Task<Product> UpdateProductAsync(Product product)
    {
        product.UpdatedAt = DateTime.UtcNow;
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            UPDATE Products SET
                Code = @Code, Name = @Name, Description = @Description, Unit = @Unit,
                DefaultPrice = @DefaultPrice, Category = @Category, IsActive = @IsActive, UpdatedAt = @UpdatedAt
            WHERE Id = @Id";

        using var command = new SqlCommand(sql, connection);
        AddProductParameters(command, product);
        await command.ExecuteNonQueryAsync();
        
        return product;
    }

    public async Task DeleteProductAsync(string id)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand(
            "UPDATE Products SET IsDeleted = 1, UpdatedAt = @UpdatedAt WHERE Id = @Id", 
            connection);
        command.Parameters.AddWithValue("@Id", id);
        command.Parameters.AddWithValue("@UpdatedAt", DateTime.UtcNow);
        await command.ExecuteNonQueryAsync();
    }

    public async Task<int> GetProductsCountAsync(string? search = null)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        var sql = @"
            SELECT COUNT(*) FROM Products 
            WHERE IsDeleted = 0
            AND (@Search IS NULL OR Name LIKE '%' + @Search + '%' OR Code LIKE '%' + @Search + '%')";

        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Search", (object?)search ?? DBNull.Value);
        
        return (int)await command.ExecuteScalarAsync();
    }

    #endregion

    #region Sync Operations

    public async Task<SyncResponse> GetChangesSinceAsync(DateTime? lastSyncTime, string? stationId)
    {
        var response = new SyncResponse { SyncTime = DateTime.UtcNow };
        
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        
        // Get modified weighing tickets
        var ticketsSql = @"SELECT * FROM WeighingTickets WHERE UpdatedAt > @LastSyncTime ORDER BY UpdatedAt";
        using (var cmd = new SqlCommand(ticketsSql, connection))
        {
            cmd.Parameters.AddWithValue("@LastSyncTime", lastSyncTime ?? DateTime.MinValue);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                response.WeighingTickets.Add(MapWeighingTicket(reader));
            }
        }
        
        // Get modified customers
        var customersSql = @"SELECT * FROM Customers WHERE UpdatedAt > @LastSyncTime ORDER BY UpdatedAt";
        using (var cmd = new SqlCommand(customersSql, connection))
        {
            cmd.Parameters.AddWithValue("@LastSyncTime", lastSyncTime ?? DateTime.MinValue);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                response.Customers.Add(MapCustomer(reader));
            }
        }
        
        // Get modified vehicles
        var vehiclesSql = @"SELECT * FROM Vehicles WHERE UpdatedAt > @LastSyncTime ORDER BY UpdatedAt";
        using (var cmd = new SqlCommand(vehiclesSql, connection))
        {
            cmd.Parameters.AddWithValue("@LastSyncTime", lastSyncTime ?? DateTime.MinValue);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                response.Vehicles.Add(MapVehicle(reader));
            }
        }
        
        // Get modified products
        var productsSql = @"SELECT * FROM Products WHERE UpdatedAt > @LastSyncTime ORDER BY UpdatedAt";
        using (var cmd = new SqlCommand(productsSql, connection))
        {
            cmd.Parameters.AddWithValue("@LastSyncTime", lastSyncTime ?? DateTime.MinValue);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                response.Products.Add(MapProduct(reader));
            }
        }
        
        response.TotalChanges = response.WeighingTickets.Count + response.Customers.Count + 
                                 response.Vehicles.Count + response.Products.Count;
        
        return response;
    }

    #endregion

    #region Helper Methods

    private static WeighingTicket MapWeighingTicket(SqlDataReader reader)
    {
        return new WeighingTicket
        {
            Id = reader.GetString(reader.GetOrdinal("Id")),
            TicketNumber = reader.GetString(reader.GetOrdinal("TicketNumber")),
            VehiclePlate = reader.GetString(reader.GetOrdinal("VehiclePlate")),
            VehicleId = reader.IsDBNull(reader.GetOrdinal("VehicleId")) ? null : reader.GetString(reader.GetOrdinal("VehicleId")),
            CustomerId = reader.IsDBNull(reader.GetOrdinal("CustomerId")) ? null : reader.GetString(reader.GetOrdinal("CustomerId")),
            CustomerName = reader.IsDBNull(reader.GetOrdinal("CustomerName")) ? null : reader.GetString(reader.GetOrdinal("CustomerName")),
            ProductId = reader.IsDBNull(reader.GetOrdinal("ProductId")) ? null : reader.GetString(reader.GetOrdinal("ProductId")),
            ProductName = reader.IsDBNull(reader.GetOrdinal("ProductName")) ? null : reader.GetString(reader.GetOrdinal("ProductName")),
            FirstWeight = reader.GetDouble(reader.GetOrdinal("FirstWeight")),
            SecondWeight = reader.GetDouble(reader.GetOrdinal("SecondWeight")),
            NetWeight = reader.GetDouble(reader.GetOrdinal("NetWeight")),
            UnitPrice = reader.IsDBNull(reader.GetOrdinal("UnitPrice")) ? null : reader.GetDouble(reader.GetOrdinal("UnitPrice")),
            TotalAmount = reader.IsDBNull(reader.GetOrdinal("TotalAmount")) ? null : reader.GetDouble(reader.GetOrdinal("TotalAmount")),
            FirstWeighTime = reader.GetDateTime(reader.GetOrdinal("FirstWeighTime")),
            SecondWeighTime = reader.IsDBNull(reader.GetOrdinal("SecondWeighTime")) ? null : reader.GetDateTime(reader.GetOrdinal("SecondWeighTime")),
            Status = reader.GetString(reader.GetOrdinal("Status")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            FirstWeighImageUrl = reader.IsDBNull(reader.GetOrdinal("FirstWeighImageUrl")) ? null : reader.GetString(reader.GetOrdinal("FirstWeighImageUrl")),
            SecondWeighImageUrl = reader.IsDBNull(reader.GetOrdinal("SecondWeighImageUrl")) ? null : reader.GetString(reader.GetOrdinal("SecondWeighImageUrl")),
            OperatorId = reader.IsDBNull(reader.GetOrdinal("OperatorId")) ? null : reader.GetString(reader.GetOrdinal("OperatorId")),
            OperatorName = reader.IsDBNull(reader.GetOrdinal("OperatorName")) ? null : reader.GetString(reader.GetOrdinal("OperatorName")),
            StationId = reader.GetString(reader.GetOrdinal("StationId")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
            UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UpdatedAt")),
            IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted")),
            IsSynced = reader.GetBoolean(reader.GetOrdinal("IsSynced"))
        };
    }

    private static Customer MapCustomer(SqlDataReader reader)
    {
        return new Customer
        {
            Id = reader.GetString(reader.GetOrdinal("Id")),
            Code = reader.GetString(reader.GetOrdinal("Code")),
            Name = reader.GetString(reader.GetOrdinal("Name")),
            Phone = reader.IsDBNull(reader.GetOrdinal("Phone")) ? null : reader.GetString(reader.GetOrdinal("Phone")),
            Email = reader.IsDBNull(reader.GetOrdinal("Email")) ? null : reader.GetString(reader.GetOrdinal("Email")),
            Address = reader.IsDBNull(reader.GetOrdinal("Address")) ? null : reader.GetString(reader.GetOrdinal("Address")),
            TaxCode = reader.IsDBNull(reader.GetOrdinal("TaxCode")) ? null : reader.GetString(reader.GetOrdinal("TaxCode")),
            ContactPerson = reader.IsDBNull(reader.GetOrdinal("ContactPerson")) ? null : reader.GetString(reader.GetOrdinal("ContactPerson")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            CustomerType = reader.GetString(reader.GetOrdinal("CustomerType")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
            UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UpdatedAt")),
            IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
        };
    }

    private static Vehicle MapVehicle(SqlDataReader reader)
    {
        return new Vehicle
        {
            Id = reader.GetString(reader.GetOrdinal("Id")),
            PlateNumber = reader.GetString(reader.GetOrdinal("PlateNumber")),
            VehicleType = reader.IsDBNull(reader.GetOrdinal("VehicleType")) ? null : reader.GetString(reader.GetOrdinal("VehicleType")),
            TareWeight = reader.IsDBNull(reader.GetOrdinal("TareWeight")) ? null : reader.GetDouble(reader.GetOrdinal("TareWeight")),
            CustomerId = reader.IsDBNull(reader.GetOrdinal("CustomerId")) ? null : reader.GetString(reader.GetOrdinal("CustomerId")),
            CustomerName = reader.IsDBNull(reader.GetOrdinal("CustomerName")) ? null : reader.GetString(reader.GetOrdinal("CustomerName")),
            DriverName = reader.IsDBNull(reader.GetOrdinal("DriverName")) ? null : reader.GetString(reader.GetOrdinal("DriverName")),
            DriverPhone = reader.IsDBNull(reader.GetOrdinal("DriverPhone")) ? null : reader.GetString(reader.GetOrdinal("DriverPhone")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
            UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UpdatedAt")),
            IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
        };
    }

    private static Product MapProduct(SqlDataReader reader)
    {
        return new Product
        {
            Id = reader.GetString(reader.GetOrdinal("Id")),
            Code = reader.GetString(reader.GetOrdinal("Code")),
            Name = reader.GetString(reader.GetOrdinal("Name")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            Unit = reader.IsDBNull(reader.GetOrdinal("Unit")) ? null : reader.GetString(reader.GetOrdinal("Unit")),
            DefaultPrice = reader.IsDBNull(reader.GetOrdinal("DefaultPrice")) ? null : reader.GetDouble(reader.GetOrdinal("DefaultPrice")),
            Category = reader.IsDBNull(reader.GetOrdinal("Category")) ? null : reader.GetString(reader.GetOrdinal("Category")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
            UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UpdatedAt")),
            IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
        };
    }

    private static void AddWeighingTicketParameters(SqlCommand command, WeighingTicket ticket)
    {
        command.Parameters.AddWithValue("@Id", ticket.Id);
        command.Parameters.AddWithValue("@TicketNumber", ticket.TicketNumber);
        command.Parameters.AddWithValue("@VehiclePlate", ticket.VehiclePlate);
        command.Parameters.AddWithValue("@VehicleId", (object?)ticket.VehicleId ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerId", (object?)ticket.CustomerId ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerName", (object?)ticket.CustomerName ?? DBNull.Value);
        command.Parameters.AddWithValue("@ProductId", (object?)ticket.ProductId ?? DBNull.Value);
        command.Parameters.AddWithValue("@ProductName", (object?)ticket.ProductName ?? DBNull.Value);
        command.Parameters.AddWithValue("@FirstWeight", ticket.FirstWeight);
        command.Parameters.AddWithValue("@SecondWeight", ticket.SecondWeight);
        command.Parameters.AddWithValue("@NetWeight", ticket.NetWeight);
        command.Parameters.AddWithValue("@UnitPrice", (object?)ticket.UnitPrice ?? DBNull.Value);
        command.Parameters.AddWithValue("@TotalAmount", (object?)ticket.TotalAmount ?? DBNull.Value);
        command.Parameters.AddWithValue("@FirstWeighTime", ticket.FirstWeighTime);
        command.Parameters.AddWithValue("@SecondWeighTime", (object?)ticket.SecondWeighTime ?? DBNull.Value);
        command.Parameters.AddWithValue("@Status", ticket.Status);
        command.Parameters.AddWithValue("@Notes", (object?)ticket.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@FirstWeighImageUrl", (object?)ticket.FirstWeighImageUrl ?? DBNull.Value);
        command.Parameters.AddWithValue("@SecondWeighImageUrl", (object?)ticket.SecondWeighImageUrl ?? DBNull.Value);
        command.Parameters.AddWithValue("@OperatorId", (object?)ticket.OperatorId ?? DBNull.Value);
        command.Parameters.AddWithValue("@OperatorName", (object?)ticket.OperatorName ?? DBNull.Value);
        command.Parameters.AddWithValue("@StationId", ticket.StationId);
        command.Parameters.AddWithValue("@CreatedAt", ticket.CreatedAt);
        command.Parameters.AddWithValue("@UpdatedAt", ticket.UpdatedAt);
        command.Parameters.AddWithValue("@IsDeleted", ticket.IsDeleted);
        command.Parameters.AddWithValue("@IsSynced", ticket.IsSynced);
    }

    private static void AddCustomerParameters(SqlCommand command, Customer customer)
    {
        command.Parameters.AddWithValue("@Id", customer.Id);
        command.Parameters.AddWithValue("@Code", customer.Code);
        command.Parameters.AddWithValue("@Name", customer.Name);
        command.Parameters.AddWithValue("@Phone", (object?)customer.Phone ?? DBNull.Value);
        command.Parameters.AddWithValue("@Email", (object?)customer.Email ?? DBNull.Value);
        command.Parameters.AddWithValue("@Address", (object?)customer.Address ?? DBNull.Value);
        command.Parameters.AddWithValue("@TaxCode", (object?)customer.TaxCode ?? DBNull.Value);
        command.Parameters.AddWithValue("@ContactPerson", (object?)customer.ContactPerson ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)customer.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerType", customer.CustomerType);
        command.Parameters.AddWithValue("@IsActive", customer.IsActive);
        command.Parameters.AddWithValue("@CreatedAt", customer.CreatedAt);
        command.Parameters.AddWithValue("@UpdatedAt", customer.UpdatedAt);
        command.Parameters.AddWithValue("@IsDeleted", customer.IsDeleted);
    }

    private static void AddVehicleParameters(SqlCommand command, Vehicle vehicle)
    {
        command.Parameters.AddWithValue("@Id", vehicle.Id);
        command.Parameters.AddWithValue("@PlateNumber", vehicle.PlateNumber);
        command.Parameters.AddWithValue("@VehicleType", (object?)vehicle.VehicleType ?? DBNull.Value);
        command.Parameters.AddWithValue("@TareWeight", (object?)vehicle.TareWeight ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerId", (object?)vehicle.CustomerId ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerName", (object?)vehicle.CustomerName ?? DBNull.Value);
        command.Parameters.AddWithValue("@DriverName", (object?)vehicle.DriverName ?? DBNull.Value);
        command.Parameters.AddWithValue("@DriverPhone", (object?)vehicle.DriverPhone ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)vehicle.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", vehicle.IsActive);
        command.Parameters.AddWithValue("@CreatedAt", vehicle.CreatedAt);
        command.Parameters.AddWithValue("@UpdatedAt", vehicle.UpdatedAt);
        command.Parameters.AddWithValue("@IsDeleted", vehicle.IsDeleted);
    }

    private static void AddProductParameters(SqlCommand command, Product product)
    {
        command.Parameters.AddWithValue("@Id", product.Id);
        command.Parameters.AddWithValue("@Code", product.Code);
        command.Parameters.AddWithValue("@Name", product.Name);
        command.Parameters.AddWithValue("@Description", (object?)product.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@Unit", (object?)product.Unit ?? DBNull.Value);
        command.Parameters.AddWithValue("@DefaultPrice", (object?)product.DefaultPrice ?? DBNull.Value);
        command.Parameters.AddWithValue("@Category", (object?)product.Category ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", product.IsActive);
        command.Parameters.AddWithValue("@CreatedAt", product.CreatedAt);
        command.Parameters.AddWithValue("@UpdatedAt", product.UpdatedAt);
        command.Parameters.AddWithValue("@IsDeleted", product.IsDeleted);
    }

    #endregion
}
