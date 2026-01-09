import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:canoto/data/models/product.dart';
import 'package:canoto/services/database/database_service.dart';
import 'package:canoto/services/logging/logging_service.dart';

/// SQLite implementation của Product Repository
class ProductSqliteRepository {
  // Singleton
  static ProductSqliteRepository? _instance;
  static ProductSqliteRepository get instance =>
      _instance ??= ProductSqliteRepository._();
  ProductSqliteRepository._();

  final LoggingService _logger = LoggingService.instance;

  Database get _db => DatabaseService.instance.database;

  static const String _tableName = 'products';

  /// Convert Product to Map for database
  Map<String, dynamic> _toMap(Product product) {
    return {
      if (product.id != null) 'id': product.id,
      'code': product.code,
      'name': product.name,
      'category': product.category,
      'unit': product.unit,
      'unit_price': product.unitPrice,
      'description': product.description,
      'is_active': product.isActive ? 1 : 0,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from database to Product
  Product _fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String,
      category: map['category'] as String?,
      unit: map['unit'] as String?,
      unitPrice: map['unit_price'] as double?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Lấy tất cả sản phẩm
  Future<List<Product>> getAll() async {
    try {
      final maps = await _db.query(
        _tableName,
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to get all products', error: e);
      return [];
    }
  }

  /// Lấy sản phẩm đang hoạt động
  Future<List<Product>> getActive() async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to get active products', error: e);
      return [];
    }
  }

  /// Tìm theo ID
  Future<Product?> getById(int id) async {
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
      _logger.error('ProductSqliteRepo', 'Failed to get product by id', error: e);
      return null;
    }
  }

  /// Tìm theo mã
  Future<Product?> getByCode(String code) async {
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
      _logger.error('ProductSqliteRepo', 'Failed to get product by code', error: e);
      return null;
    }
  }

  /// Lấy theo danh mục
  Future<List<Product>> getByCategory(String category) async {
    try {
      final maps = await _db.query(
        _tableName,
        where: 'category = ? AND is_active = 1',
        whereArgs: [category],
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to get products by category', error: e);
      return [];
    }
  }

  /// Lấy danh sách danh mục
  Future<List<String>> getCategories() async {
    try {
      final maps = await _db.rawQuery(
        'SELECT DISTINCT category FROM $_tableName WHERE category IS NOT NULL AND is_active = 1 ORDER BY category'
      );
      return maps.map((m) => m['category'] as String).toList();
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to get categories', error: e);
      return [];
    }
  }

  /// Tìm kiếm sản phẩm
  Future<List<Product>> search(String query) async {
    try {
      final lowerQuery = '%${query.toLowerCase()}%';
      final maps = await _db.query(
        _tableName,
        where: 'LOWER(code) LIKE ? OR LOWER(name) LIKE ? OR LOWER(category) LIKE ?',
        whereArgs: [lowerQuery, lowerQuery, lowerQuery],
        orderBy: 'name ASC',
      );
      return maps.map((m) => _fromMap(m)).toList();
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to search products', error: e);
      return [];
    }
  }

  /// Thêm sản phẩm mới
  Future<Product?> add(Product product) async {
    try {
      final now = DateTime.now();
      final newProduct = product.copyWith(
        code: product.code.isEmpty ? await _generateCode() : product.code,
        createdAt: now,
        updatedAt: now,
      );
      
      final id = await _db.insert(_tableName, _toMap(newProduct));
      _logger.info('ProductSqliteRepo', 'Added product: ${newProduct.name} with id: $id');
      return newProduct.copyWith(id: id);
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to add product', error: e);
      return null;
    }
  }

  /// Cập nhật sản phẩm
  Future<bool> update(Product product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      final count = await _db.update(
        _tableName,
        _toMap(updatedProduct),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      _logger.info('ProductSqliteRepo', 'Updated product: ${product.name}');
      return count > 0;
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to update product', error: e);
      return false;
    }
  }

  /// Xóa sản phẩm (soft delete)
  Future<bool> delete(int id) async {
    try {
      final count = await _db.update(
        _tableName,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.info('ProductSqliteRepo', 'Soft deleted product: $id');
      return count > 0;
    } catch (e) {
      _logger.error('ProductSqliteRepo', 'Failed to delete product', error: e);
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

  /// Tạo mã sản phẩm tự động
  Future<String> _generateCode() async {
    final count = await this.count();
    return 'SP${(count + 1).toString().padLeft(3, '0')}';
  }

  /// Thêm dữ liệu mẫu (chỉ khi bảng trống)
  Future<void> insertSampleData() async {
    final currentCount = await count();
    if (currentCount > 0) return;

    final now = DateTime.now();
    final sampleProducts = [
      Product(
        code: 'SP001',
        name: 'Cá tra fillet',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 85000,
        description: 'Cá tra fillet đông lạnh xuất khẩu',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP002',
        name: 'Tôm sú',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 180000,
        description: 'Tôm sú nguyên con',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP003',
        name: 'Cá basa nguyên con',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP004',
        name: 'Thức ăn cá viên nổi',
        category: 'Thức ăn',
        unit: 'kg',
        unitPrice: 25000,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP005',
        name: 'Thức ăn tôm cao cấp',
        category: 'Thức ăn',
        unit: 'kg',
        unitPrice: 35000,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP006',
        name: 'Mực ống',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 120000,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        code: 'SP007',
        name: 'Phân bón NPK',
        category: 'Vật tư',
        unit: 'kg',
        unitPrice: 15000,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final product in sampleProducts) {
      await add(product);
    }
    _logger.info('ProductSqliteRepo', 'Inserted ${sampleProducts.length} sample products');
  }
}
