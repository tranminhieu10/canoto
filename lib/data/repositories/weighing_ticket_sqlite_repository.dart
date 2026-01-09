import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/models/enums/weighing_enums.dart';
import 'package:canoto/data/repositories/weighing_ticket_repository.dart';
import 'package:canoto/services/database/database_service.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// SQLite implementation của WeighingTicketRepository
class WeighingTicketSqliteRepository implements WeighingTicketRepository {
  // Singleton
  static WeighingTicketSqliteRepository? _instance;
  static WeighingTicketSqliteRepository get instance =>
      _instance ??= WeighingTicketSqliteRepository._();
  WeighingTicketSqliteRepository._();

  final LoggingService _logger = LoggingService.instance;

  Database get _db => DatabaseService.instance.database;

  static const String _tableName = 'weighing_tickets';

  /// Convert WeighingTicket to Map for database
  Map<String, dynamic> _toMap(WeighingTicket ticket) {
    return {
      if (ticket.id != null) 'id': ticket.id,
      'ticket_number': ticket.ticketNumber,
      'license_plate': ticket.licensePlate,
      'vehicle_type': ticket.vehicleType,
      'driver_name': ticket.driverName,
      'driver_phone': ticket.driverPhone,
      'customer_id': ticket.customerId,
      'customer_name': ticket.customerName,
      'product_id': ticket.productId,
      'product_name': ticket.productName,
      'first_weight': ticket.firstWeight,
      'first_weight_time': ticket.firstWeightTime?.toIso8601String(),
      'second_weight': ticket.secondWeight,
      'second_weight_time': ticket.secondWeightTime?.toIso8601String(),
      'net_weight': ticket.netWeight,
      'deduction': ticket.deduction,
      'actual_weight': ticket.actualWeight,
      'unit_price': ticket.unitPrice,
      'total_amount': ticket.totalAmount,
      'weighing_type': ticket.weighingType.value,
      'status': ticket.status.value,
      'note': ticket.note,
      'first_weight_image': ticket.firstWeightImage,
      'second_weight_image': ticket.secondWeightImage,
      'license_plate_image': ticket.licensePlateImage,
      'scale_id': ticket.scaleId,
      'operator_id': ticket.operatorId,
      'operator_name': ticket.operatorName,
      'created_at': ticket.createdAt.toIso8601String(),
      'updated_at': ticket.updatedAt.toIso8601String(),
      'is_synced': ticket.isSynced ? 1 : 0,
      'azure_id': ticket.azureId,
      'synced_at': ticket.syncedAt?.toIso8601String(),
    };
  }

