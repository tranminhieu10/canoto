using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Report API functions for analytics and statistics
/// </summary>
public class ReportFunctions
{
    private readonly ILogger<ReportFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public ReportFunctions(ILogger<ReportFunctions> logger)
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
    /// Get daily weighing summary
    /// </summary>
    [Function("GetDailySummary")]
    public async Task<HttpResponseData> GetDailySummary(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "reports/daily")] HttpRequestData req)
    {
        _logger.LogInformation("Getting daily summary");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var dateStr = query["date"];
            var date = string.IsNullOrEmpty(dateStr) ? DateTime.Today : DateTime.Parse(dateStr);
            
            var startOfDay = date.Date;
            var endOfDay = date.Date.AddDays(1).AddSeconds(-1);
            
            var tickets = await _db.GetWeighingTicketsAsync(1, 1000, startOfDay, endOfDay);
            
            var summary = new
            {
                date = date.ToString("yyyy-MM-dd"),
                totalTickets = tickets.Count,
                completedTickets = tickets.Count(t => t.Status == "completed"),
                pendingTickets = tickets.Count(t => t.Status == "pending"),
                cancelledTickets = tickets.Count(t => t.Status == "cancelled"),
                totalNetWeight = tickets.Where(t => t.Status == "completed").Sum(t => t.NetWeight),
                totalAmount = tickets.Where(t => t.Status == "completed").Sum(t => t.TotalAmount ?? 0),
                averageWeight = tickets.Where(t => t.Status == "completed").Any() 
                    ? tickets.Where(t => t.Status == "completed").Average(t => t.NetWeight) 
                    : 0,
                tickets = tickets.Take(20) // Last 20 tickets
            };
            
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(summary));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting daily summary");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get weighing statistics by date range
    /// </summary>
    [Function("GetStatistics")]
    public async Task<HttpResponseData> GetStatistics(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "reports/statistics")] HttpRequestData req)
    {
        _logger.LogInformation("Getting statistics");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var fromDateStr = query["fromDate"];
            var toDateStr = query["toDate"];
            
            var fromDate = string.IsNullOrEmpty(fromDateStr) ? DateTime.Today.AddDays(-30) : DateTime.Parse(fromDateStr);
            var toDate = string.IsNullOrEmpty(toDateStr) ? DateTime.Today.AddDays(1) : DateTime.Parse(toDateStr);
            
            var tickets = await _db.GetWeighingTicketsAsync(1, 10000, fromDate, toDate);
            var customers = await _db.GetCustomersAsync(1, 1000);
            var vehicles = await _db.GetVehiclesAsync(1, 1000);
            var products = await _db.GetProductsAsync(1, 1000);
            
            // Group by date
            var dailyStats = tickets
                .Where(t => t.Status == "completed")
                .GroupBy(t => t.CreatedAt.Date)
                .Select(g => new
                {
                    date = g.Key.ToString("yyyy-MM-dd"),
                    count = g.Count(),
                    totalWeight = g.Sum(t => t.NetWeight),
                    totalAmount = g.Sum(t => t.TotalAmount ?? 0)
                })
                .OrderBy(x => x.date)
                .ToList();
            
            // Top customers
            var topCustomers = tickets
                .Where(t => t.Status == "completed" && !string.IsNullOrEmpty(t.CustomerName))
                .GroupBy(t => t.CustomerName)
                .Select(g => new
                {
                    customer = g.Key,
                    ticketCount = g.Count(),
                    totalWeight = g.Sum(t => t.NetWeight),
                    totalAmount = g.Sum(t => t.TotalAmount ?? 0)
                })
                .OrderByDescending(x => x.totalWeight)
                .Take(10)
                .ToList();
            
            // Top products
            var topProducts = tickets
                .Where(t => t.Status == "completed" && !string.IsNullOrEmpty(t.ProductName))
                .GroupBy(t => t.ProductName)
                .Select(g => new
                {
                    product = g.Key,
                    ticketCount = g.Count(),
                    totalWeight = g.Sum(t => t.NetWeight),
                    totalAmount = g.Sum(t => t.TotalAmount ?? 0)
                })
                .OrderByDescending(x => x.totalWeight)
                .Take(10)
                .ToList();
            
            var statistics = new
            {
                period = new { fromDate = fromDate.ToString("yyyy-MM-dd"), toDate = toDate.ToString("yyyy-MM-dd") },
                overview = new
                {
                    totalTickets = tickets.Count,
                    completedTickets = tickets.Count(t => t.Status == "completed"),
                    totalNetWeight = tickets.Where(t => t.Status == "completed").Sum(t => t.NetWeight),
                    totalAmount = tickets.Where(t => t.Status == "completed").Sum(t => t.TotalAmount ?? 0),
                    totalCustomers = customers.Count,
                    totalVehicles = vehicles.Count,
                    totalProducts = products.Count
                },
                dailyStats,
                topCustomers,
                topProducts
            };
            
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(statistics));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting statistics");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get customer report
    /// </summary>
    [Function("GetCustomerReport")]
    public async Task<HttpResponseData> GetCustomerReport(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "reports/customer/{customerId}")] HttpRequestData req,
        string customerId)
    {
        _logger.LogInformation("Getting customer report: {CustomerId}", customerId);
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var fromDateStr = query["fromDate"];
            var toDateStr = query["toDate"];
            
            var fromDate = string.IsNullOrEmpty(fromDateStr) ? DateTime.Today.AddDays(-30) : DateTime.Parse(fromDateStr);
            var toDate = string.IsNullOrEmpty(toDateStr) ? DateTime.Today.AddDays(1) : DateTime.Parse(toDateStr);
            
            var customer = await _db.GetCustomerByIdAsync(customerId);
            if (customer == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Customer not found"), HttpStatusCode.NotFound);
            }
            
            var allTickets = await _db.GetWeighingTicketsAsync(1, 10000, fromDate, toDate);
            var customerTickets = allTickets.Where(t => t.CustomerId == customerId).ToList();
            
            var report = new
            {
                customer,
                period = new { fromDate = fromDate.ToString("yyyy-MM-dd"), toDate = toDate.ToString("yyyy-MM-dd") },
                summary = new
                {
                    totalTickets = customerTickets.Count,
                    completedTickets = customerTickets.Count(t => t.Status == "completed"),
                    totalNetWeight = customerTickets.Where(t => t.Status == "completed").Sum(t => t.NetWeight),
                    totalAmount = customerTickets.Where(t => t.Status == "completed").Sum(t => t.TotalAmount ?? 0)
                },
                recentTickets = customerTickets.OrderByDescending(t => t.CreatedAt).Take(20)
            };
            
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(report));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customer report");
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
