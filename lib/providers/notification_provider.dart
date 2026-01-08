import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:canoto/services/signalr/signalr_service.dart';
import 'package:canoto/services/mqtt/mqtt_service.dart';

/// Notification Provider - Manages app notifications and real-time updates
class NotificationProvider extends ChangeNotifier {
  // Services
  final SignalRService _signalRService = SignalRService.instance;
  final MqttService _mqttService = MqttService.instance;
  
  // Subscriptions
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _alertSubscription;
  StreamSubscription? _weighingUpdateSubscription;
  StreamSubscription? _signalRConnectionSubscription;
  StreamSubscription? _mqttConnectionSubscription;
  
  // State
  final List<AppNotification> _notifications = [];
  final List<AppNotification> _alerts = [];
  int _unreadCount = 0;
  bool _isSignalRConnected = false;
  bool _isMqttConnected = false;
  
  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get alerts => List.unmodifiable(_alerts);
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  bool get isSignalRConnected => _isSignalRConnected;
  bool get isMqttConnected => _isMqttConnected;
  bool get isConnected => _isSignalRConnected || _isMqttConnected;

  /// Initialize the provider
  Future<void> initialize() async {
    debugPrint('NotificationProvider: Initializing...');
    
    // Subscribe to SignalR events
    _subscribeToSignalR();
    
    // Subscribe to MQTT events
    _subscribeToMqtt();
    
    // Connect to services
    await _connectServices();
    
    debugPrint('NotificationProvider: Initialized');
  }

  /// Connect to notification services
  Future<void> _connectServices() async {
    // Connect SignalR
    try {
      await _signalRService.connect();
    } catch (e) {
      debugPrint('NotificationProvider: SignalR connection error: $e');
    }
    
    // Connect MQTT
    try {
      await _mqttService.connect();
    } catch (e) {
      debugPrint('NotificationProvider: MQTT connection error: $e');
    }
  }

  /// Subscribe to SignalR events
  void _subscribeToSignalR() {
    // Notifications
    _notificationSubscription = _signalRService.notificationStream.listen(
      (notification) {
        _addNotification(AppNotification(
          id: notification.id,
          title: notification.title,
          message: notification.body,
          type: _mapNotificationType(notification.type),
          timestamp: notification.timestamp,
          data: notification.data,
        ));
      },
    );
    
    // Alerts
    _alertSubscription = _signalRService.alertStream.listen(
      (alert) {
        _addAlert(AppNotification(
          id: alert.id,
          title: 'Cảnh báo',
          message: alert.message,
          type: AppNotificationType.warning,
          priority: _mapAlertPriority(alert.priority),
          timestamp: alert.timestamp,
          data: alert.data,
        ));
      },
    );
    
    // Weighing updates
    _weighingUpdateSubscription = _signalRService.weighingUpdateStream.listen(
      (update) {
        _addNotification(AppNotification(
          id: update.ticketNumber,
          title: 'Cập nhật phiếu cân',
          message: 'Phiếu ${update.ticketNumber}: ${update.eventType ?? "đã cập nhật"}',
          type: AppNotificationType.weighing,
          timestamp: update.timestamp,
          data: {
            'ticketNumber': update.ticketNumber,
            'licensePlate': update.licensePlate,
            'weight': update.weight,
            'isCompleted': update.isCompleted,
          },
        ));
      },
    );
    
    // Connection status
    _signalRConnectionSubscription = _signalRService.connectionStream.listen(
      (state) {
        _isSignalRConnected = state == SignalRConnectionState.connected;
        notifyListeners();
      },
    );
  }

