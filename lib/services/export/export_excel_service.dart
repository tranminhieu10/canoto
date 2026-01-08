import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// Service để xuất dữ liệu ra file Excel
class ExportExcelService {
  // Singleton
  static final ExportExcelService _instance = ExportExcelService._internal();
  static ExportExcelService get instance => _instance;
  ExportExcelService._internal();

  final LoggingService _logger = LoggingService.instance;

  /// Xuất danh sách phiếu cân ra file Excel
  /// Returns đường dẫn file đã xuất hoặc null nếu lỗi
  Future<String?> exportWeighingTickets({
    required List<WeighingTicket> tickets,
    String? fileName,
    String? sheetName,
    bool includeImages = false,
  }) async {
    try {
      _logger.info('ExportExcel', 'Exporting ${tickets.length} tickets to Excel...');

      final excel = Excel.createExcel();
      final sheet = excel[sheetName ?? 'Phiếu cân'];

      // Remove default sheet if exists
      if (excel.getDefaultSheet() != sheetName) {
        excel.delete('Sheet1');
      }

      // Create header row with styling
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue200,
        fontColorHex: ExcelColor.black,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'STT',
        'Số phiếu',
        'Biển số xe',
        'Loại xe',
        'Tên lái xe',
        'Khách hàng',
        'Sản phẩm',
        'Trọng lượng lần 1 (kg)',
        'Thời gian lần 1',
        'Trọng lượng lần 2 (kg)',
        'Thời gian lần 2',
        'Trọng lượng hàng (kg)',
        'Trừ hao (kg)',
        'Trọng lượng thực (kg)',
        'Đơn giá',
        'Thành tiền',
        'Loại cân',
        'Trạng thái',
        'Ghi chú',
        'Ngày tạo',
        'Đã đồng bộ',
      ];

      // Add headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Date formatters
      final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Add data rows
      for (var rowIndex = 0; rowIndex < tickets.length; rowIndex++) {
        final ticket = tickets[rowIndex];
        final row = rowIndex + 1;

        // STT
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(rowIndex + 1);

        // Số phiếu
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(ticket.ticketNumber);

        // Biển số xe
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(ticket.licensePlate);

        // Loại xe
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(ticket.vehicleType ?? '');

        // Tên lái xe
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(ticket.driverName ?? '');

        // Khách hàng
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(ticket.customerName ?? '');

        // Sản phẩm
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(ticket.productName ?? '');

        // Trọng lượng lần 1
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = DoubleCellValue(ticket.firstWeight ?? 0);

        // Thời gian lần 1
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = TextCellValue(
              ticket.firstWeightTime != null 
                ? dateTimeFormat.format(ticket.firstWeightTime!) 
                : ''
            );

        // Trọng lượng lần 2
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = DoubleCellValue(ticket.secondWeight ?? 0);

        // Thời gian lần 2
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = TextCellValue(
              ticket.secondWeightTime != null 
                ? dateTimeFormat.format(ticket.secondWeightTime!) 
                : ''
            );

        // Trọng lượng hàng
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
            .value = DoubleCellValue(ticket.netWeight ?? 0);

        // Trừ hao
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
            .value = DoubleCellValue(ticket.deduction ?? 0);

        // Trọng lượng thực
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
            .value = DoubleCellValue(ticket.actualWeight ?? 0);

        // Đơn giá
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
            .value = DoubleCellValue(ticket.unitPrice ?? 0);

        // Thành tiền
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row))
            .value = DoubleCellValue(ticket.totalAmount ?? 0);

