import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:canoto/core/constants/azure_config.dart';

/// MQTT Service for Azure IoT Hub communication
/// Handles device-to-cloud and cloud-to-device messaging
class MqttService {
  // Singleton pattern
  static MqttService? _instance;
  static MqttService get instance => _instance ??= MqttService._();
  MqttService._();

  MqttServerClient? _client;
  
  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 5);
  Timer? _reconnectTimer;
  
  // Message streams
  final StreamController<MqttReceivedData> _messageController = 
      StreamController<MqttReceivedData>.broadcast();
  Stream<MqttReceivedData> get messageStream => _messageController.stream;
  
  // Connection status stream
  final StreamController<MqttConnectionState> _connectionController = 
      StreamController<MqttConnectionState>.broadcast();
  Stream<MqttConnectionState> get connectionStream => _connectionController.stream;

  /// Initialize and connect to Azure IoT Hub
  Future<bool> connect({
    String? hostname,
    String? deviceId,
    String? sasToken,
  }) async {
    final host = hostname ?? AzureConfig.iotHubHostname;
    final device = deviceId ?? AzureConfig.iotDeviceId;
    
    try {
      _client = MqttServerClient.withPort(
        host,
        device,
        AzureConfig.iotHubMqttPort,
      );

      // Configure client
      _client!.logging(on: AzureConfig.isDevelopment);
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect = true;
      _client!.secure = true;
      
      // Set security context for TLS
      final securityContext = SecurityContext.defaultContext;
      _client!.securityContext = securityContext;

      // Connection message - Azure IoT Hub requires MQTT 3.1.1 (protocol version 4)
      final connMessage = MqttConnectMessage()
          .withProtocolName('MQTT')  // Use 'MQTT' for version 3.1.1, 'MQIsdp' for 3.1
          .withProtocolVersion(4)    // MQTT 3.1.1 = version 4
          .withClientIdentifier(device)
          .authenticateAs(
            '$host/$device/?api-version=2021-04-12',
            sasToken ?? _generateSasToken(host, device),
          )
          .startClean();

      _client!.connectionMessage = connMessage;

      // Set up callbacks
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onAutoReconnect = _onAutoReconnect;
      _client!.onAutoReconnected = _onAutoReconnected;
      _client!.onSubscribed = _onSubscribed;

      debugPrint('MqttService: Connecting to $host...');
      _connectionController.add(MqttConnectionState.connecting);

      final result = await _client!.connect();
      
      if (result?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _reconnectAttempts = 0;
        _subscribeToTopics(device);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('MqttService: Connection error: $e');
      _connectionController.add(MqttConnectionState.faulted);
      _scheduleReconnect();
      return false;
    }
  }

  /// Subscribe to device topics
  void _subscribeToTopics(String deviceId) {
    if (_client == null) return;
    
    // Cloud-to-device messages
    final c2dTopic = 'devices/$deviceId/messages/devicebound/#';
    _client!.subscribe(c2dTopic, MqttQos.atLeastOnce);
    
    // Direct method invocations
    final methodTopic = '\$iothub/methods/POST/#';
    _client!.subscribe(methodTopic, MqttQos.atLeastOnce);
    
    // Device twin desired property updates
    final twinTopic = '\$iothub/twin/PATCH/properties/desired/#';
    _client!.subscribe(twinTopic, MqttQos.atLeastOnce);
    
    // Listen for messages
    _client!.updates?.listen((messages) {
      for (final message in messages) {
        final topic = message.topic;
        final payload = message.payload as MqttPublishMessage;
        final data = MqttPublishPayload.bytesToStringAsString(
          payload.payload.message,
        );
        
        debugPrint('MqttService: Received on $topic: $data');
        
        _messageController.add(MqttReceivedData(
          topic: topic,
          payload: data,
          timestamp: DateTime.now(),
        ));
        
        // Handle specific message types
        _handleMessage(topic, data);
      }
    });
    
    debugPrint('MqttService: Subscribed to topics');
  }

  /// Process specific message types
  void _handleMessage(String topic, String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      
      if (topic.contains('methods/POST')) {
        // Direct method invocation
        _handleDirectMethod(topic, json);
      } else if (topic.contains('twin/PATCH')) {
        // Device twin update
        _handleTwinUpdate(json);
      } else if (topic.contains('devicebound')) {
        // Cloud-to-device message
        _handleC2DMessage(json);
      }
    } catch (e) {
      debugPrint('MqttService: Error processing message: $e');
    }
  }

  /// Handle direct method invocations
  void _handleDirectMethod(String topic, Map<String, dynamic> payload) {
    // Extract method name from topic
    final methodName = topic.split('/').last.split('?').first;
    debugPrint('MqttService: Direct method: $methodName');
    
    switch (methodName) {
      case 'openBarrier':
        // Trigger barrier open
        _publishMethodResponse(topic, {'success': true, 'message': 'Barrier opened'});
        break;
      case 'closeBarrier':
        // Trigger barrier close
        _publishMethodResponse(topic, {'success': true, 'message': 'Barrier closed'});
        break;
      case 'captureImage':
        // Trigger camera capture
        _publishMethodResponse(topic, {'success': true, 'message': 'Image captured'});
        break;
      case 'getWeight':
        // Get current weight
        _publishMethodResponse(topic, {'success': true, 'weight': 0.0});
        break;
      default:
        _publishMethodResponse(topic, {'success': false, 'error': 'Unknown method'});
    }
  }

  /// Publish method response
  void _publishMethodResponse(String requestTopic, Map<String, dynamic> response) {
    // Extract request ID from topic
    final requestId = Uri.parse(requestTopic).queryParameters['\$rid'];
    if (requestId == null) return;
    
    final responseTopic = '\$iothub/methods/res/200/?rid=$requestId';
    publishMessage(responseTopic, jsonEncode(response));
  }

  /// Handle device twin updates
  void _handleTwinUpdate(Map<String, dynamic> payload) {
    debugPrint('MqttService: Twin update: $payload');
    // Process twin desired properties
  }

  /// Handle cloud-to-device messages
  void _handleC2DMessage(Map<String, dynamic> payload) {
    debugPrint('MqttService: C2D message: $payload');
    // Process C2D message (e.g., notifications, commands)
  }

  /// Publish message to Azure IoT Hub
  Future<bool> publishMessage(String topic, String message) async {
    if (_client == null || !_isConnected) {
      debugPrint('MqttService: Not connected, cannot publish');
      return false;
    }
    
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      
      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      
      debugPrint('MqttService: Published to $topic');
      return true;
    } catch (e) {
      debugPrint('MqttService: Publish error: $e');
      return false;
    }
  }

  /// Send telemetry data to IoT Hub
  Future<bool> sendTelemetry(Map<String, dynamic> data) async {
    final deviceId = AzureConfig.iotDeviceId;
    final topic = 'devices/$deviceId/messages/events/';
    
    final payload = jsonEncode({
      ...data,
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': deviceId,
    });
    
    return publishMessage(topic, payload);
  }

  /// Send weighing event
  Future<bool> sendWeighingEvent({
    required String ticketNumber,
    required String licensePlate,
    required double weight,
    required String eventType, // 'first_weight', 'second_weight', 'completed'
  }) async {
    return sendTelemetry({
      'eventType': 'weighing',
      'ticketNumber': ticketNumber,
      'licensePlate': licensePlate,
      'weight': weight,
      'weighingEventType': eventType,
    });
  }

  /// Send device status
  Future<bool> sendDeviceStatus({
    required bool scaleOnline,
    required bool cameraOnline,
    required bool barrierOnline,
    required bool printerOnline,
  }) async {
    return sendTelemetry({
      'eventType': 'deviceStatus',
      'scale': scaleOnline ? 'online' : 'offline',
      'camera': cameraOnline ? 'online' : 'offline',
      'barrier': barrierOnline ? 'online' : 'offline',
      'printer': printerOnline ? 'online' : 'offline',
    });
  }

  /// Report device twin properties
  Future<bool> reportTwinProperties(Map<String, dynamic> properties) async {
    final topic = '\$iothub/twin/PATCH/properties/reported/?rid=${DateTime.now().millisecondsSinceEpoch}';
    return publishMessage(topic, jsonEncode(properties));
  }

  /// Generate SAS token for IoT Hub authentication
  /// Uses HMAC-SHA256 to sign the token properly for Azure IoT Hub
  String _generateSasToken(String hostname, String deviceId) {
    // Use the device key from Azure config
    final deviceKey = AzureConfig.iotDeviceKey;
    
    // Token expiry - 24 hours from now (in seconds since epoch)
    final expiry = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 86400;
    
    // Resource URI - must be URL encoded
    final resourceUri = Uri.encodeComponent('$hostname/devices/$deviceId');
    
    // String to sign: {resourceUri}\n{expiry}
    final stringToSign = '$resourceUri\n$expiry';
    
    // Decode the Base64 encoded device key
    final keyBytes = base64Decode(deviceKey);
    
    // Compute HMAC-SHA256 signature
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(stringToSign));
    
    // Base64 encode the signature and URL encode it
    final signature = Uri.encodeComponent(base64Encode(digest.bytes));
    
    // Return the complete SAS token
    return 'SharedAccessSignature sr=$resourceUri&sig=$signature&se=$expiry';
  }

  /// Connection callbacks
  void _onConnected() {
    debugPrint('MqttService: Connected');
    _isConnected = true;
    _reconnectAttempts = 0;
    _connectionController.add(MqttConnectionState.connected);
  }

  void _onDisconnected() {
    debugPrint('MqttService: Disconnected');
    _isConnected = false;
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void _onAutoReconnect() {
    debugPrint('MqttService: Auto-reconnecting...');
    _connectionController.add(MqttConnectionState.connecting);
  }

  void _onAutoReconnected() {
    debugPrint('MqttService: Auto-reconnected');
    _isConnected = true;
    _connectionController.add(MqttConnectionState.connected);
  }

  void _onSubscribed(String topic) {
    debugPrint('MqttService: Subscribed to $topic');
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('MqttService: Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('MqttService: Reconnect attempt $_reconnectAttempts');
      connect();
    });
  }

  /// Disconnect from IoT Hub
  void disconnect() {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _isConnected = false;
    debugPrint('MqttService: Disconnected manually');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}

/// MQTT Received Data model
class MqttReceivedData {
  final String topic;
  final String payload;
  final DateTime timestamp;

  MqttReceivedData({
    required this.topic,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic>? get payloadAsJson {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
