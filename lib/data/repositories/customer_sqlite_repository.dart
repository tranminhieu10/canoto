import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:canoto/data/models/customer.dart';
import 'package:canoto/services/database/database_service.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// SQLite implementation của Customer Repository
class CustomerSqliteRepository {
  // Singleton
  static CustomerSqliteRepository? _instance;
  static CustomerSqliteRepository get instance =>
      _instance ??= CustomerSqliteRepository._();
  CustomerSqliteRepository._();

  final LoggingService _logger = LoggingService.instance;

  Database get _db => DatabaseService.instance.database;

  static const String _tableName = 'customers';

  /// Convert Customer to Map for database
  Map<String, dynamic> _toMap(Customer customer) {
    return {
      if (customer.id != null) 'id': customer.id,
      'code': customer.code,
      'name': customer.name,
      'address': customer.address,
      'phone': customer.phone,
      'email': customer.email,
      'tax_code': customer.taxCode,
      'contact_person': customer.contactPerson,
      'notes': customer.note,
      'is_active': customer.isActive ? 1 : 0,
      'created_at': customer.createdAt.toIso8601String(),
      'updated_at': customer.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to Customer
  Customer _fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      taxCode: map['tax_code'] as String?,
      contactPerson: map['contact_person'] as String?,
      note: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Lấy tất cả khách hàng
  Future<List<Customer>> getAll() async {
    try {
      final maps = await _db.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to get all customers', error: e);
      return [];
    }
  }

  /// Lấy khách hàng đang hoạt động
  Future<List<Customer>> getActive() async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to get active customers', error: e);
      return [];
    }
  }

  /// Tìm theo ID
  Future<Customer?> getById(int id) async {
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
      _logger.error('CustomerSqliteRepo', 'Failed to get customer by id', error: e);
      return null;
    }
  }

  /// Tìm theo mã
  Future<Customer?> getByCode(String code) async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return _fromMap(maps.first);
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to get customer by code', error: e);
      return null;
    }
  }

  /// Tìm kiếm khách hàng
  Future<List<Customer>> search(String query) async {
    try {
      final lowerQuery = '%${query.toLowerCase()}%';
      final maps = await _db.query(
        _tableName,
        where: 'LOWER(code) LIKE ? OR LOWER(name) LIKE ? OR phone LIKE ? OR LOWER(contact_person) LIKE ?',
        whereArgs: [lowerQuery, lowerQuery, '%$query%', lowerQuery],
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to search customers', error: e);
      return [];
    }
  }

  /// Thêm khách hàng mới
  Future<Customer?> add(Customer customer) async {
    try {
      final now = DateTime.now();
      final newCustomer = customer.copyWith(
        code: customer.code.isEmpty ? await _generateCode() : customer.code,
        createdAt: now,
        updatedAt: now,
      );
      
      final id = await _db.insert(_tableName, _toMap(newCustomer));
      _logger.info('CustomerSqliteRepo', 'Added customer: ${newCustomer.name} with id: $id');
      return newCustomer.copyWith(id: id);
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to add customer', error: e);
      return null;
    }
  }

  /// Cập nhật khách hàng
  Future<bool> update(Customer customer) async {
    try {
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
      final count = await _db.update(
        _tableName,
        _toMap(updatedCustomer),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      _logger.info('CustomerSqliteRepo', 'Updated customer: ${customer.name}');
      return count > 0;
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to update customer', error: e);
      return false;
    }
  }

  /// Xóa khách hàng (soft delete)
  Future<bool> delete(int id) async {
    try {
      final count = await _db.update(
        _tableName,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('CustomerSqliteRepo', 'Soft deleted customer: $id');
      return count > 0;
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to delete customer', error: e);
      return false;
    }
  }

  /// Xóa vĩnh viễn
  Future<bool> hardDelete(int id) async {
    try {
      final count = await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('CustomerSqliteRepo', 'Hard deleted customer: $id');
      return count > 0;
    } catch (e) {
      _logger.error('CustomerSqliteRepo', 'Failed to hard delete customer', error: e);
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

  /// Tạo mã khách hàng tự động
  Future<String> _generateCode() async {
    final count = await this.count();
    return 'KH${(count + 1).toString().padLeft(3, '0')}';
  }

  /// Thêm dữ liệu mẫu (chỉ khi bảng trống)
  Future<void> insertSampleData() async {
    final currentCount = await count();
    if (currentCount > 0) return;

    final now = DateTime.now();
    final sampleCustomers = [
      Customer(
        code: 'KH001',
        name: 'Công ty Thủy sản A',
        address: '123 Nguyễn Văn Linh, Quận 7, TP.HCM',
        phone: '0281234567',
        email: 'contact@thuysana.com',
        taxCode: '0301234567',
        contactPerson: 'Nguyễn Văn A',
        createdAt: now,
        updatedAt: now,
      ),
      Customer(
        code: 'KH002',
        name: 'Công ty Xuất nhập khẩu B',
        address: '456 Lê Lợi, Quận 1, TP.HCM',
        phone: '0287654321',
        email: 'info@xnkb.com',
        taxCode: '0302345678',
        contactPerson: 'Trần Thị B',
        createdAt: now,
        updatedAt: now,
      ),
      Customer(
        code: 'KH003',
        name: 'Công ty Logistics C',
        address: '789 Võ Văn Kiệt, Quận 5, TP.HCM',
        phone: '0289876543',
        email: 'logistics@ctyc.com',
        contactPerson: 'Lê Văn C',
        createdAt: now,
        updatedAt: now,
      ),
      Customer(
        code: 'KH004',
        name: 'Hộ kinh doanh D',
        address: 'Chợ Bình Điền, Quận 8, TP.HCM',
        phone: '0909123456',
        contactPerson: 'Phạm Văn D',
        createdAt: now,
        updatedAt: now,
      ),
      Customer(
        code: 'KH005',
        name: 'Công ty TNHH E',
        address: '321 Điện Biên Phủ, Quận 3, TP.HCM',
        phone: '0283456789',
        email: 'sales@ctye.vn',
        taxCode: '0305678901',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final customer in sampleCustomers) {
      await add(customer);
    }
    _logger.info('CustomerSqliteRepo', 'Inserted ${sampleCustomers.length} sample customers');
  }
}
