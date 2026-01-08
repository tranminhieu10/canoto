import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Service for communicating with Azure Functions/App Service
/// Handles REST API calls for data synchronization
class ApiService {
  // Singleton pattern
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // Base URL for Azure API - có thể cấu hình từ settings
  String _baseUrl = 'https://canoto-api.azurewebsites.net/api';
  
  // API endpoints - khớp với Azure Functions
  static const String weighingTicketsEndpoint = '/weighing-tickets';
  static const String vehiclesEndpoint = '/vehicles';
  static const String customersEndpoint = '/customers';
  static const String productsEndpoint = '/products';
  
  // HTTP client
  HttpClient? _client;
  
  // API Key for authentication
  String? _apiKey;

  // Getters
  String get baseUrl => _baseUrl;
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Initialize the API service with settings
  void initialize({String? apiKey, String? baseUrl}) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    }
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
    debugPrint('ApiService: Initialized with baseUrl=$_baseUrl, hasApiKey=${_apiKey != null}');
  }

  /// Update configuration
  void configure({String? apiKey, String? baseUrl}) {
    if (apiKey != null) _apiKey = apiKey;
    if (baseUrl != null && baseUrl.isNotEmpty) _baseUrl = baseUrl;
    debugPrint('ApiService: Configured with baseUrl=$_baseUrl');
  }
  
  /// Dispose resources
  void dispose() {
    _client?.close();
    _client = null;
  }
  
  /// Check if network is available
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// POST request to upload data
  Future<ApiResponse> post(String endpoint, dynamic data) async {
    try {
      // Check network
      if (!await isNetworkAvailable()) {
        return ApiResponse(
          success: false,
          statusCode: 0,
          message: 'No network connection',
          error: 'NETWORK_UNAVAILABLE',
        );
      }

      final uri = Uri.parse('$_baseUrl$endpoint');
      debugPrint('ApiService: POST $uri');
      
      final request = await _client!.postUrl(uri);
      
      // Set headers
      request.headers.set('Content-Type', 'application/json');
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers.set('x-functions-key', _apiKey!);
      }
      
      // Write body
      final jsonData = jsonEncode(data);
      request.write(jsonData);
      
      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      debugPrint('ApiService: Response ${response.statusCode}: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
          message: 'Success',
          data: responseBody.isNotEmpty ? jsonDecode(responseBody) : null,
        );
      } else {
        return ApiResponse(
          success: false,
          statusCode: response.statusCode,
          message: 'API Error',
          error: responseBody,
        );
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Connection failed',
        error: e.toString(),
      );
    } on HttpException catch (e) {
      debugPrint('HttpException: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'HTTP Error',
        error: e.toString(),
      );
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Unknown error',
        error: e.toString(),
      );
    }
  }

  /// GET request to fetch data
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      if (!await isNetworkAvailable()) {
        return ApiResponse(
          success: false,
          statusCode: 0,
          message: 'No network connection',
          error: 'NETWORK_UNAVAILABLE',
        );
      }

      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      debugPrint('ApiService: GET $uri');
      final request = await _client!.getUrl(uri);
      
      // Set headers
      request.headers.set('Accept', 'application/json');
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers.set('x-functions-key', _apiKey!);
      }
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
          message: 'Success',
          data: responseBody.isNotEmpty ? jsonDecode(responseBody) : null,
        );
      } else {
        return ApiResponse(
          success: false,
          statusCode: response.statusCode,
          message: 'API Error',
          error: responseBody,
        );
      }
    } catch (e) {
      debugPrint('API GET Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Unknown error',
        error: e.toString(),
      );
    }
  }

  /// Upload single weighing ticket to Azure
  Future<ApiResponse> createWeighingTicket(Map<String, dynamic> ticket) async {
    return await post(weighingTicketsEndpoint, ticket);
  }

  /// Upload multiple weighing tickets to Azure (batch)
  Future<ApiResponse> uploadWeighingTicketsData(List<Map<String, dynamic>> tickets) async {
    // Azure Functions expects individual tickets, so we send them one by one
    // and collect results
    List<String> successIds = [];
    List<String> failedIds = [];
    
    for (final ticket in tickets) {
      final result = await createWeighingTicket(ticket);
      final ticketId = ticket['ticketNumber'] ?? ticket['id'] ?? 'unknown';
      if (result.success) {
        successIds.add(ticketId.toString());
      } else {
        failedIds.add(ticketId.toString());
      }
    }
    
    if (failedIds.isEmpty) {
      return ApiResponse(
        success: true,
        statusCode: 200,
        message: 'All ${successIds.length} tickets synced successfully',
        data: {'syncedIds': successIds},
      );
    } else if (successIds.isEmpty) {
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Failed to sync all tickets',
        error: 'Failed tickets: ${failedIds.join(", ")}',
      );
    } else {
      return ApiResponse(
        success: true,
        statusCode: 200,
        message: '${successIds.length} synced, ${failedIds.length} failed',
        data: {'syncedIds': successIds, 'failedIds': failedIds},
      );
    }
  }

  /// Get weighing tickets from Azure
  Future<ApiResponse> getWeighingTickets({int page = 1, int pageSize = 50}) async {
    return await get(weighingTicketsEndpoint, queryParams: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final int statusCode;
  final String message;
  final dynamic data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.error,
  });

  /// Check if response contains Azure IDs
  List<int>? get azureIds {
    if (success && data != null && data is Map) {
      final ids = data['azureIds'];
      if (ids is List) {
        return ids.cast<int>();
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message, error: $error)';
  }
}