  /// Subscribe to MQTT events
  void _subscribeToMqtt() {
    // MQTT messages
    _mqttService.messageStream.listen(
      (message) {
        final json = message.payloadAsJson;
        if (json != null) {
          final eventType = json['eventType'] as String?;
          
          if (eventType == 'notification') {
            _addNotification(AppNotification(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: json['title'] as String? ?? 'Thông báo',
              message: json['message'] as String? ?? '',
              type: AppNotificationType.info,
              timestamp: DateTime.now(),
              data: json,
            ));
          } else if (eventType == 'alert') {
            _addAlert(AppNotification(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Cảnh báo IoT',
              message: json['message'] as String? ?? '',
              type: AppNotificationType.warning,
              timestamp: DateTime.now(),
              data: json,
            ));
          }
        }
      },
    );
    
    // Connection status
    _mqttConnectionSubscription = _mqttService.connectionStream.listen(
      (state) {
        _isMqttConnected = state == MqttConnectionState.connected;
        notifyListeners();
      },
    );
  }

  /// Add notification
  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    
    // Limit to 100 notifications
    if (_notifications.length > 100) {
      _notifications.removeLast();
    }
    
    notifyListeners();
    debugPrint('NotificationProvider: Added notification: ${notification.title}');
  }

  /// Add alert
  void _addAlert(AppNotification alert) {
    _alerts.insert(0, alert);
    
    // Limit to 50 alerts
    if (_alerts.length > 50) {
      _alerts.removeLast();
    }
    
    notifyListeners();
    debugPrint('NotificationProvider: Added alert: ${alert.message}');
  }

  /// Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
    }
  }

  /// Mark all as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  /// Clear notification
  void clearNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Clear alert
  void clearAlert(String id) {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// Clear all alerts
  void clearAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  /// Add local notification (for in-app events)
  void addLocalNotification({
    required String title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Map<String, dynamic>? data,
  }) {
    _addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    ));
  }

  /// Add local alert
  void addLocalAlert({
    required String message,
    AppNotificationPriority priority = AppNotificationPriority.normal,
    Map<String, dynamic>? data,
  }) {
    _addAlert(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Cảnh báo',
      message: message,
      type: AppNotificationType.warning,
      priority: priority,
      timestamp: DateTime.now(),
      data: data,
    ));
  }

  /// Map notification type
  AppNotificationType _mapNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppNotificationType.success;
      case NotificationType.warning:
        return AppNotificationType.warning;
      case NotificationType.error:
        return AppNotificationType.error;
      case NotificationType.weighing:
        return AppNotificationType.weighing;
      case NotificationType.sync:
        return AppNotificationType.sync;
      case NotificationType.system:
        return AppNotificationType.system;
      default:
        return AppNotificationType.info;
    }
  }

  /// Map alert priority
  AppNotificationPriority _mapAlertPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.low:
        return AppNotificationPriority.low;
      case AlertPriority.high:
        return AppNotificationPriority.high;
      case AlertPriority.critical:
        return AppNotificationPriority.critical;
      default:
        return AppNotificationPriority.normal;
    }
  }

  /// Reconnect services
  Future<void> reconnect() async {
    await _signalRService.disconnect();
    _mqttService.disconnect();
    await _connectServices();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _alertSubscription?.cancel();
    _weighingUpdateSubscription?.cancel();
    _signalRConnectionSubscription?.cancel();
    _mqttConnectionSubscription?.cancel();
    super.dispose();
  }
}

/// App notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final AppNotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = AppNotificationPriority.normal,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    AppNotificationType? type,
    AppNotificationPriority? priority,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get icon for notification type
  IconData get icon {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_circle;
      case AppNotificationType.warning:
        return Icons.warning;
      case AppNotificationType.error:
        return Icons.error;
      case AppNotificationType.weighing:
        return Icons.scale;
      case AppNotificationType.sync:
        return Icons.sync;
      case AppNotificationType.system:
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  /// Get color for notification type
  Color get color {
    switch (type) {
      case AppNotificationType.success:
        return Colors.green;
      case AppNotificationType.warning:
        return Colors.orange;
      case AppNotificationType.error:
        return Colors.red;
      case AppNotificationType.weighing:
        return Colors.blue;
      case AppNotificationType.sync:
        return Colors.purple;
      case AppNotificationType.system:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

/// Notification types
enum AppNotificationType {
  info,
  success,
  warning,
  error,
  weighing,
  sync,
  system,
}

/// Notification priority
enum AppNotificationPriority {
  low,
  normal,
  high,
  critical,
}
