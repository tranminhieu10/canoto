import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:canoto/data/models/vehicle.dart';
import 'package:canoto/services/database/database_service.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// SQLite implementation của Vehicle Repository
class VehicleSqliteRepository {
  // Singleton
  static VehicleSqliteRepository? _instance;
  static VehicleSqliteRepository get instance =>
      _instance ??= VehicleSqliteRepository._();
  VehicleSqliteRepository._();

  final LoggingService _logger = LoggingService.instance;

  Database get _db => DatabaseService.instance.database;

  static const String _tableName = 'vehicles';

  /// Convert Vehicle to Map for database
  Map<String, dynamic> _toMap(Vehicle vehicle) {
    return {
      if (vehicle.id != null) 'id': vehicle.id,
      'license_plate': vehicle.licensePlate,
      'vehicle_type': vehicle.vehicleType,
      'brand': vehicle.brand,
      'model': vehicle.model,
      'color': vehicle.color,
      'tare_weight': vehicle.tareWeight,
      'customer_id': vehicle.customerId,
      'customer_name': vehicle.customerName,
      'driver_name': vehicle.driverName,
      'driver_phone': vehicle.driverPhone,
      'note': vehicle.note,
      'is_active': vehicle.isActive ? 1 : 0,
      'created_at': vehicle.createdAt.toIso8601String(),
      'updated_at': vehicle.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to Vehicle
  Vehicle _fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      licensePlate: map['license_plate'] as String,
      vehicleType: map['vehicle_type'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      color: map['color'] as String?,
      tareWeight: map['tare_weight'] as double?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      note: map['note'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Lấy tất cả xe
  Future<List<Vehicle>> getAll() async {
    try {
      final maps = await _db.query(
        _tableName,
        orderBy: 'license_plate ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to get all vehicles', error: e);
      return [];
    }
  }

  /// Lấy xe đang hoạt động
  Future<List<Vehicle>> getActive() async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'license_plate ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to get active vehicles', error: e);
      return [];
    }
  }

  /// Tìm theo ID
  Future<Vehicle?> getById(int id) async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return _fromMap(maps.first);
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to get vehicle by id', error: e);
      return null;
    }
  }

  /// Tìm theo biển số
  Future<Vehicle?> getByLicensePlate(String licensePlate) async {
    try {
      final normalized = licensePlate.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
      final maps = await _db.query(
        _tableName,
        where: "REPLACE(REPLACE(UPPER(license_plate), ' ', ''), '-', '') = ?",
        whereArgs: [normalized],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return _fromMap(maps.first);
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to get vehicle by plate', error: e);
      return null;
    }
  }

  /// Tìm kiếm xe
  Future<List<Vehicle>> search(String query) async {
    try {
      final lowerQuery = '%${query.toLowerCase()}%';
      final maps = await _db.query(
        _tableName,
        where: 'LOWER(license_plate) LIKE ? OR LOWER(owner_name) LIKE ? OR LOWER(vehicle_type) LIKE ?',
        whereArgs: [lowerQuery, lowerQuery, lowerQuery],
        orderBy: 'license_plate ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to search vehicles', error: e);
      return [];
    }
  }

  /// Thêm xe mới
  Future<Vehicle?> add(Vehicle vehicle) async {
    try {
      final now = DateTime.now();
      final newVehicle = vehicle.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      
      final id = await _db.insert(_tableName, _toMap(newVehicle));
      _logger.info('VehicleSqliteRepo', 'Added vehicle: ${newVehicle.licensePlate} with id: $id');
      return newVehicle.copyWith(id: id);
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to add vehicle', error: e);
      return null;
    }
  }

  /// Cập nhật xe
  Future<bool> update(Vehicle vehicle) async {
    try {
      final updatedVehicle = vehicle.copyWith(updatedAt: DateTime.now());
      final count = await _db.update(
        _tableName,
        _toMap(updatedVehicle),
        where: 'id = ?',
        whereArgs: [vehicle.id],
      );
      _logger.info('VehicleSqliteRepo', 'Updated vehicle: ${vehicle.licensePlate}');
      return count > 0;
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to update vehicle', error: e);
      return false;
    }
  }

  /// Xóa xe (soft delete)
  Future<bool> delete(int id) async {
    try {
      final count = await _db.update(
        _tableName,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('VehicleSqliteRepo', 'Soft deleted vehicle: $id');
      return count > 0;
    } catch (e) {
      _logger.error('VehicleSqliteRepo', 'Failed to delete vehicle', error: e);
      return false;
    }
  }

  /// Đếm tổng số
  Future<int> count() async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Đếm đang hoạt động
  Future<int> activeCount() async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE is_active = 1');
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Thêm dữ liệu mẫu (chỉ khi bảng trống)
  Future<void> insertSampleData() async {
    final currentCount = await count();
    if (currentCount > 0) return;

    final now = DateTime.now();
    final sampleVehicles = [
      Vehicle(
        licensePlate: '29C-12345',
        vehicleType: 'Xe tải',
        brand: 'Hyundai',
        model: 'HD72',
        tareWeight: 3500,
        customerId: 1,
        customerName: 'Công ty Thủy sản A',
        driverName: 'Nguyễn Văn Tài',
        driverPhone: '0901234567',
        createdAt: now,
        updatedAt: now,
      ),
      Vehicle(
        licensePlate: '51D-67890',
        vehicleType: 'Xe tải',
        brand: 'Isuzu',
        model: 'FRR90',
        tareWeight: 4200,
        customerId: 2,
        customerName: 'Công ty Xuất nhập khẩu B',
        driverName: 'Trần Văn Lái',
        driverPhone: '0912345678',
        createdAt: now,
        updatedAt: now,
      ),
      Vehicle(
        licensePlate: '30E-11111',
        vehicleType: 'Xe container',
        brand: 'Hino',
        model: '500',
        tareWeight: 7500,
        customerId: 3,
        customerName: 'Công ty Logistics C',
        driverName: 'Phạm Văn Xe',
        driverPhone: '0923456789',
        createdAt: now,
        updatedAt: now,
      ),
      Vehicle(
        licensePlate: '43B-22222',
        vehicleType: 'Xe tải nhẹ',
        brand: 'Kia',
        model: 'K200',
        tareWeight: 1800,
        createdAt: now,
        updatedAt: now,
      ),
      Vehicle(
        licensePlate: '60C-33333',
        vehicleType: 'Xe ben',
        brand: 'Dongfeng',
        model: 'B180',
        tareWeight: 6200,
        driverName: 'Lê Văn Ben',
        driverPhone: '0934567890',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final vehicle in sampleVehicles) {
      await add(vehicle);
    }
    _logger.info('VehicleSqliteRepo', 'Inserted ${sampleVehicles.length} sample vehicles');
  }
}
