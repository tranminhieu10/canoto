using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;
using TramCanFunctions.Services;

namespace TramCanFunctions.Functions;

/// <summary>
/// Product API functions
/// </summary>
public class ProductFunctions
{
    private readonly ILogger<ProductFunctions> _logger;
    private readonly DatabaseService _db;
    private readonly JsonSerializerOptions _jsonOptions;

    public ProductFunctions(ILogger<ProductFunctions> logger)
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
    /// Get all products with pagination
    /// </summary>
    [Function("GetProducts")]
    public async Task<HttpResponseData> GetProducts(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] HttpRequestData req)
    {
        _logger.LogInformation("Getting products");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var page = int.TryParse(query["page"], out var p) ? p : 1;
            var pageSize = int.TryParse(query["pageSize"], out var ps) ? ps : 50;
            var search = query["search"];
            
            var products = await _db.GetProductsAsync(page, pageSize, search);
            var totalCount = await _db.GetProductsCountAsync(search);
            
            var result = ApiResponse<List<Product>>.Ok(products, totalCount, page, pageSize);
            return await CreateJsonResponse(req, result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Get product by ID
    /// </summary>
    [Function("GetProduct")]
    public async Task<HttpResponseData> GetProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Getting product: {Id}", id);
        
        try
        {
            var product = await _db.GetProductByIdAsync(id);
            
            if (product == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Product not found"), HttpStatusCode.NotFound);
            }
            
            return await CreateJsonResponse(req, ApiResponse<Product>.Ok(product));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Create new product
    /// </summary>
    [Function("CreateProduct")]
    public async Task<HttpResponseData> CreateProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "products")] HttpRequestData req)
    {
        _logger.LogInformation("Creating product");
        
        try
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var product = JsonSerializer.Deserialize<Product>(body, _jsonOptions);
            
            if (product == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid product data"), HttpStatusCode.BadRequest);
            }
            
            product.Id = string.IsNullOrEmpty(product.Id) ? Guid.NewGuid().ToString() : product.Id;
            product.CreatedAt = DateTime.UtcNow;
            product.UpdatedAt = DateTime.UtcNow;
            
            var created = await _db.CreateProductAsync(product);
            return await CreateJsonResponse(req, ApiResponse<Product>.Ok(created, "Product created successfully"), HttpStatusCode.Created);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Update product
    /// </summary>
    [Function("UpdateProduct")]
    public async Task<HttpResponseData> UpdateProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "products/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Updating product: {Id}", id);
        
        try
        {
            var existing = await _db.GetProductByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Product not found"), HttpStatusCode.NotFound);
            }
            
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            var product = JsonSerializer.Deserialize<Product>(body, _jsonOptions);
            
            if (product == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Invalid product data"), HttpStatusCode.BadRequest);
            }
            
            product.Id = id;
            var updated = await _db.UpdateProductAsync(product);
            return await CreateJsonResponse(req, ApiResponse<Product>.Ok(updated, "Product updated successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product");
            return await CreateJsonResponse(req, ApiResponse<object>.Error(ex.Message), HttpStatusCode.InternalServerError);
        }
    }

    /// <summary>
    /// Delete product (soft delete)
    /// </summary>
    [Function("DeleteProduct")]
    public async Task<HttpResponseData> DeleteProduct(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "products/{id}")] HttpRequestData req,
        string id)
    {
        _logger.LogInformation("Deleting product: {Id}", id);
        
        try
        {
            var existing = await _db.GetProductByIdAsync(id);
            if (existing == null)
            {
                return await CreateJsonResponse(req, ApiResponse<object>.Error("Product not found"), HttpStatusCode.NotFound);
            }
            
            await _db.DeleteProductAsync(id);
            return await CreateJsonResponse(req, ApiResponse<object>.Ok(null!, "Product deleted successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product");
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
