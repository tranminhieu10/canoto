import 'dart:async';
import 'package:canoto/data/models/alert.dart';
import 'package:canoto/data/models/enums/alert_enums.dart';

/// Dịch vụ quản lý và gửi cảnh báo
class AlertService {
  final StreamController<Alert> _alertController =
      StreamController<Alert>.broadcast();
  final List<Alert> _alertHistory = [];

  /// Stream cảnh báo
  Stream<Alert> get alertStream => _alertController.stream;

  /// Lịch sử cảnh báo
  List<Alert> get alertHistory => List.unmodifiable(_alertHistory);

  /// Số cảnh báo chưa đọc
  int get unreadCount => _alertHistory.where((a) => !a.isRead).length;

  /// Gửi cảnh báo
  void sendAlert({
    required String title,
    required String message,
    required AlertType type,
    AlertSeverity severity = AlertSeverity.info,
    String? source,
  }) {
    final alert = Alert(
      title: title,
      message: message,
      type: type,
      severity: severity,
      source: source,
    );
    _alertHistory.add(alert);
    _alertController.add(alert);

    // TODO: Gửi thông báo qua các kênh khác
    // - Email
    // - SMS
    // - Push notification
    // - Telegram/Zalo
  }

  /// Cảnh báo thiết bị
  void deviceAlert(String deviceName, String message, {AlertSeverity severity = AlertSeverity.warning}) {
    sendAlert(
      title: 'Cảnh báo thiết bị: $deviceName',
      message: message,
      type: AlertType.device,
      severity: severity,
      source: deviceName,
    );
  }

  /// Cảnh báo cân
  void weightAlert(String message, {AlertSeverity severity = AlertSeverity.warning}) {
    sendAlert(
      title: 'Cảnh báo cân',
      message: message,
      type: AlertType.weight,
      severity: severity,
    );
  }

  /// Cảnh báo bảo mật
  void securityAlert(String message, {AlertSeverity severity = AlertSeverity.error}) {
    sendAlert(
      title: 'Cảnh báo bảo mật',
      message: message,
      type: AlertType.security,
      severity: severity,
    );
  }

  /// Đánh dấu đã đọc
  void markAsRead(int alertId) {
    final index = _alertHistory.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alertHistory[index] = _alertHistory[index].copyWith(isRead: true);
    }
  }

  /// Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    for (var i = 0; i < _alertHistory.length; i++) {
      _alertHistory[i] = _alertHistory[i].copyWith(isRead: true);
    }
  }

  /// Xóa cảnh báo
  void clearAlerts() {
    _alertHistory.clear();
  }

  void dispose() {
    _alertController.close();
  }
}
