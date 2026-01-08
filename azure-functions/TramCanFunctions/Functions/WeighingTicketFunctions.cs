using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Weighing Ticket API functions
/// </summary>
public class WeighingTicketFunctions
{
    private readonly ILogger<WeighingTicketFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public WeighingTicketFunctions(ILogger<WeighingTicketFunctions> logger)
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
    /// Get all weighing tickets with pagination and filters
    /// </summary>
    [Function("GetWeighingTickets")]
    public async Task<HttpResponseData> GetWeighingTickets(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "weighing-tickets")] HttpRequestData req)
    {
        _logger.LogInformation("Getting weighing tickets");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var page = int.TryParse(query["page"], out var p) ? p : 1;
            var pageSize = int.TryParse(query["pageSize"], out var ps) ? ps : 50;
            var status = query["status"];
            var vehiclePlate = query["vehiclePlate"];
            DateTime? fromDate = DateTime.TryParse(query["fromDate"], out var fd) ? fd : null;
            DateTime? toDate = DateTime.TryParse(query["toDate"], out var td) ? td : null;
            
            var tickets = await _db.GetWeighingTicketsAsync(page, pageSize, fromDate, toDate, status, vehiclePlate);
            var totalCount = await _db.GetWeighingTicketsCountAsync(fromDate, toDate, status);
            
            var result = ApiResponse<List<WeighingTicket>>.Ok(tickets, totalCount, page, pageSize);
            return await CreateJsonResponse(req, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting weighing tickets");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get weighing ticket by ID
    /// </summary>
    [Function("GetWeighingTicket")]
    public async Task<HttpResponseData> GetWeighingTicket(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "weighing-tickets/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Getting weighing ticket: {Id}", id);
        
        try
        {
            var ticket = await _db.GetWeighingTicketByIdAsync(id);
            
            if (ticket == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Ticket not found"), HttpStatusCode.NotFound);
            }
            
            return await CreateJsonResponse(req, ApiResponse<WeighingTicket>.Ok(ticket));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting weighing ticket");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Create new weighing ticket
    /// </summary>
    [Function("CreateWeighingTicket")]
    public async Task<HttpResponseData> CreateWeighingTicket(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "weighing-tickets")] HttpRequestData req)
    {
        _logger.LogInformation("Creating weighing ticket");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var ticket = JsonSerializer.Deserialize<WeighingTicket>(body, _jsonOptions);
            
            if (ticket == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid ticket data"), HttpStatusCode.BadRequest);
            }
            
            ticket.Id = string.IsNullOrEmpty(ticket.Id) ? Guid.NewGuid().ToString() : ticket.Id;
            ticket.CreatedAt = DateTime.UtcNow;
            ticket.UpdatedAt = DateTime.UtcNow;
            
            var created = await _db.CreateWeighingTicketAsync(ticket);
            return await CreateJsonResponse(req, ApiResponse<WeighingTicket>.Ok(created, "Ticket created successfully"), HttpStatusCode.Created);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating weighing ticket");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Update weighing ticket
    /// </summary>
    [Function("UpdateWeighingTicket")]
    public async Task<HttpResponseData> UpdateWeighingTicket(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "weighing-tickets/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Updating weighing ticket: {Id}", id);
        
        try
        {
            var existing = await _db.GetWeighingTicketByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Ticket not found"), HttpStatusCode.NotFound);
            }
            
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var ticket = JsonSerializer.Deserialize<WeighingTicket>(body, _jsonOptions);
            
            if (ticket == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid ticket data"), HttpStatusCode.BadRequest);
            }
            
            ticket.Id = id;
            var updated = await _db.UpdateWeighingTicketAsync(ticket);
            return await CreateJsonResponse(req, ApiResponse<WeighingTicket>.Ok(updated, "Ticket updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating weighing ticket");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Delete weighing ticket (soft delete)
    /// </summary>
    [Function("DeleteWeighingTicket")]
    public async Task<HttpResponseData> DeleteWeighingTicket(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "weighing-tickets/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Deleting weighing ticket: {Id}", id);
        
        try
        {
            var existing = await _db.GetWeighingTicketByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Ticket not found"), HttpStatusCode.NotFound);
            }
            
            await _db.DeleteWeighingTicketAsync(id);
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(null!, "Ticket deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting weighing ticket");
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