  /// Convert Map from database to WeighingTicket
  WeighingTicket _fromMap(Map<String, dynamic> map) {
    return WeighingTicket(
      id: map['id'] as int?,
      ticketNumber: map['ticket_number'] as String,
      licensePlate: map['license_plate'] as String,
      vehicleType: map['vehicle_type'] as String?,
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String?,
      firstWeight: map['first_weight'] as double?,
      firstWeightTime: map['first_weight_time'] != null
          ? DateTime.parse(map['first_weight_time'] as String)
          : null,
      secondWeight: map['second_weight'] as double?,
      secondWeightTime: map['second_weight_time'] != null
          ? DateTime.parse(map['second_weight_time'] as String)
          : null,
      netWeight: map['net_weight'] as double?,
      deduction: map['deduction'] as double?,
      actualWeight: map['actual_weight'] as double?,
      unitPrice: map['unit_price'] as double?,
      totalAmount: map['total_amount'] as double?,
      weighingType: WeighingType.fromValue(map['weighing_type'] as String? ?? 'incoming'),
      status: WeighingStatus.fromValue(map['status'] as String? ?? 'pending'),
      note: map['note'] as String?,
      firstWeightImage: map['first_weight_image'] as String?,
      secondWeightImage: map['second_weight_image'] as String?,
      licensePlateImage: map['license_plate_image'] as String?,
      scaleId: map['scale_id'] as int?,
      operatorId: map['operator_id'] as String?,
      operatorName: map['operator_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
      azureId: map['azure_id'] as int?,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
    );
  }

  @override
  Future<List<WeighingTicket>> getAll() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get all tickets', error: e);
      return [];
    }
  }

  @override
  Future<WeighingTicket?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return _fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get ticket by id', error: e);
      return null;
    }
  }

  @override
  Future<WeighingTicket?> getByTicketNumber(String ticketNumber) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'ticket_number = ?',
        whereArgs: [ticketNumber],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return _fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get ticket by number', error: e);
      return null;
    }
  }

  @override
  Future<List<WeighingTicket>> getByLicensePlate(String licensePlate) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'license_plate LIKE ?',
        whereArgs: ['%$licensePlate%'],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get tickets by plate', error: e);
      return [];
    }
  }

  @override
  Future<List<WeighingTicket>> getByDateRange(DateTime from, DateTime to) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [from.toIso8601String(), to.toIso8601String()],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get tickets by date range', error: e);
      return [];
    }
  }

  @override
  Future<List<WeighingTicket>> getByStatus(String status) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get tickets by status', error: e);
      return [];
    }
  }

  @override
  Future<int> insert(WeighingTicket ticket) async {
    try {
      final id = await _db.insert(_tableName, _toMap(ticket));
      _logger.info('WeighingRepo', 'Inserted ticket: ${ticket.ticketNumber}, id: $id');
      return id;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to insert ticket', error: e);
      return -1;
    }
  }

  @override
  Future<int> update(WeighingTicket ticket) async {
    try {
      final updatedTicket = ticket.copyWith(updatedAt: DateTime.now());
      final count = await _db.update(
        _tableName,
        _toMap(updatedTicket),
        where: 'id = ?',
        whereArgs: [ticket.id],
      );
      _logger.info('WeighingRepo', 'Updated ticket: ${ticket.ticketNumber}');
      return count;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to update ticket', error: e);
      return 0;
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final count = await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('WeighingRepo', 'Deleted ticket id: $id');
      return count;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to delete ticket', error: e);
      return 0;
    }
  }

  @override
  Future<String> generateTicketNumber() async {
    final now = DateTime.now();
    final todayCount = await countToday();
    final sequence = (todayCount + 1).toString().padLeft(4, '0');
    return 'PC${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$sequence';
  }

  @override
  Future<int> countToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE created_at >= ?',
        [startOfDay.toIso8601String()],
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to count today tickets', error: e);
      return 0;
    }
  }

  @override
  Future<double> totalWeightToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final result = await _db.rawQuery(
        'SELECT SUM(net_weight) as total FROM $_tableName WHERE created_at >= ?',
        [startOfDay.toIso8601String()],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get total weight today', error: e);
      return 0.0;
    }
  }

  // ============ SYNC METHODS ============

  @override
  Future<List<WeighingTicket>> getUnsynced() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'is_synced = 0',
        orderBy: 'created_at ASC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get unsynced tickets', error: e);
      return [];
    }
  }

  /// Get unsynced completed tickets only (for sync)
  /// Only sync completed tickets within the last N days
  Future<List<WeighingTicket>> getUnsyncedCompleted({int days = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: "is_synced = 0 AND status = 'completed' AND created_at >= ?",
        whereArgs: [cutoffDate.toIso8601String()],
        orderBy: 'created_at ASC',
      );
      _logger.info('WeighingRepo', 'Found ${maps.length} unsynced completed tickets in last $days days');
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get unsynced completed tickets', error: e);
      return [];
    }
  }

  /// Count unsynced completed tickets
  Future<int> countUnsyncedCompleted({int days = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final result = await _db.rawQuery(
        "SELECT COUNT(*) as count FROM $_tableName WHERE is_synced = 0 AND status = 'completed' AND created_at >= ?",
        [cutoffDate.toIso8601String()],
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> countUnsynced() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE is_synced = 0',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> countSynced() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE is_synced = 1',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get total ticket count
  Future<int> getTicketCount() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> markAsSynced(List<int> localIds, List<int?>? azureIds) async {
    if (localIds.isEmpty) return;

    try {
      await _db.transaction((txn) async {
        for (var i = 0; i < localIds.length; i++) {
          final localId = localIds[i];
          final azureId = azureIds != null && i < azureIds.length ? azureIds[i] : null;
          
          await txn.update(
            _tableName,
            {
              'is_synced': 1,
              'azure_id': azureId,
              'synced_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      });
      _logger.info('WeighingRepo', 'Marked ${localIds.length} tickets as synced');
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to mark tickets as synced', error: e);
    }
  }

  @override
  Future<void> markOneSynced(int localId, int? azureId) async {
    await markAsSynced([localId], azureId != null ? [azureId] : null);
  }

  @override
  Future<List<WeighingTicket>> getLast30Days() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'created_at >= ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get last 30 days tickets', error: e);
      return [];
    }
  }

  // ============ ADDITIONAL QUERY METHODS ============

  /// Tìm kiếm phiếu cân theo nhiều tiêu chí
  Future<List<WeighingTicket>> search({
    String? keyword,
    String? licensePlate,
    String? customerName,
    String? productName,
    DateTime? fromDate,
    DateTime? toDate,
    WeighingType? weighingType,
    WeighingStatus? status,
    bool? isSynced,
    int? limit,
    int? offset,
  }) async {
    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (keyword != null && keyword.isNotEmpty) {
        whereClauses.add(
          '(ticket_number LIKE ? OR license_plate LIKE ? OR customer_name LIKE ? OR product_name LIKE ?)'
        );
        final keywordPattern = '%$keyword%';
        whereArgs.addAll([keywordPattern, keywordPattern, keywordPattern, keywordPattern]);
      }

      if (licensePlate != null && licensePlate.isNotEmpty) {
        whereClauses.add('license_plate LIKE ?');
        whereArgs.add('%$licensePlate%');
      }

      if (customerName != null && customerName.isNotEmpty) {
        whereClauses.add('customer_name LIKE ?');
        whereArgs.add('%$customerName%');
      }

      if (productName != null && productName.isNotEmpty) {
        whereClauses.add('product_name LIKE ?');
        whereArgs.add('%$productName%');
      }

      if (fromDate != null) {
        whereClauses.add('created_at >= ?');
        whereArgs.add(fromDate.toIso8601String());
      }

      if (toDate != null) {
        whereClauses.add('created_at <= ?');
        whereArgs.add(toDate.toIso8601String());
      }

      if (weighingType != null) {
        whereClauses.add('weighing_type = ?');
        whereArgs.add(weighingType.value);
      }

      if (status != null) {
        whereClauses.add('status = ?');
        whereArgs.add(status.value);
      }

      if (isSynced != null) {
        whereClauses.add('is_synced = ?');
        whereArgs.add(isSynced ? 1 : 0);
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => _fromMap(map)).toList();
    } catch (e) {
      _logger.error('WeighingRepo', 'Search failed', error: e);
      return [];
    }
  }

  /// Lấy thống kê theo ngày
  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(CASE WHEN weighing_type = 'incoming' THEN 1 ELSE 0 END) as incoming_count,
          SUM(CASE WHEN weighing_type = 'outgoing' THEN 1 ELSE 0 END) as outgoing_count,
          SUM(CASE WHEN weighing_type = 'incoming' THEN net_weight ELSE 0 END) as incoming_weight,
          SUM(CASE WHEN weighing_type = 'outgoing' THEN net_weight ELSE 0 END) as outgoing_weight,
          SUM(net_weight) as total_weight,
          SUM(total_amount) as total_amount
        FROM $_tableName
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      return result.first;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get daily stats', error: e);
      return {};
    }
  }

  /// Lấy thống kê theo tháng
  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final result = await _db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(CASE WHEN weighing_type = 'incoming' THEN 1 ELSE 0 END) as incoming_count,
          SUM(CASE WHEN weighing_type = 'outgoing' THEN 1 ELSE 0 END) as outgoing_count,
          SUM(CASE WHEN weighing_type = 'incoming' THEN net_weight ELSE 0 END) as incoming_weight,
          SUM(CASE WHEN weighing_type = 'outgoing' THEN net_weight ELSE 0 END) as outgoing_weight,
          SUM(net_weight) as total_weight,
          SUM(total_amount) as total_amount
        FROM $_tableName
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      return result.first;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to get monthly stats', error: e);
      return {};
    }
  }

  /// Insert sample weighing tickets for demo
  Future<void> insertSampleData() async {
    try {
      // Kiểm tra xem đã có dữ liệu có trọng lượng chưa
      final existingTickets = await getAll();
      
      // Nếu có phiếu với trọng lượng thực, không cần thêm sample
      final hasRealData = existingTickets.any((t) => 
        (t.firstWeight != null && t.firstWeight! > 0) || 
        (t.netWeight != null && t.netWeight! > 0)
      );
      
      if (hasRealData) {
        _logger.info('WeighingRepo', 'Real weighing data exists, skipping sample data');
        return;
      }
      
      // Xóa các phiếu trống (không có trọng lượng)
      if (existingTickets.isNotEmpty) {
        for (final ticket in existingTickets) {
          if (ticket.id != null && 
              (ticket.firstWeight == null || ticket.firstWeight == 0) &&
              (ticket.netWeight == null || ticket.netWeight == 0)) {
            await delete(ticket.id!);
            _logger.info('WeighingRepo', 'Deleted empty ticket: ${ticket.ticketNumber}');
          }
        }
      }

      final now = DateTime.now();
      final sampleTickets = [
        WeighingTicket(
          ticketNumber: 'PC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0001',
          licensePlate: '29C-12345',
          vehicleType: 'Xe tải',
          driverName: 'Nguyễn Văn A',
          driverPhone: '0901234567',
          customerId: 1,
          customerName: 'Công ty TNHH ABC',
          productId: 1,
          productName: 'Cá tra nguyên liệu',
          firstWeight: 25500,
          firstWeightTime: now.subtract(const Duration(hours: 2)),
          secondWeight: 12300,
          secondWeightTime: now.subtract(const Duration(hours: 1, minutes: 30)),
          netWeight: 13200,
          deduction: 0,
          actualWeight: 13200,
          unitPrice: 35000,
          totalAmount: 462000000,
          weighingType: WeighingType.incoming,
          status: WeighingStatus.completed,
          operatorName: 'Admin',
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 1, minutes: 30)),
          isSynced: true,
        ),
        WeighingTicket(
          ticketNumber: 'PC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0002',
          licensePlate: '51D-67890',
          vehicleType: 'Container 40ft',
          driverName: 'Trần Văn B',
          driverPhone: '0912345678',
          customerId: 2,
          customerName: 'Công ty XYZ',
          productId: 2,
          productName: 'Tôm thẻ chân trắng',
          firstWeight: 38200,
          firstWeightTime: now.subtract(const Duration(hours: 1)),
          secondWeight: 15800,
          secondWeightTime: now.subtract(const Duration(minutes: 30)),
          netWeight: 22400,
          deduction: 100,
          actualWeight: 22300,
          unitPrice: 120000,
          totalAmount: 2676000000,
          weighingType: WeighingType.outgoing,
          status: WeighingStatus.completed,
          operatorName: 'Admin',
          createdAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now.subtract(const Duration(minutes: 30)),
          isSynced: true,
        ),
        WeighingTicket(
          ticketNumber: 'PC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0003',
          licensePlate: '30E-11111',
          vehicleType: 'Xe ben',
          driverName: 'Lê Văn C',
          driverPhone: '0923456789',
          customerId: 3,
          customerName: 'HTX Thủy sản Miền Tây',
          productId: 3,
          productName: 'Cá basa fillet',
          firstWeight: 18700,
          firstWeightTime: now.subtract(const Duration(minutes: 45)),
          secondWeight: 8200,
          secondWeightTime: now.subtract(const Duration(minutes: 15)),
          netWeight: 10500,
          deduction: 50,
          actualWeight: 10450,
          unitPrice: 45000,
          totalAmount: 470250000,
          weighingType: WeighingType.incoming,
          status: WeighingStatus.completed,
          operatorName: 'Admin',
          createdAt: now.subtract(const Duration(minutes: 45)),
          updatedAt: now.subtract(const Duration(minutes: 15)),
          isSynced: false,
        ),
        WeighingTicket(
          ticketNumber: 'PC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0004',
          licensePlate: '43B-22222',
          vehicleType: 'Xe tải đông lạnh',
          driverName: 'Phạm Thị D',
          driverPhone: '0934567890',
          customerId: 4,
          customerName: 'Công ty CP Thủy sản Việt',
          productId: 4,
          productName: 'Cá ngừ đại dương',
          firstWeight: 28900,
          firstWeightTime: now.subtract(const Duration(minutes: 20)),
          secondWeight: null,
          secondWeightTime: null,
          netWeight: null,
          weighingType: WeighingType.incoming,
          status: WeighingStatus.firstWeighed,
          operatorName: 'Admin',
          createdAt: now.subtract(const Duration(minutes: 20)),
          updatedAt: now.subtract(const Duration(minutes: 20)),
          isSynced: false,
        ),
        WeighingTicket(
          ticketNumber: 'PC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0005',
          licensePlate: '60C-33333',
          vehicleType: 'Xe container',
          driverName: 'Hoàng Văn E',
          driverPhone: '0945678901',
          customerId: 5,
          customerName: 'Nhà máy chế biến Hải Phong',
          productId: 5,
          productName: 'Nghêu lụa',
          firstWeight: null,
          firstWeightTime: null,
          secondWeight: null,
          secondWeightTime: null,
          netWeight: null,
          weighingType: WeighingType.outgoing,
          status: WeighingStatus.pending,
          operatorName: 'Admin',
          createdAt: now,
          updatedAt: now,
          isSynced: false,
        ),
      ];

      for (final ticket in sampleTickets) {
        await insert(ticket);
        _logger.info('WeighingRepo', 'Added sample ticket: ${ticket.ticketNumber}');
      }

      _logger.info('WeighingRepo', 'Inserted ${sampleTickets.length} sample weighing tickets');
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to insert sample data', error: e);
    }
  }

  /// Insert 1000 fake weighing tickets for testing
  /// - 10% (100) first weigh only (firstWeighed status)
  /// - 10% (100) second weigh only (conceptually: completed but missing first weight)
  /// - 80% (800) complete with both weights (completed status)
  Future<int> insertTestData({
    int totalCount = 1000,
    double firstWeighOnlyPercent = 0.10,
    double secondWeighOnlyPercent = 0.10,
  }) async {
    _logger.info('WeighingRepo', 'insertTestData called with totalCount=$totalCount');
    try {
      final random = Random();
      final now = DateTime.now();
      int insertedCount = 0;

      // Sample data for random selection
      final licensePlates = [
        '29A-12345', '29B-23456', '29C-34567', '29D-45678', '29E-56789',
        '30A-11111', '30B-22222', '30C-33333', '30D-44444', '30E-55555',
        '51A-66666', '51B-77777', '51C-88888', '51D-99999', '51E-00000',
        '43A-12121', '43B-23232', '43C-34343', '43D-45454', '43E-56565',
        '60A-67676', '60B-78787', '60C-89898', '60D-90909', '60E-01010',
      ];

      final vehicleTypes = [
        'Xe tải 5 tấn', 'Xe tải 10 tấn', 'Xe ben', 'Container 20ft', 
        'Container 40ft', 'Xe đông lạnh', 'Xe tải thùng', 'Xe đầu kéo',
      ];

      final driverNames = [
        'Nguyễn Văn A', 'Trần Văn B', 'Lê Văn C', 'Phạm Văn D', 'Hoàng Văn E',
        'Ngô Văn F', 'Đỗ Văn G', 'Vũ Văn H', 'Bùi Văn I', 'Dương Văn K',
        'Lý Văn L', 'Hồ Văn M', 'Đinh Văn N', 'Mai Văn O', 'Trương Văn P',
      ];

      final customers = [
        {'id': 1, 'name': 'Công ty TNHH ABC'},
        {'id': 2, 'name': 'Công ty XYZ'},
        {'id': 3, 'name': 'HTX Thủy sản Miền Tây'},
        {'id': 4, 'name': 'Công ty CP Thủy sản Việt'},
        {'id': 5, 'name': 'Nhà máy chế biến Hải Phong'},
        {'id': 6, 'name': 'Công ty TNHH Seafood'},
        {'id': 7, 'name': 'Công ty CP Đông Á'},
        {'id': 8, 'name': 'Nhà máy Nam Việt'},
        {'id': 9, 'name': 'Công ty Bình An Fish'},
        {'id': 10, 'name': 'HTX Sông Hậu'},
      ];

      final products = [
        {'id': 1, 'name': 'Cá tra nguyên liệu', 'unitPrice': 35000.0},
        {'id': 2, 'name': 'Tôm thẻ chân trắng', 'unitPrice': 120000.0},
        {'id': 3, 'name': 'Cá basa fillet', 'unitPrice': 45000.0},
        {'id': 4, 'name': 'Cá ngừ đại dương', 'unitPrice': 85000.0},
        {'id': 5, 'name': 'Nghêu lụa', 'unitPrice': 55000.0},
        {'id': 6, 'name': 'Tôm sú', 'unitPrice': 180000.0},
        {'id': 7, 'name': 'Cá điêu hồng', 'unitPrice': 40000.0},
        {'id': 8, 'name': 'Mực ống', 'unitPrice': 95000.0},
        {'id': 9, 'name': 'Cá rô phi', 'unitPrice': 32000.0},
        {'id': 10, 'name': 'Ốc hương', 'unitPrice': 250000.0},
      ];

      // Calculate counts for each category
      final firstWeighOnlyCount = (totalCount * firstWeighOnlyPercent).round();
      final secondWeighOnlyCount = (totalCount * secondWeighOnlyPercent).round();
      final completeCount = totalCount - firstWeighOnlyCount - secondWeighOnlyCount;

      _logger.info('WeighingRepo', 'Generating $totalCount test tickets: '
          '$firstWeighOnlyCount first-weigh, $secondWeighOnlyCount second-weigh, $completeCount complete');

      // Use batch insert for performance
      final batch = _db.batch();

      for (int i = 0; i < totalCount; i++) {
        // Random data selection
        final licensePlate = licensePlates[random.nextInt(licensePlates.length)];
        final vehicleType = vehicleTypes[random.nextInt(vehicleTypes.length)];
        final driverName = driverNames[random.nextInt(driverNames.length)];
        final driverPhone = '09${random.nextInt(100000000).toString().padLeft(8, '0')}';
        final customer = customers[random.nextInt(customers.length)];
        final product = products[random.nextInt(products.length)];
        final weighingType = random.nextBool() ? WeighingType.incoming : WeighingType.outgoing;
        
        // Random date within last 30 days (to match getLast30Days query)
        final daysAgo = random.nextInt(30);
        final hoursAgo = random.nextInt(24);
        final minutesAgo = random.nextInt(60);
        final ticketDate = now.subtract(Duration(
          days: daysAgo,
          hours: hoursAgo,
          minutes: minutesAgo,
        ));

        // Ticket number with date prefix + unique suffix (timestamp + index)
        // Format: TEST-YYMMDD-HHMMSS-XXXX to avoid conflicts with real tickets
        final ticketNumber = 'TEST${ticketDate.year % 100}'
            '${ticketDate.month.toString().padLeft(2, '0')}'
            '${ticketDate.day.toString().padLeft(2, '0')}'
            '${ticketDate.hour.toString().padLeft(2, '0')}'
            '${ticketDate.minute.toString().padLeft(2, '0')}'
            '${(i + 1).toString().padLeft(5, '0')}';

        // Generate weights (gross weight 15-45 tons, tare 5-15 tons)
        final grossWeight = 15000.0 + random.nextDouble() * 30000; // 15-45 tons
        final tareWeight = 5000.0 + random.nextDouble() * 10000; // 5-15 tons
        final deduction = random.nextDouble() < 0.3 ? random.nextInt(200).toDouble() : 0.0;
        final netWeight = grossWeight - tareWeight;
        final actualWeight = netWeight - deduction;
        final unitPrice = product['unitPrice'] as double;
        final totalAmount = actualWeight * unitPrice;

        // Determine ticket type based on index
        WeighingStatus status;
        double? firstWeight;
        DateTime? firstWeightTime;
        double? secondWeight;
        DateTime? secondWeightTime;
        double? ticketNetWeight;
        double? ticketActualWeight;
        double? ticketTotalAmount;
        bool isSynced;

        if (i < firstWeighOnlyCount) {
          // First 10%: First weigh only
          status = WeighingStatus.firstWeighed;
          firstWeight = grossWeight;
          firstWeightTime = ticketDate;
          secondWeight = null;
          secondWeightTime = null;
          ticketNetWeight = null;
          ticketActualWeight = null;
          ticketTotalAmount = null;
          isSynced = false; // Not synced since incomplete
        } else if (i < firstWeighOnlyCount + secondWeighOnlyCount) {
          // Next 10%: Second weigh only (unusual case - for testing)
          // This represents data where first weight was lost/not recorded properly
          status = WeighingStatus.firstWeighed; // Still needs processing
          firstWeight = null;
          firstWeightTime = null;
          secondWeight = tareWeight;
          secondWeightTime = ticketDate;
          ticketNetWeight = null;
          ticketActualWeight = null;
          ticketTotalAmount = null;
          isSynced = false;
        } else {
          // Remaining 80%: Complete tickets
          status = WeighingStatus.completed;
          firstWeight = grossWeight;
          firstWeightTime = ticketDate;
          secondWeight = tareWeight;
          secondWeightTime = ticketDate.add(Duration(minutes: 30 + random.nextInt(120)));
          ticketNetWeight = netWeight;
          ticketActualWeight = actualWeight;
          ticketTotalAmount = totalAmount;
          // 70% of complete tickets are synced
          isSynced = random.nextDouble() < 0.7;
        }

        final ticketMap = {
          'ticket_number': ticketNumber,
          'license_plate': licensePlate,
          'vehicle_type': vehicleType,
          'driver_name': driverName,
          'driver_phone': driverPhone,
          'customer_id': customer['id'],
          'customer_name': customer['name'],
          'product_id': product['id'],
          'product_name': product['name'],
          'first_weight': firstWeight,
          'first_weight_time': firstWeightTime?.toIso8601String(),
          'second_weight': secondWeight,
          'second_weight_time': secondWeightTime?.toIso8601String(),
          'net_weight': ticketNetWeight,
          'deduction': deduction,
          'actual_weight': ticketActualWeight,
          'unit_price': unitPrice,
          'total_amount': ticketTotalAmount,
          'weighing_type': weighingType.value,
          'status': status.value,
          'note': i % 10 == 0 ? 'Phiếu test #${i + 1}' : null,
          'first_weight_image': null,
          'second_weight_image': null,
          'license_plate_image': null,
          'scale_id': 1,
          'operator_id': 'admin',
          'operator_name': 'Admin',
          'created_at': ticketDate.toIso8601String(),
          'updated_at': (secondWeightTime ?? ticketDate).toIso8601String(),
          'is_synced': isSynced ? 1 : 0,
          'azure_id': isSynced ? 1000 + i : null,
          'synced_at': isSynced ? ticketDate.add(const Duration(hours: 1)).toIso8601String() : null,
        };

        batch.insert(_tableName, ticketMap);
        insertedCount++;

        // Log progress every 100 tickets
        if ((i + 1) % 100 == 0) {
          _logger.info('WeighingRepo', 'Generated ${i + 1}/$totalCount test tickets...');
        }
      }

      // Execute batch insert
      _logger.info('WeighingRepo', 'Committing batch insert...');
      await batch.commit(noResult: true);
      
      _logger.info('WeighingRepo', 'Successfully inserted $insertedCount test tickets');
      _logger.info('WeighingRepo', 'Distribution: $firstWeighOnlyCount first-weigh only, '
          '$secondWeighOnlyCount second-weigh only, $completeCount complete');

      return insertedCount;
    } catch (e, stackTrace) {
      _logger.error('WeighingRepo', 'Failed to insert test data: $e\n$stackTrace', error: e);
      rethrow; // Re-throw để UI có thể hiển thị lỗi chi tiết
    }
  }

  /// Delete all test data (tickets with ticket_number starting with 'TEST')
  Future<int> deleteTestData() async {
    try {
      final count = await _db.delete(
        _tableName,
        where: "ticket_number LIKE 'TEST%'",
      );
      _logger.info('WeighingRepo', 'Deleted $count test tickets');
      return count;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to delete test data', error: e);
      return 0;
    }
  }

  /// Clear all data from the table
  Future<int> clearAll() async {
    try {
      final count = await _db.delete(_tableName);
      _logger.info('WeighingRepo', 'Cleared all $count tickets from database');
      return count;
    } catch (e) {
      _logger.error('WeighingRepo', 'Failed to clear all data', error: e);
      return 0;
    }
  }
}
