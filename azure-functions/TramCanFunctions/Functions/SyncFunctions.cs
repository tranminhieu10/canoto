using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Sync API functions for offline/online data synchronization
/// </summary>
public class SyncFunctions
{
    private readonly ILogger<SyncFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public SyncFunctions(ILogger<SyncFunctions> logger)
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
    /// Get all changes since last sync time
    /// </summary>
    [Function("GetChanges")]
    public async Task<HttpResponseData> GetChanges(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "sync/changes")] HttpRequestData req)
    {
        _logger.LogInformation("Getting sync changes");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            DateTime? lastSyncTime = DateTime.TryParse(query["lastSyncTime"], out var lst) ? lst : null;
            var stationId = query["stationId"];
            
            var changes = await _db.GetChangesSinceAsync(lastSyncTime, stationId);
            
            var result = ApiResponse<SyncResponse>.Ok(changes, $"Found {changes.TotalChanges} changes");
            return await CreateJsonResponse(req, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting sync changes");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Push local changes to cloud
    /// </summary>
    [Function("PushChanges")]
    public async Task<HttpResponseData> PushChanges(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "sync/push")] HttpRequestData req)
    {
        _logger.LogInformation("Pushing sync changes");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var syncRequest = JsonSerializer.Deserialize<SyncRequest>(body, _jsonOptions);
            
            if (syncRequest == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid sync data"), HttpStatusCode.BadRequest);
            }
            
            var syncedCount = 0;
            
            // Sync weighing tickets
            if (syncRequest.WeighingTickets != null)
            {
                foreach (var ticket in syncRequest.WeighingTickets)
                {
                    var existing = await _db.GetWeighingTicketByIdAsync(ticket.Id);
                    if (existing == null)
                    {
                        await _db.CreateWeighingTicketAsync(ticket);
                    }
                    else if (ticket.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateWeighingTicketAsync(ticket);
                    }
                    syncedCount++;
                }
            }
            
            // Sync customers
            if (syncRequest.Customers != null)
            {
                foreach (var customer in syncRequest.Customers)
                {
                    var existing = await _db.GetCustomerByIdAsync(customer.Id);
                    if (existing == null)
                    {
                        await _db.CreateCustomerAsync(customer);
                    }
                    else if (customer.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateCustomerAsync(customer);
                    }
                    syncedCount++;
                }
            }
            
            // Sync vehicles
            if (syncRequest.Vehicles != null)
            {
                foreach (var vehicle in syncRequest.Vehicles)
                {
                    var existing = await _db.GetVehicleByIdAsync(vehicle.Id);
                    if (existing == null)
                    {
                        await _db.CreateVehicleAsync(vehicle);
                    }
                    else if (vehicle.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateVehicleAsync(vehicle);
                    }
                    syncedCount++;
                }
            }
            
            // Sync products
            if (syncRequest.Products != null)
            {
                foreach (var product in syncRequest.Products)
                {
                    var existing = await _db.GetProductByIdAsync(product.Id);
                    if (existing == null)
                    {
                        await _db.CreateProductAsync(product);
                    }
                    else if (product.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateProductAsync(product);
                    }
                    syncedCount++;
                }
            }
            
            var result = new
            {
                success = true,
                syncedCount = syncedCount,
                syncTime = DateTime.UtcNow
            };
            
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(result, $"Synced {syncedCount} items"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error pushing sync changes");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Full bidirectional sync
    /// </summary>
    [Function("FullSync")]
    public async Task<HttpResponseData> FullSync(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "sync/full")] HttpRequestData req)
    {
        _logger.LogInformation("Performing full sync");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var syncRequest = JsonSerializer.Deserialize<SyncRequest>(body, _jsonOptions);
            
            if (syncRequest == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid sync data"), HttpStatusCode.BadRequest);
            }
            
            var pushedCount = 0;
            
            // Push local changes first
            if (syncRequest.WeighingTickets != null)
            {
                foreach (var ticket in syncRequest.WeighingTickets)
                {
                    var existing = await _db.GetWeighingTicketByIdAsync(ticket.Id);
                    if (existing == null)
                    {
                        await _db.CreateWeighingTicketAsync(ticket);
                        pushedCount++;
                    }
                    else if (ticket.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateWeighingTicketAsync(ticket);
                        pushedCount++;
                    }
                }
            }
            
            if (syncRequest.Customers != null)
            {
                foreach (var customer in syncRequest.Customers)
                {
                    var existing = await _db.GetCustomerByIdAsync(customer.Id);
                    if (existing == null)
                    {
                        await _db.CreateCustomerAsync(customer);
                        pushedCount++;
                    }
                    else if (customer.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateCustomerAsync(customer);
                        pushedCount++;
                    }
                }
            }
            
            if (syncRequest.Vehicles != null)
            {
                foreach (var vehicle in syncRequest.Vehicles)
                {
                    var existing = await _db.GetVehicleByIdAsync(vehicle.Id);
                    if (existing == null)
                    {
                        await _db.CreateVehicleAsync(vehicle);
                        pushedCount++;
                    }
                    else if (vehicle.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateVehicleAsync(vehicle);
                        pushedCount++;
                    }
                }
            }
            
            if (syncRequest.Products != null)
            {
                foreach (var product in syncRequest.Products)
                {
                    var existing = await _db.GetProductByIdAsync(product.Id);
                    if (existing == null)
                    {
                        await _db.CreateProductAsync(product);
                        pushedCount++;
                    }
                    else if (product.UpdatedAt > existing.UpdatedAt)
                    {
                        await _db.UpdateProductAsync(product);
                        pushedCount++;
                    }
                }
            }
            
            // Then get server changes
            var serverChanges = await _db.GetChangesSinceAsync(syncRequest.LastSyncTime, syncRequest.StationId);
            
            var result = new
            {
                success = true,
                pushedCount = pushedCount,
                pulledCount = serverChanges.TotalChanges,
                syncTime = DateTime.UtcNow,
                serverChanges = serverChanges
            };
            
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(result));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error performing full sync");
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
