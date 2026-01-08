using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Customer API functions
/// </summary>
public class CustomerFunctions
{
    private readonly ILogger<CustomerFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public CustomerFunctions(ILogger<CustomerFunctions> logger)
    {
        _logger = logger;
        _db = new DatabaseService();
        _jsonOptions = new JsonSerializerOptions 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true
        };
    }

    /// <summary>
    /// Get all customers with pagination
    /// </summary>
    [Function("GetCustomers")]
    public async Task<HttpResponseData> GetCustomers(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "customers")] HttpRequestData req)
    {
        _logger.LogInformation("Getting customers");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var page = int.TryParse(query["page"], out var p) ? p : 1;
            var pageSize = int.TryParse(query["pageSize"], out var ps) ? ps : 50;
            var search = query["search"];
            
            var customers = await _db.GetCustomersAsync(page, pageSize, search);
            var totalCount = await _db.GetCustomersCountAsync(search);
            
            var result = ApiResponse<List<Customer>>.Ok(customers, totalCount, page, pageSize);
            return await CreateJsonResponse(req, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customers");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get customer by ID
    /// </summary>
    [Function("GetCustomer")]
    public async Task<HttpResponseData> GetCustomer(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "customers/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Getting customer: {Id}", id);
        
        try
        {
            var customer = await _db.GetCustomerByIdAsync(id);
            
            if (customer == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Customer not found"), HttpStatusCode.NotFound);
            }
            
            return await CreateJsonResponse(req, ApiResponse<Customer>.Ok(customer));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customer");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Create new customer
    /// </summary>
    [Function("CreateCustomer")]
    public async Task<HttpResponseData> CreateCustomer(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "customers")] HttpRequestData req)
    {
        _logger.LogInformation("Creating customer");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var customer = JsonSerializer.Deserialize<Customer>(body, _jsonOptions);
            
            if (customer == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid customer data"), HttpStatusCode.BadRequest);
            }
            
            customer.Id = string.IsNullOrEmpty(customer.Id) ? Guid.NewGuid().ToString() : customer.Id;
            customer.CreatedAt = DateTime.UtcNow;
            customer.UpdatedAt = DateTime.UtcNow;
            
            var created = await _db.CreateCustomerAsync(customer);
            return await CreateJsonResponse(req, ApiResponse<Customer>.Ok(created, "Customer created successfully"), HttpStatusCode.Created);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating customer");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Update customer
    /// </summary>
    [Function("UpdateCustomer")]
    public async Task<HttpResponseData> UpdateCustomer(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "customers/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Updating customer: {Id}", id);
        
        try
        {
            var existing = await _db.GetCustomerByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Customer not found"), HttpStatusCode.NotFound);
            }
            
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var customer = JsonSerializer.Deserialize<Customer>(body, _jsonOptions);
            
            if (customer == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid customer data"), HttpStatusCode.BadRequest);
            }
            
            customer.Id = id;
            var updated = await _db.UpdateCustomerAsync(customer);
            return await CreateJsonResponse(req, ApiResponse<Customer>.Ok(updated, "Customer updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating customer");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Delete customer (soft delete)
    /// </summary>
    [Function("DeleteCustomer")]
    public async Task<HttpResponseData> DeleteCustomer(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "customers/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Deleting customer: {Id}", id);
        
        try
        {
            var existing = await _db.GetCustomerByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Customer not found"), HttpStatusCode.NotFound);
            }
            
            await _db.DeleteCustomerAsync(id);
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(null!, "Customer deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting customer");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    private async Task<HttpResponseData> CreateJsonResponse<T>(HttpRequestData req, T data, HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        var response = req.CreateResponse(statusCode);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        await response.WriteStringAsync(JsonSerializer.Serialize(data, _jsonOptions));
        return response;
    }
}
