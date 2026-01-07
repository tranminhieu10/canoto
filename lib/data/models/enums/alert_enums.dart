/// Loại cảnh báo
enum AlertType {
  /// Cảnh báo cân
  weight('weight', 'Cảnh báo cân'),

  /// Cảnh báo thiết bị
  device('device', 'Cảnh báo thiết bị'),

  /// Cảnh báo bảo mật
  security('security', 'Cảnh báo bảo mật'),

  /// Cảnh báo hệ thống
  system('system', 'Cảnh báo hệ thống'),

  /// Cảnh báo khác
  other('other', 'Cảnh báo khác');

  final String value;
  final String displayName;

  const AlertType(this.value, this.displayName);
}

/// Mức độ cảnh báo
enum AlertSeverity {
  /// Thông tin
  info('info', 'Thông tin'),

  /// Cảnh báo
  warning('warning', 'Cảnh báo'),

  /// Nghiêm trọng
  error('error', 'Lỗi'),

  /// Khẩn cấp
  critical('critical', 'Khẩn cấp');

  final String value;
  final String displayName;

  const AlertSeverity(this.value, this.displayName);
}
