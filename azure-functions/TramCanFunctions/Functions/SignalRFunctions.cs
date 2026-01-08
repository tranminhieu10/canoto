using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace TramCanFunctions.Functions;

/// <summary>
/// SignalR Service functions for real-time notifications
/// </summary>
public class SignalRFunctions
{
    private readonly ILogger<SignalRFunctions> _logger;

    public SignalRFunctions(ILogger<SignalRFunctions> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Negotiate endpoint for SignalR clients
    /// Returns connection info with access token
    /// </summary>
    [Function("negotiate")]
    public async Task<HttpResponseData> Negotiate(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "negotiate")] HttpRequestData req,
        [SignalRConnectionInfoInput(HubName = "notificationHub")] SignalRConnectionInfo connectionInfo)
    {
        _logger.LogInformation("SignalR negotiate called");
        
        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json; charset=utf-8");
        
        var json = JsonSerializer.Serialize(new 
        { 
            url = connectionInfo.Url, 
            accessToken = connectionInfo.AccessToken 
        });
        
        await response.WriteStringAsync(json);
        return response;
    }

    /// <summary>
    /// Broadcast message to all connected clients
    /// </summary>
    [Function("broadcast")]
    [SignalROutput(HubName = "notificationHub")]
    public SignalRMessageAction Broadcast(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "broadcast")] HttpRequestData req)
    {
        _logger.LogInformation("Broadcasting message to all clients");
        
        using var reader = new StreamReader(req.Body);
        var message = reader.ReadToEnd();
        
        return new SignalRMessageAction("newMessage")
        {
            Arguments = new object[] { message }
        };
    }

    /// <summary>
    /// Send notification to specific group
    /// </summary>
    [Function("sendToGroup")]
    [SignalROutput(HubName = "notificationHub")]
    public SignalRMessageAction SendToGroup(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "sendToGroup/{groupName}")] HttpRequestData req,
        string groupName)
    {
        _logger.LogInformation("Sending message to group: {GroupName}", groupName);
        
        using var reader = new StreamReader(req.Body);
        var message = reader.ReadToEnd();
        
        return new SignalRMessageAction("newMessage")
        {
            GroupName = groupName,
            Arguments = new object[] { message }
        };
    }

    /// <summary>
    /// Send weighing ticket notification
    /// </summary>
    [Function("notifyWeighingTicket")]
    [SignalROutput(HubName = "notificationHub")]
    public SignalRMessageAction NotifyWeighingTicket(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "notify/weighing-ticket")] HttpRequestData req)
    {
        _logger.LogInformation("Sending weighing ticket notification");
        
        using var reader = new StreamReader(req.Body);
        var message = reader.ReadToEnd();
        
        return new SignalRMessageAction("weighingTicketUpdate")
        {
            Arguments = new object[] { message }
        };
    }

    /// <summary>
    /// Send data sync notification
    /// </summary>
    [Function("notifySync")]
    [SignalROutput(HubName = "notificationHub")]
    public SignalRMessageAction NotifySync(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "notify/sync")] HttpRequestData req)
    {
        _logger.LogInformation("Sending sync notification");
        
        using var reader = new StreamReader(req.Body);
        var message = reader.ReadToEnd();
        
        return new SignalRMessageAction("syncRequired")
        {
            Arguments = new object[] { message }
        };
    }
}
