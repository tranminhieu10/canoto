import 'dart:async';
import 'dart:typed_data';

/// Abstract class cho dịch vụ Camera
abstract class CameraService {
  /// Kết nối camera
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected;

  /// Stream video frame
  Stream<Uint8List> get frameStream;

  /// Chụp ảnh
  Future<Uint8List?> captureImage();

  /// Lưu ảnh vào file
  Future<String?> saveImage(Uint8List imageData, String fileName);

  /// Bắt đầu ghi video
  Future<bool> startRecording(String filePath);

  /// Dừng ghi video
  Future<String?> stopRecording();

  /// Đang ghi video?
  bool get isRecording;

  /// Dispose resources
  void dispose();
}
