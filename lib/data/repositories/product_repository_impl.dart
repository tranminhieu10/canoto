import 'package:flutter/foundation.dart';
import 'package:canoto/data/models/product.dart';

/// Product Repository Implementation với dữ liệu mẫu
class ProductRepositoryImpl {
  ProductRepositoryImpl._();
  static final ProductRepositoryImpl instance = ProductRepositoryImpl._();

  final List<Product> _products = [];
  bool _initialized = false;

  /// Khởi tạo dữ liệu mẫu
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    _products.addAll([
      Product(
        id: 1,
        code: 'TS001',
        name: 'Cá tra fillet',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 85000,
        description: 'Cá tra fillet đông lạnh xuất khẩu',
        isActive: true,
      ),
      Product(
        id: 2,
        code: 'TS002',
        name: 'Tôm sú nguyên con',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 280000,
        description: 'Tôm sú size 20-25 con/kg',
        isActive: true,
      ),
      Product(
        id: 3,
        code: 'TS003',
        name: 'Cá basa nguyên con',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 45000,
        description: 'Cá basa tươi sống',
        isActive: true,
      ),
      Product(
        id: 4,
        code: 'NS001',
        name: 'Gạo ST25',
        category: 'Nông sản',
        unit: 'kg',
        unitPrice: 32000,
        description: 'Gạo ST25 Sóc Trăng',
        isActive: true,
      ),
      Product(
        id: 5,
        code: 'NS002',
        name: 'Lúa tươi',
        category: 'Nông sản',
        unit: 'tấn',
        unitPrice: 7500000,
        description: 'Lúa tươi vụ Đông Xuân',
        isActive: true,
      ),
      Product(
        id: 6,
        code: 'NS003',
        name: 'Cám gạo',
        category: 'Phụ phẩm',
        unit: 'kg',
        unitPrice: 8000,
        description: 'Cám gạo làm thức ăn chăn nuôi',
        isActive: true,
      ),
      Product(
        id: 7,
        code: 'TS004',
        name: 'Mực ống',
        category: 'Thủy sản',
        unit: 'kg',
        unitPrice: 180000,
        description: 'Mực ống tươi đông lạnh',
        isActive: true,
      ),
      Product(
        id: 8,
        code: 'NS004',
        name: 'Bắp hạt',
        category: 'Nông sản',
        unit: 'kg',
        unitPrice: 12000,
        description: 'Bắp hạt khô - Hết mùa',
        isActive: false,
      ),
    ]);
    
    debugPrint('ProductRepository: Initialized with ${_products.length} products');
  }

  /// Lấy tất cả sản phẩm
  List<Product> getAll() {
    initialize();
    return List.unmodifiable(_products);
  }

  /// Lấy sản phẩm đang hoạt động
  List<Product> getActive() {
    initialize();
    return _products.where((p) => p.isActive).toList();
  }

  /// Tìm theo ID
  Product? getById(int id) {
    initialize();
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tìm theo mã
  Product? getByCode(String code) {
    initialize();
    try {
      return _products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Lấy theo danh mục
  List<Product> getByCategory(String category) {
    initialize();
    return _products.where((p) => p.category == category).toList();
  }

  /// Lấy danh sách danh mục
  List<String> getCategories() {
    initialize();
    return _products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();
  }

  /// Tìm kiếm
  List<Product> search(String query) {
    initialize();
    final lowerQuery = query.toLowerCase();
    return _products.where((p) {
      return p.code.toLowerCase().contains(lowerQuery) ||
          p.name.toLowerCase().contains(lowerQuery) ||
          (p.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Thêm sản phẩm
  Product add(Product product) {
    initialize();
    final newId = _products.isEmpty ? 1 : _products.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final newProduct = product.copyWith(id: newId);
    _products.add(newProduct);
    return newProduct;
  }

  /// Cập nhật sản phẩm
  bool update(Product product) {
    initialize();
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product.copyWith(updatedAt: DateTime.now());
      return true;
    }
    return false;
  }

  /// Xóa sản phẩm (soft delete)
  bool delete(int id) {
    initialize();
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _products[index] = _products[index].copyWith(isActive: false);
      return true;
    }
    return false;
  }

  /// Đếm tổng số
  int get count {
    initialize();
    return _products.length;
  }

  /// Đếm đang hoạt động
  int get activeCount {
    initialize();
    return _products.where((p) => p.isActive).length;
  }
}