        // Loại cân
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row))
            .value = TextCellValue(ticket.weighingType.displayName);

        // Trạng thái
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: row))
            .value = TextCellValue(ticket.status.displayName);

        // Ghi chú
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: row))
            .value = TextCellValue(ticket.note ?? '');

        // Ngày tạo
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: row))
            .value = TextCellValue(dateFormat.format(ticket.createdAt));

        // Đã đồng bộ
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: row))
            .value = TextCellValue(ticket.isSynced ? 'Có' : 'Chưa');
      }

      // Set column widths
      sheet.setColumnWidth(0, 5);   // STT
      sheet.setColumnWidth(1, 15);  // Số phiếu
      sheet.setColumnWidth(2, 12);  // Biển số
      sheet.setColumnWidth(3, 10);  // Loại xe
      sheet.setColumnWidth(4, 15);  // Tên lái xe
      sheet.setColumnWidth(5, 20);  // Khách hàng
      sheet.setColumnWidth(6, 15);  // Sản phẩm
      sheet.setColumnWidth(7, 18);  // TL lần 1
      sheet.setColumnWidth(8, 18);  // Thời gian 1
      sheet.setColumnWidth(9, 18);  // TL lần 2
      sheet.setColumnWidth(10, 18); // Thời gian 2
      sheet.setColumnWidth(11, 18); // TL hàng
      sheet.setColumnWidth(12, 12); // Trừ hao
      sheet.setColumnWidth(13, 18); // TL thực
      sheet.setColumnWidth(14, 12); // Đơn giá
      sheet.setColumnWidth(15, 15); // Thành tiền
      sheet.setColumnWidth(16, 10); // Loại cân
      sheet.setColumnWidth(17, 12); // Trạng thái
      sheet.setColumnWidth(18, 25); // Ghi chú
      sheet.setColumnWidth(19, 12); // Ngày tạo
      sheet.setColumnWidth(20, 10); // Đã đồng bộ

      // Generate file name
      final now = DateTime.now();
      final defaultFileName = 'PhieuCan_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
      final outputFileName = fileName ?? defaultFileName;

      // Get export directory
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/CanOTo/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final filePath = '${exportDir.path}/$outputFileName';

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        _logger.info('ExportExcel', 'Exported to: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      _logger.error('ExportExcel', 'Export failed', error: e);
      return null;
    }
  }

  /// Xuất báo cáo tổng hợp theo ngày
  Future<String?> exportDailyReport({
    required List<WeighingTicket> tickets,
    required DateTime date,
    String? companyName,
  }) async {
    try {
      _logger.info('ExportExcel', 'Exporting daily report for ${DateFormat('dd/MM/yyyy').format(date)}...');

      final excel = Excel.createExcel();
      final sheet = excel['Báo cáo ngày'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      final titleStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(companyName ?? 'CÔNG TY TNHH CÂN Ô TÔ');
      titleCell.cellStyle = titleStyle;

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'));
      final reportTitleCell = sheet.cell(CellIndex.indexByString('A2'));
      reportTitleCell.value = TextCellValue('BÁO CÁO CÂN XE NGÀY ${DateFormat('dd/MM/yyyy').format(date)}');
      reportTitleCell.cellStyle = titleStyle;

      // Summary section
      final incomingTickets = tickets.where((t) => t.weighingType.value == 'incoming').toList();
      final outgoingTickets = tickets.where((t) => t.weighingType.value == 'outgoing').toList();

      double totalIncomingWeight = 0;
      double totalOutgoingWeight = 0;
      double totalIncomingAmount = 0;
      double totalOutgoingAmount = 0;

      for (final t in incomingTickets) {
        totalIncomingWeight += t.netWeight ?? 0;
        totalIncomingAmount += t.totalAmount ?? 0;
      }

      for (final t in outgoingTickets) {
        totalOutgoingWeight += t.netWeight ?? 0;
        totalOutgoingAmount += t.totalAmount ?? 0;
      }

      // Summary headers
      final summaryStartRow = 4;
      final summaryHeaders = ['Loại', 'Số lượt', 'Tổng TL (kg)', 'Tổng tiền (VNĐ)'];
      for (var i = 0; i < summaryHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: summaryStartRow));
        cell.value = TextCellValue(summaryHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Incoming summary
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow + 1))
          .value = TextCellValue('Cân nhập');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryStartRow + 1))
          .value = IntCellValue(incomingTickets.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryStartRow + 1))
          .value = DoubleCellValue(totalIncomingWeight);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryStartRow + 1))
          .value = DoubleCellValue(totalIncomingAmount);

      // Outgoing summary
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow + 2))
          .value = TextCellValue('Cân xuất');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryStartRow + 2))
          .value = IntCellValue(outgoingTickets.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryStartRow + 2))
          .value = DoubleCellValue(totalOutgoingWeight);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryStartRow + 2))
          .value = DoubleCellValue(totalOutgoingAmount);

      // Total summary
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow + 3))
          .value = TextCellValue('TỔNG CỘNG');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow + 3))
          .cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryStartRow + 3))
          .value = IntCellValue(tickets.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryStartRow + 3))
          .value = DoubleCellValue(totalIncomingWeight + totalOutgoingWeight);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryStartRow + 3))
          .value = DoubleCellValue(totalIncomingAmount + totalOutgoingAmount);

      // Detail section
      final detailStartRow = summaryStartRow + 6;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: detailStartRow - 1),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: detailStartRow - 1),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: detailStartRow - 1))
          .value = TextCellValue('CHI TIẾT PHIẾU CÂN');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: detailStartRow - 1))
          .cellStyle = headerStyle;

      // Detail headers
      final detailHeaders = ['STT', 'Số phiếu', 'Biển số', 'TL hàng (kg)', 'Thành tiền', 'Loại'];
      for (var i = 0; i < detailHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: detailStartRow));
        cell.value = TextCellValue(detailHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Detail data
      for (var i = 0; i < tickets.length; i++) {
        final ticket = tickets[i];
        final row = detailStartRow + 1 + i;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(ticket.ticketNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(ticket.licensePlate);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(ticket.netWeight ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = DoubleCellValue(ticket.totalAmount ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(ticket.weighingType.displayName);
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 15);
      sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 15);
      sheet.setColumnWidth(5, 12);

      // Generate file name
      final outputFileName = 'BaoCao_${DateFormat('yyyyMMdd').format(date)}.xlsx';

      // Get export directory
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/CanOTo/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final filePath = '${exportDir.path}/$outputFileName';

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        _logger.info('ExportExcel', 'Daily report exported to: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      _logger.error('ExportExcel', 'Daily report export failed', error: e);
      return null;
    }
  }

  /// Xuất báo cáo tổng hợp theo tháng
  Future<String?> exportMonthlyReport({
    required List<WeighingTicket> tickets,
    required int year,
    required int month,
    String? companyName,
  }) async {
    try {
      _logger.info('ExportExcel', 'Exporting monthly report for $month/$year...');

      final excel = Excel.createExcel();
      final sheet = excel['Báo cáo tháng'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      final titleStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(companyName ?? 'CÔNG TY TNHH CÂN Ô TÔ');
      titleCell.cellStyle = titleStyle;

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('H2'));
      final reportTitleCell = sheet.cell(CellIndex.indexByString('A2'));
      reportTitleCell.value = TextCellValue('BÁO CÁO CÂN XE THÁNG $month/$year');
      reportTitleCell.cellStyle = titleStyle;

      // Group by day
      final Map<int, List<WeighingTicket>> ticketsByDay = {};
      for (final ticket in tickets) {
        final day = ticket.createdAt.day;
        ticketsByDay.putIfAbsent(day, () => []).add(ticket);
      }

      // Summary by day
      final summaryStartRow = 4;
      final summaryHeaders = ['Ngày', 'Số lượt nhập', 'TL nhập (kg)', 'Số lượt xuất', 'TL xuất (kg)', 'Tổng TL (kg)', 'Tổng tiền'];
      for (var i = 0; i < summaryHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: summaryStartRow));
        cell.value = TextCellValue(summaryHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      var currentRow = summaryStartRow + 1;
      double grandTotalWeight = 0;
      double grandTotalAmount = 0;
      int grandTotalIncoming = 0;
      int grandTotalOutgoing = 0;

      final sortedDays = ticketsByDay.keys.toList()..sort();
      for (final day in sortedDays) {
        final dayTickets = ticketsByDay[day]!;
        final incoming = dayTickets.where((t) => t.weighingType.value == 'incoming').toList();
        final outgoing = dayTickets.where((t) => t.weighingType.value == 'outgoing').toList();

        double inWeight = 0;
        double outWeight = 0;
        double totalAmount = 0;

        for (final t in incoming) {
          inWeight += t.netWeight ?? 0;
          totalAmount += t.totalAmount ?? 0;
        }
        for (final t in outgoing) {
          outWeight += t.netWeight ?? 0;
          totalAmount += t.totalAmount ?? 0;
        }

        grandTotalWeight += inWeight + outWeight;
        grandTotalAmount += totalAmount;
        grandTotalIncoming += incoming.length;
        grandTotalOutgoing += outgoing.length;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = TextCellValue('$day/$month');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
            .value = IntCellValue(incoming.length);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
            .value = DoubleCellValue(inWeight);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
            .value = IntCellValue(outgoing.length);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
            .value = DoubleCellValue(outWeight);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
            .value = DoubleCellValue(inWeight + outWeight);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
            .value = DoubleCellValue(totalAmount);

        currentRow++;
      }

      // Grand total row
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = TextCellValue('TỔNG CỘNG');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = IntCellValue(grandTotalIncoming);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
          .value = IntCellValue(grandTotalOutgoing);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
          .value = DoubleCellValue(grandTotalWeight);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
          .value = DoubleCellValue(grandTotalAmount);

      // Set column widths
      for (var i = 0; i < 7; i++) {
        sheet.setColumnWidth(i, 15);
      }

      // Generate file name
      final outputFileName = 'BaoCaoThang_${year}_${month.toString().padLeft(2, '0')}.xlsx';

      // Get export directory
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/CanOTo/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final filePath = '${exportDir.path}/$outputFileName';

      // Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        _logger.info('ExportExcel', 'Monthly report exported to: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      _logger.error('ExportExcel', 'Monthly report export failed', error: e);
      return null;
    }
  }

  /// Mở thư mục chứa file export
  Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/CanOTo/Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }
}
