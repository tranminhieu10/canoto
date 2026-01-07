import 'package:canoto/data/models/product.dart';

/// Repository cho sản phẩm
abstract class ProductRepository {
  /// Lấy tất cả sản phẩm
  Future<List<Product>> getAll();

  /// Lấy sản phẩm theo ID
  Future<Product?> getById(int id);

  /// Lấy sản phẩm theo mã
  Future<Product?> getByCode(String code);

  /// Tìm kiếm sản phẩm
  Future<List<Product>> search(String query);

  /// Lấy sản phẩm theo danh mục
  Future<List<Product>> getByCategory(String category);

  /// Thêm sản phẩm mới
  Future<int> insert(Product product);

  /// Cập nhật sản phẩm
  Future<int> update(Product product);

  /// Xóa sản phẩm
  Future<int> delete(int id);
}
