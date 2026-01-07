import 'package:canoto/data/models/vehicle.dart';

/// Repository cho xe
abstract class VehicleRepository {
  /// Lấy tất cả xe
  Future<List<Vehicle>> getAll();

  /// Lấy xe theo ID
  Future<Vehicle?> getById(int id);

  /// Lấy xe theo biển số
  Future<Vehicle?> getByLicensePlate(String licensePlate);

  /// Tìm kiếm xe
  Future<List<Vehicle>> search(String query);

  /// Thêm xe mới
  Future<int> insert(Vehicle vehicle);

  /// Cập nhật xe
  Future<int> update(Vehicle vehicle);

  /// Xóa xe
  Future<int> delete(int id);

  /// Lấy xe theo khách hàng
  Future<List<Vehicle>> getByCustomerId(int customerId);
}
