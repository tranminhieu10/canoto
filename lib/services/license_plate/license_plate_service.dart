import 'dart:async';
import 'package:canoto/data/models/license_plate_result.dart';

/// Abstract class cho dịch vụ nhận diện biển số (Vision Master)
abstract class LicensePlateService {
  /// Kết nối đến Vision Master
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected;

  /// Stream kết quả nhận diện
  Stream<LicensePlateResult> get resultStream;

  /// Nhận diện biển số từ ảnh
  Future<LicensePlateResult?> recognizeFromImage(String imagePath);

  /// Nhận diện biển số từ bytes
  Future<LicensePlateResult?> recognizeFromBytes(List<int> imageBytes);

  /// Kích hoạt nhận diện (trigger)
  Future<LicensePlateResult?> trigger();

  /// Dispose resources
  void dispose();
}
