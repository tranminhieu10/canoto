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
}
