import 'dart:async';
import 'dart:typed_data';

/// Abstract class cho dịch vụ máy in
abstract class PrinterService {
  /// Kết nối máy in
  Future<bool> connect();

  /// Ngắt kết nối
  Future<void> disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected;

  /// Kiểm tra máy in sẵn sàng
  Future<bool> isReady();

  /// In văn bản
  Future<bool> printText(String text);

  /// In phiếu cân
  Future<bool> printTicket(Map<String, dynamic> ticketData);

  /// In ảnh
  Future<bool> printImage(Uint8List imageData);

  /// In PDF
  Future<bool> printPdf(String pdfPath);

  /// Lấy danh sách máy in
  Future<List<String>> getAvailablePrinters();

  /// Dispose resources
  void dispose();
}
