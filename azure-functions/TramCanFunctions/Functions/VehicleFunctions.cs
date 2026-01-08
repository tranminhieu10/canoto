using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Vehicle API functions
/// </summary>
public class VehicleFunctions
{
    private readonly ILogger<VehicleFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public VehicleFunctions(ILogger<VehicleFunctions> logger)
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
    /// Get all vehicles with pagination
    /// </summary>
    [Function("GetVehicles")]
    public async Task<HttpResponseData> GetVehicles(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "vehicles")] HttpRequestData req)
    {
        _logger.LogInformation("Getting vehicles");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var page = int.TryParse(query["page"], out var p) ? p : 1;
            var pageSize = int.TryParse(query["pageSize"], out var ps) ? ps : 50;
            var search = query["search"];
            
            var vehicles = await _db.GetVehiclesAsync(page, pageSize, search);
            var totalCount = await _db.GetVehiclesCountAsync(search);
            
            var result = ApiResponse<List<Vehicle>>.Ok(vehicles, totalCount, page, pageSize);
            return await CreateJsonResponse(req, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vehicles");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get vehicle by ID
    /// </summary>
    [Function("GetVehicle")]
    public async Task<HttpResponseData> GetVehicle(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "vehicles/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Getting vehicle: {Id}", id);
        
        try
        {
            var vehicle = await _db.GetVehicleByIdAsync(id);
            
            if (vehicle == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Vehicle not found"), HttpStatusCode.NotFound);
            }
            
            return await CreateJsonResponse(req, ApiResponse<Vehicle>.Ok(vehicle));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vehicle");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get vehicle by plate number
    /// </summary>
    [Function("GetVehicleByPlate")]
    public async Task<HttpResponseData> GetVehicleByPlate(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "vehicles/plate/{plateNumber}")] HttpRequestData req,
        string plateNumber)
    {
        _logger.LogInformation("Getting vehicle by plate: {PlateNumber}", plateNumber);
        
        try
        {
            var vehicle = await _db.GetVehicleByPlateAsync(plateNumber);
            
            if (vehicle == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Vehicle not found"), HttpStatusCode.NotFound);
            }
            
            return await CreateJsonResponse(req, ApiResponse<Vehicle>.Ok(vehicle));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vehicle by plate");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Create new vehicle
    /// </summary>
    [Function("CreateVehicle")]
    public async Task<HttpResponseData> CreateVehicle(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "vehicles")] HttpRequestData req)
    {
        _logger.LogInformation("Creating vehicle");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var vehicle = JsonSerializer.Deserialize<Vehicle>(body, _jsonOptions);
            
            if (vehicle == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid vehicle data"), HttpStatusCode.BadRequest);
            }
            
            // Check if plate already exists
            var existing = await _db.GetVehicleByPlateAsync(vehicle.PlateNumber);
            if (existing != null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Vehicle with this plate number already exists"), HttpStatusCode.Conflict);
            }
            
            vehicle.Id = string.IsNullOrEmpty(vehicle.Id) ? Guid.NewGuid().ToString() : vehicle.Id;
            vehicle.CreatedAt = DateTime.UtcNow;
            vehicle.UpdatedAt = DateTime.UtcNow;
            
            var created = await _db.CreateVehicleAsync(vehicle);
            return await CreateJsonResponse(req, ApiResponse<Vehicle>.Ok(created, "Vehicle created successfully"), HttpStatusCode.Created);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating vehicle");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Update vehicle
    /// </summary>
    [Function("UpdateVehicle")]
    public async Task<HttpResponseData> UpdateVehicle(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "vehicles/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Updating vehicle: {Id}", id);
        
        try
        {
            var existing = await _db.GetVehicleByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Vehicle not found"), HttpStatusCode.NotFound);
            }
            
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var vehicle = JsonSerializer.Deserialize<Vehicle>(body, _jsonOptions);
            
            if (vehicle == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid vehicle data"), HttpStatusCode.BadRequest);
            }
            
            vehicle.Id = id;
            var updated = await _db.UpdateVehicleAsync(vehicle);
            return await CreateJsonResponse(req, ApiResponse<Vehicle>.Ok(updated, "Vehicle updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating vehicle");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Delete vehicle (soft delete)
    /// </summary>
    [Function("DeleteVehicle")]
    public async Task<HttpResponseData> DeleteVehicle(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "vehicles/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Deleting vehicle: {Id}", id);
        
        try
        {
            var existing = await _db.GetVehicleByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Vehicle not found"), HttpStatusCode.NotFound);
            }
            
            await _db.DeleteVehicleAsync(id);
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(null!, "Vehicle deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting vehicle");
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
