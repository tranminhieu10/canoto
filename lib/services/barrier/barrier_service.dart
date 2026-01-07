import 'dart:async';
import 'package:canoto/data/models/enums/device_enums.dart';

/// Abstract class cho dịch vụ Barrier
abstract class BarrierService {
  /// Kết nối barrier
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected;

  /// Stream trạng thái barrier
  Stream<BarrierStatus> get statusStream;

  /// Trạng thái hiện tại
  BarrierStatus get currentStatus;

  /// Mở barrier
  Future<bool> open();

  /// Đóng barrier
  Future<bool> close();

  /// Mở tạm thời (tự đóng sau thời gian)
  Future<bool> openTemporary({Duration duration = const Duration(seconds: 5)});

  /// Dừng barrier (emergency)
  Future<bool> stop();

  /// Dispose resources
  void dispose();
}
