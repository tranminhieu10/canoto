import 'dart:async';

/// Abstract class cho dịch vụ đầu cân
abstract class ScaleService {
  /// Kết nối đến đầu cân
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected;

  /// Stream dữ liệu cân liên tục
  Stream<double> get weightStream;

  /// Đọc trọng lượng hiện tại
  Future<double> readWeight();

  /// Zero cân
  Future<bool> zero();

  /// Tare (cân bì)
  Future<bool> tare();

  /// Kiểm tra cân ổn định
  Future<bool> isStable();

  /// Dispose resources
  void dispose();
}
