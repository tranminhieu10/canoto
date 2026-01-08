using System.Net;
using System.Text.Json;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using TramCanFunctions.Models;

namespace TramCanFunctions.Functions;

/// <summary>
/// Blob storage functions for image upload/download
/// </summary>
public class BlobFunctions
{
    private readonly ILogger<BlobFunctions> _logger;
    private readonly string _connectionString;
    private readonly JsonSerializerOptions _jsonOptions;

    public BlobFunctions(ILogger<BlobFunctions> logger)
    {
        _logger = logger;
        _connectionString = Environment.GetEnvironmentVariable("AzureBlobStorage") 
            ?? "UseDevelopmentStorage=true";
        _jsonOptions = new JsonSerializerOptions 
        { 
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase 
        };
    }

    /// <summary>
    /// Upload image to blob storage
    /// </summary>
    [Function("UploadImage")]
    public async Task<HttpResponseData> UploadImage(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "images/upload")] HttpRequestData req)
    {
        _logger.LogInformation("Uploading image");
        
        try
        {
            // Get container name and file name from headers or query
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var containerName = query["container"] ?? "weighing-images";
            var fileName = query["filename"] ?? $"{Guid.NewGuid()}.jpg";
            var ticketId = query["ticketId"];
            var imageType = query["type"] ?? "first"; // first or second
            
            // Create container if not exists
            var blobServiceClient = new BlobServiceClient(_connectionString);
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);
            
            // Generate blob name with path structure
            var blobName = string.IsNullOrEmpty(ticketId) 
                ? $"{DateTime.UtcNow:yyyy/MM/dd}/{fileName}"
                : $"tickets/{ticketId}/{imageType}_{fileName}";
            
            var blobClient = containerClient.GetBlobClient(blobName);
            
            // Upload the image
            await blobClient.UploadAsync(req.Body, new BlobHttpHeaders 
            { 
                ContentType = req.Headers.GetValues("Content-Type").FirstOrDefault() ?? "image/jpeg" 
            });
            
            var result = new
            {
                success = true,
                url = blobClient.Uri.ToString(),
                blobName = blobName,
                container = containerName
            };
            
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(result, _jsonOptions));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading image");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(
                ApiResponse<object>.Error(ex.Message), _jsonOptions));
            return response;
        }
    }

    /// <summary>
    /// Get SAS URL for image download
    /// </summary>
    [Function("GetImageUrl")]
    public async Task<HttpResponseData> GetImageUrl(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "images/{*blobPath}")] HttpRequestData req,
        string blobPath)
    {
        _logger.LogInformation("Getting image URL for: {BlobPath}", blobPath);
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var containerName = query["container"] ?? "weighing-images";
            
            var blobServiceClient = new BlobServiceClient(_connectionString);
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobPath);
            
            if (!await blobClient.ExistsAsync())
            {
                var response = req.CreateResponse(HttpStatusCode.NotFound);
                response.Headers.Add("Content-Type", "application/json; charset=utf-8");
                await response.WriteStringAsync(JsonSerializer.Serialize(
                    ApiResponse<object>.Error("Image not found"), _jsonOptions));
                return response;
            }
            
            var result = new
            {
                success = true,
                url = blobClient.Uri.ToString()
            };
            
            var okResponse = req.CreateResponse(HttpStatusCode.OK);
            okResponse.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await okResponse.WriteStringAsync(JsonSerializer.Serialize(result, _jsonOptions));
            return okResponse;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting image URL");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(
                ApiResponse<object>.Error(ex.Message), _jsonOptions));
            return response;
        }
    }

    /// <summary>
    /// Delete image from blob storage
    /// </summary>
    [Function("DeleteImage")]
    public async Task<HttpResponseData> DeleteImage(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "images/{*blobPath}")] HttpRequestData req,
        string blobPath)
    {
        _logger.LogInformation("Deleting image: {BlobPath}", blobPath);
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var containerName = query["container"] ?? "weighing-images";
            
            var blobServiceClient = new BlobServiceClient(_connectionString);
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobPath);
            
            var deleted = await blobClient.DeleteIfExistsAsync();
            
            var result = new
            {
                success = true,
                deleted = deleted.Value,
                blobPath = blobPath
            };
            
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(result, _jsonOptions));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(
                ApiResponse<object>.Error(ex.Message), _jsonOptions));
            return response;
        }
    }

    /// <summary>
    /// List images in a container/folder
    /// </summary>
    [Function("ListImages")]
    public async Task<HttpResponseData> ListImages(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "images")] HttpRequestData req)
    {
        _logger.LogInformation("Listing images");
        
        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var containerName = query["container"] ?? "weighing-images";
            var prefix = query["prefix"] ?? "";
            
            var blobServiceClient = new BlobServiceClient(_connectionString);
            var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
            
            var blobs = new List<object>();
            await foreach (var blobItem in containerClient.GetBlobsAsync(prefix: prefix))
            {
                blobs.Add(new
                {
                    name = blobItem.Name,
                    size = blobItem.Properties.ContentLength,
                    contentType = blobItem.Properties.ContentType,
                    createdOn = blobItem.Properties.CreatedOn,
                    url = $"{containerClient.Uri}/{blobItem.Name}"
                });
            }
            
            var result = ApiResponse<List<object>>.Ok(blobs);
            
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(result, _jsonOptions));
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error listing images");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            await response.WriteStringAsync(JsonSerializer.Serialize(
                ApiResponse<object>.Error(ex.Message), _jsonOptions));
            return response;
        }
    }
}
