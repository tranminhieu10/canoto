import 'package:canoto/data/models/customer.dart';

/// Repository cho khách hàng
abstract class CustomerRepository {
  /// Lấy tất cả khách hàng
  Future<List<Customer>> getAll();

  /// Lấy khách hàng theo ID
  Future<Customer?> getById(int id);

  /// Lấy khách hàng theo mã
  Future<Customer?> getByCode(String code);

  /// Tìm kiếm khách hàng
  Future<List<Customer>> search(String query);

  /// Thêm khách hàng mới
  Future<int> insert(Customer customer);

  /// Cập nhật khách hàng
  Future<int> update(Customer customer);

  /// Xóa khách hàng
  Future<int> delete(int id);
}
