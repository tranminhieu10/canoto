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

  // Base URL for Azure API
  // TODO: Replace with actual Azure Functions URL
  static const String baseUrl = 'https://canoto-api.azurewebsites.net/api';
  
  // API endpoints
  static const String uploadWeighingTickets = '/weighing-tickets/upload';
  static const String getWeighingTickets = '/weighing-tickets';
  static const String uploadVehicles = '/vehicles/upload';
  static const String uploadCustomers = '/customers/upload';
  static const String uploadProducts = '/products/upload';
  
  // HTTP client
  HttpClient? _client;
  
  // API Key for authentication (optional)
  String? _apiKey;
  
  /// Initialize the API service
  void initialize({String? apiKey}) {
    _apiKey = apiKey;
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 60);
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

      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _client!.postUrl(uri);
      
      // Set headers
      request.headers.set('Content-Type', 'application/json');
      if (_apiKey != null) {
        request.headers.set('x-functions-key', _apiKey!);
      }
      
      // Write body
      final jsonData = jsonEncode(data);
      request.write(jsonData);
      
      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
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

      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final request = await _client!.getUrl(uri);
      
      // Set headers
      request.headers.set('Accept', 'application/json');
      if (_apiKey != null) {
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

  /// Upload weighing tickets to Azure
  Future<ApiResponse> uploadWeighingTicketsData(List<Map<String, dynamic>> tickets) async {
    return await post(uploadWeighingTickets, {'tickets': tickets});
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
