import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:canoto/core/constants/azure_config.dart';

/// SignalR Service for real-time notifications
/// Receives push notifications from Azure SignalR Service
class SignalRService {
  // Singleton pattern
  static SignalRService? _instance;
  static SignalRService get instance => _instance ??= SignalRService._();
  SignalRService._();

  HubConnection? _hubConnection;
  
  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  Timer? _reconnectTimer;
  
  // Notification streams
  final StreamController<NotificationMessage> _notificationController = 
      StreamController<NotificationMessage>.broadcast();
  Stream<NotificationMessage> get notificationStream => _notificationController.stream;
  
  // Weighing update streams
  final StreamController<WeighingUpdate> _weighingUpdateController = 
      StreamController<WeighingUpdate>.broadcast();
  Stream<WeighingUpdate> get weighingUpdateStream => _weighingUpdateController.stream;
  
  // Alert streams
  final StreamController<AlertMessage> _alertController = 
      StreamController<AlertMessage>.broadcast();
  Stream<AlertMessage> get alertStream => _alertController.stream;
  
  // Connection status stream
  final StreamController<SignalRConnectionState> _connectionController = 
      StreamController<SignalRConnectionState>.broadcast();
  Stream<SignalRConnectionState> get connectionStream => _connectionController.stream;

  /// Initialize and connect to SignalR Hub
  Future<bool> connect({String? hubUrl, String? accessToken}) async {
    final url = hubUrl ?? AzureConfig.signalRHubUrl;
    
    try {
      debugPrint('SignalRService: Connecting to $url...');
      _connectionController.add(SignalRConnectionState.connecting);
      
      // Build hub connection
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              accessTokenFactory: accessToken != null 
                  ? () async => accessToken 
                  : null,
              logging: (level, message) {
                if (AzureConfig.isDevelopment) {
                  debugPrint('SignalR: $message');
                }
              },
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [2000, 5000, 10000, 30000],
          )
          .build();

      // Register event handlers
      _registerHandlers();
      
      // Set up connection callbacks
      _hubConnection!.onclose(({error}) {
        debugPrint('SignalRService: Connection closed: $error');
        _isConnected = false;
        _connectionController.add(SignalRConnectionState.disconnected);
        _scheduleReconnect();
      });
      
      _hubConnection!.onreconnecting(({error}) {
        debugPrint('SignalRService: Reconnecting: $error');
        _connectionController.add(SignalRConnectionState.reconnecting);
      });
      
      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('SignalRService: Reconnected: $connectionId');
        _isConnected = true;
        _reconnectAttempts = 0;
        _connectionController.add(SignalRConnectionState.connected);
      });

      // Start connection
      await _hubConnection!.start();
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(SignalRConnectionState.connected);
      debugPrint('SignalRService: Connected successfully');
      
      // Register device with hub
      await _registerDevice();
      
      return true;
    } catch (e) {
      debugPrint('SignalRService: Connection error: $e');
      _connectionController.add(SignalRConnectionState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// Register event handlers for hub methods
  void _registerHandlers() {
    if (_hubConnection == null) return;
    
    // General notifications
    _hubConnection!.on('ReceiveNotification', _handleNotification);
    
    // Weighing updates
    _hubConnection!.on('WeighingUpdated', _handleWeighingUpdate);
    _hubConnection!.on('WeighingCompleted', _handleWeighingCompleted);
    
    // Alerts
    _hubConnection!.on('ReceiveAlert', _handleAlert);
    _hubConnection!.on('EmergencyAlert', _handleEmergencyAlert);
    
    // Device commands
    _hubConnection!.on('DeviceCommand', _handleDeviceCommand);
    
    // Sync notifications
    _hubConnection!.on('SyncRequired', _handleSyncRequired);
    _hubConnection!.on('DataUpdated', _handleDataUpdated);
    
    // System messages
    _hubConnection!.on('SystemMessage', _handleSystemMessage);
  }

  /// Handle general notification
  void _handleNotification(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final notification = NotificationMessage.fromJson(data);
      _notificationController.add(notification);
      debugPrint('SignalRService: Notification received: ${notification.title}');
    } catch (e) {
      debugPrint('SignalRService: Error parsing notification: $e');
    }
  }

  /// Handle weighing update
  void _handleWeighingUpdate(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final update = WeighingUpdate.fromJson(data);
      _weighingUpdateController.add(update);
      debugPrint('SignalRService: Weighing update: ${update.ticketNumber}');
    } catch (e) {
      debugPrint('SignalRService: Error parsing weighing update: $e');
    }
  }

  /// Handle weighing completed
  void _handleWeighingCompleted(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final update = WeighingUpdate.fromJson(data);
      update.isCompleted = true;
      _weighingUpdateController.add(update);
      debugPrint('SignalRService: Weighing completed: ${update.ticketNumber}');
    } catch (e) {
      debugPrint('SignalRService: Error parsing weighing completed: $e');
    }
  }

  /// Handle alert
  void _handleAlert(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final alert = AlertMessage.fromJson(data);
      _alertController.add(alert);
      debugPrint('SignalRService: Alert received: ${alert.message}');
    } catch (e) {
      debugPrint('SignalRService: Error parsing alert: $e');
    }
  }

  /// Handle emergency alert
  void _handleEmergencyAlert(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final alert = AlertMessage.fromJson(data);
      alert.priority = AlertPriority.critical;
      _alertController.add(alert);
      debugPrint('SignalRService: EMERGENCY Alert: ${alert.message}');
    } catch (e) {
      debugPrint('SignalRService: Error parsing emergency alert: $e');
    }
  }

  /// Handle device command
  void _handleDeviceCommand(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final command = data['command'] as String?;
      final parameters = data['parameters'] as Map<String, dynamic>?;
      
      debugPrint('SignalRService: Device command: $command');
      
      // Handle specific commands
      switch (command) {
        case 'openBarrier':
          // Trigger barrier open
          break;
        case 'closeBarrier':
          // Trigger barrier close
          break;
        case 'captureImage':
          // Trigger camera capture
          break;
        case 'printTicket':
          // Trigger print
          break;
        case 'refreshData':
          // Trigger data refresh
          break;
      }
    } catch (e) {
      debugPrint('SignalRService: Error parsing device command: $e');
    }
  }

  /// Handle sync required notification
  void _handleSyncRequired(List<Object?>? args) {
    debugPrint('SignalRService: Sync required notification received');
    // Trigger sync service
  }

  /// Handle data updated notification
  void _handleDataUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final data = args[0] as Map<String, dynamic>;
      final dataType = data['type'] as String?;
      debugPrint('SignalRService: Data updated: $dataType');
      // Refresh specific data type
    } catch (e) {
      debugPrint('SignalRService: Error parsing data updated: $e');
    }
  }

  /// Handle system message
  void _handleSystemMessage(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    
    try {
      final message = args[0] as String?;
      debugPrint('SignalRService: System message: $message');
      
      _notificationController.add(NotificationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Thông báo hệ thống',
        body: message ?? '',
        type: NotificationType.system,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('SignalRService: Error parsing system message: $e');
    }
  }

  /// Register this device with the hub
  Future<void> _registerDevice() async {
    if (_hubConnection == null || !_isConnected) return;
    
    try {
      await _hubConnection!.invoke('RegisterDevice', args: [
        AzureConfig.iotDeviceId,
        {
          'deviceType': 'weighing-station',
          'version': '1.0.0',
          'registeredAt': DateTime.now().toIso8601String(),
        },
      ]);
      debugPrint('SignalRService: Device registered');
    } catch (e) {
      debugPrint('SignalRService: Error registering device: $e');
    }
  }

  /// Send message to hub
  Future<void> sendMessage(String method, List<Object?> args) async {
    if (_hubConnection == null || !_isConnected) {
      debugPrint('SignalRService: Not connected, cannot send message');
      return;
    }
    
    try {
      await _hubConnection!.invoke(method, args: args);
      debugPrint('SignalRService: Message sent: $method');
    } catch (e) {
      debugPrint('SignalRService: Error sending message: $e');
    }
  }

  /// Notify weighing event
  Future<void> notifyWeighingEvent({
    required String ticketNumber,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    await sendMessage('WeighingEvent', [
      {
        'ticketNumber': ticketNumber,
        'eventType': eventType,
        'deviceId': AzureConfig.iotDeviceId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    ]);
  }

  /// Request sync
  Future<void> requestSync() async {
    await sendMessage('RequestSync', [AzureConfig.iotDeviceId]);
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('SignalRService: Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: 5 * (_reconnectAttempts + 1));
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      debugPrint('SignalRService: Reconnect attempt $_reconnectAttempts');
      connect();
    });
  }

  /// Disconnect from hub
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _hubConnection?.stop();
    _isConnected = false;
    debugPrint('SignalRService: Disconnected');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _weighingUpdateController.close();
    _alertController.close();
    _connectionController.close();
  }
}

