import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// Print Service - Quản lý in phiếu cân
class PrintService {
  // Singleton
  static PrintService? _instance;
  static PrintService get instance => _instance ??= PrintService._();
  PrintService._();

  // Thông tin công ty (sẽ được load từ settings)
  String _companyName = 'Công ty TNHH Nuôi trồng Thủy sản';
  String _companyAddress = '';
  String _companyPhone = '';
  Uint8List? _companyLogo;

  // Font - Reserved for future custom font support
  // ignore: unused_field
  pw.Font? _regularFont;
  // ignore: unused_field
  pw.Font? _boldFont;

  /// Khởi tạo service
  Future<void> initialize({
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    Uint8List? companyLogo,
  }) async {
    if (companyName != null) _companyName = companyName;
    if (companyAddress != null) _companyAddress = companyAddress;
    if (companyPhone != null) _companyPhone = companyPhone;
    if (companyLogo != null) _companyLogo = companyLogo;

    // Load fonts
    await _loadFonts();

    logger.info('PrintService', 'Print service initialized');
  }

  Future<void> _loadFonts() async {
    try {
      // Sử dụng font mặc định
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    } catch (e) {
      logger.error('PrintService', 'Failed to load fonts', error: e);
    }
  }

  /// Cập nhật thông tin công ty
  void updateCompanyInfo({
    String? name,
    String? address,
    String? phone,
    Uint8List? logo,
  }) {
    if (name != null) _companyName = name;
    if (address != null) _companyAddress = address;
    if (phone != null) _companyPhone = phone;
    if (logo != null) _companyLogo = logo;
  }

  /// Lấy danh sách máy in
  Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      logger.error('PrintService', 'Failed to list printers', error: e);
      return [];
    }
  }

  /// In phiếu cân
  Future<bool> printWeighingTicket(
    WeighingTicket ticket, {
    String? printerName,
    bool preview = false,
  }) async {
    try {
      logger.info('PrintService', 'Printing ticket: ${ticket.ticketNumber}');

      final pdf = await _generateTicketPdf(ticket);

      if (preview) {
        // Hiển thị preview (dùng trong Flutter widget)
        return true;
      }

      // In trực tiếp
      if (printerName != null && printerName.isNotEmpty) {
        final printers = await getAvailablePrinters();
        final printer = printers
            .where((p) => p.name == printerName)
            .firstOrNull;

        if (printer != null) {
          await Printing.directPrintPdf(
            printer: printer,
            onLayout: (_) async => pdf,
          );
          logger.info('PrintService', 'Printed to: $printerName');
          return true;
        }
      }

      // Mở dialog in
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'Phieu_can_${ticket.ticketNumber}',
      );

      return true;
    } catch (e) {
      logger.error('PrintService', 'Failed to print ticket', error: e);
      return false;
    }
  }

  /// Tạo PDF phiếu cân
  Future<Uint8List> _generateTicketPdf(WeighingTicket ticket) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Tiêu đề
              pw.Center(
                child: pw.Text(
                  'PHIẾU CÂN XE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Số: ${ticket.ticketNumber}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 15),

              // Thông tin xe
              _buildInfoRow('Biển số xe:', ticket.licensePlate),
              _buildInfoRow('Loại xe:', ticket.vehicleType ?? '-'),
              _buildInfoRow('Tài xế:', ticket.driverName ?? '-'),
              _buildInfoRow('Khách hàng:', ticket.customerName ?? '-'),
              _buildInfoRow('Sản phẩm:', ticket.productName ?? '-'),

              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Thông tin cân
              _buildWeightRow(
                'Cân lần 1:',
                ticket.firstWeight,
                ticket.firstWeightTime,
              ),
              _buildWeightRow(
                'Cân lần 2:',
                ticket.secondWeight,
                ticket.secondWeightTime,
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Trọng lượng hàng
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TRỌNG LƯỢNG HÀNG:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${_formatNumber(ticket.netWeight ?? 0)} kg',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Thành tiền (nếu có)
              if (ticket.totalAmount != null && ticket.totalAmount! > 0) ...[
                _buildInfoRow(
                  'Đơn giá:',
                  '${_formatNumber(ticket.unitPrice ?? 0)} đ/kg',
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'THÀNH TIỀN:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${_formatNumber(ticket.totalAmount!)} VNĐ',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Ghi chú
              if (ticket.note != null && ticket.note!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                _buildInfoRow('Ghi chú:', ticket.note!),
              ],

              pw.Spacer(),

              // Footer - Chữ ký
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBox('Người cân'),
                  _buildSignatureBox('Tài xế'),
                  _buildSignatureBox('Xác nhận'),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Ngày in: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo
        if (_companyLogo != null)
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(pw.MemoryImage(_companyLogo!)),
          )
        else
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Center(child: pw.Text('LOGO')),
          ),
        pw.SizedBox(width: 15),

        // Thông tin công ty
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (_companyAddress.isNotEmpty)
                pw.Text(
                  _companyAddress,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              if (_companyPhone.isNotEmpty)
                pw.Text(
                  'ĐT: $_companyPhone',
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeightRow(String label, double? weight, DateTime? time) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              weight != null ? '${_formatNumber(weight)} kg' : '-',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            time != null ? DateFormat('HH:mm dd/MM').format(time) : '-',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBox(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 30),
        pw.Container(width: 80, child: pw.Divider()),
      ],
    );
  }

  String _formatNumber(double value) {
    return NumberFormat('#,##0', 'vi_VN').format(value);
  }

  /// Lưu PDF ra file
  Future<String?> saveTicketPdf(WeighingTicket ticket) async {
    try {
      final pdf = await _generateTicketPdf(ticket);
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/canoto/tickets/${ticket.ticketNumber}.pdf',
      );

      await file.parent.create(recursive: true);
      await file.writeAsBytes(pdf);

      logger.info('PrintService', 'Saved PDF: ${file.path}');
      return file.path;
    } catch (e) {
      logger.error('PrintService', 'Failed to save PDF', error: e);
      return null;
    }
  }

  /// Chia sẻ PDF
  Future<void> shareTicketPdf(WeighingTicket ticket) async {
    try {
      final pdf = await _generateTicketPdf(ticket);
      await Printing.sharePdf(
        bytes: pdf,
        filename: 'Phieu_can_${ticket.ticketNumber}.pdf',
      );
    } catch (e) {
      logger.error('PrintService', 'Failed to share PDF', error: e);
    }
  }
}
