/// Trạng thái thiết bị
enum DeviceStatus {
  /// Đang kết nối
  connected('connected', 'Đã kết nối'),

  /// Mất kết nối
  disconnected('disconnected', 'Mất kết nối'),

  /// Đang kết nối
  connecting('connecting', 'Đang kết nối'),

  /// Lỗi
  error('error', 'Lỗi');

  final String value;
  final String displayName;

  const DeviceStatus(this.value, this.displayName);
}

/// Loại thiết bị
enum DeviceType {
  /// Đầu cân
  weighingIndicator('weighing_indicator', 'Đầu cân'),

  /// Camera giám sát
  camera('camera', 'Camera'),

  /// Barrier/Barie
  barrier('barrier', 'Barrier'),

  /// Máy đọc biển số (Vision Master)
  licensePlateReader('license_plate_reader', 'Đọc biển số'),

  /// Máy in
  printer('printer', 'Máy in'),

  /// Cảm biến
  sensor('sensor', 'Cảm biến');

  final String value;
  final String displayName;

  const DeviceType(this.value, this.displayName);
}

/// Trạng thái barrier
enum BarrierStatus {
  /// Đang mở
  open('open', 'Đang mở'),

  /// Đang đóng
  closed('closed', 'Đang đóng'),

  /// Đang di chuyển
  moving('moving', 'Đang di chuyển'),

  /// Lỗi
  error('error', 'Lỗi');

  final String value;
  final String displayName;

  const BarrierStatus(this.value, this.displayName);
}