/// SignalR connection states
enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Notification message model
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Notification types
enum NotificationType {
  info,
  success,
  warning,
  error,
  system,
  weighing,
  sync,
}

/// Weighing update model
class WeighingUpdate {
  final String ticketNumber;
  final String? licensePlate;
  final double? weight;
  final String? eventType;
  final DateTime timestamp;
  bool isCompleted;

  WeighingUpdate({
    required this.ticketNumber,
    this.licensePlate,
    this.weight,
    this.eventType,
    required this.timestamp,
    this.isCompleted = false,
  });

  factory WeighingUpdate.fromJson(Map<String, dynamic> json) {
    return WeighingUpdate(
      ticketNumber: json['ticketNumber'] as String? ?? '',
      licensePlate: json['licensePlate'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      eventType: json['eventType'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// Alert message model
class AlertMessage {
  final String id;
  final String message;
  final String? source;
  AlertPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  AlertMessage({
    required this.id,
    required this.message,
    this.source,
    this.priority = AlertPriority.normal,
    required this.timestamp,
    this.data,
  });

  factory AlertMessage.fromJson(Map<String, dynamic> json) {
    return AlertMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      message: json['message'] as String? ?? '',
      source: json['source'] as String?,
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => AlertPriority.normal,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Alert priority levels
enum AlertPriority {
  low,
  normal,
  high,
  critical,
}
