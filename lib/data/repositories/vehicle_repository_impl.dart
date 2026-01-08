import 'package:flutter/foundation.dart';
import 'package:canoto/data/models/vehicle.dart';

/// Vehicle Repository Implementation với dữ liệu mẫu
class VehicleRepositoryImpl {
  VehicleRepositoryImpl._();
  static final VehicleRepositoryImpl instance = VehicleRepositoryImpl._();

  final List<Vehicle> _vehicles = [];
  bool _initialized = false;

  /// Khởi tạo dữ liệu mẫu
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    _vehicles.addAll([
      Vehicle(
        id: 1,
        licensePlate: '51C-12345',
        vehicleType: 'Xe tải',
        brand: 'Hyundai',
        model: 'HD120',
        color: 'Trắng',
        tareWeight: 5200,
        customerId: 1,
        customerName: 'Công ty TNHH Thủy Sản Miền Tây',
        driverName: 'Nguyễn Văn Tài',
        driverPhone: '0901111222',
        isActive: true,
      ),
      Vehicle(
        id: 2,
        licensePlate: '51C-67890',
        vehicleType: 'Xe tải',
        brand: 'Isuzu',
        model: 'NPR85K',
        color: 'Xanh',
        tareWeight: 4800,
        customerId: 1,
        customerName: 'Công ty TNHH Thủy Sản Miền Tây',
        driverName: 'Trần Văn Bảy',
        driverPhone: '0902222333',
        isActive: true,
      ),
      Vehicle(
        id: 3,
        licensePlate: '65C-11111',
        vehicleType: 'Xe ben',
        brand: 'Howo',
        model: 'A7',
        color: 'Đỏ',
        tareWeight: 8500,
        customerId: 2,
        customerName: 'Công ty CP Nông Sản Việt',
        driverName: 'Lê Văn Chín',
        driverPhone: '0903333444',
        isActive: true,
      ),
      Vehicle(
        id: 4,
        licensePlate: '65C-22222',
        vehicleType: 'Xe container',
        brand: 'Mercedes',
        model: 'Actros',
        color: 'Trắng',
        tareWeight: 12000,
        customerId: 3,
        customerName: 'HTX Nông nghiệp Cần Thơ',
        driverName: 'Phạm Văn Mười',
        driverPhone: '0904444555',
        isActive: true,
      ),
      Vehicle(
        id: 5,
        licensePlate: '51C-99999',
        vehicleType: 'Xe tải nhỏ',
        brand: 'Kia',
        model: 'K200',
        color: 'Xám',
        tareWeight: 2100,
        customerId: 4,
        customerName: 'Công ty TNHH Xuất Nhập Khẩu Đông Á',
        driverName: 'Hoàng Văn Một',
        driverPhone: '0905555666',
        isActive: true,
      ),
      Vehicle(
        id: 6,
        licensePlate: '51C-88888',
        vehicleType: 'Xe tải',
        brand: 'Hino',
        model: '500 Series',
        color: 'Vàng',
        tareWeight: 6800,
        isActive: false,
        note: 'Xe đang bảo trì',
      ),
    ]);
    
    debugPrint('VehicleRepository: Initialized with ${_vehicles.length} vehicles');
  }

  /// Lấy tất cả xe
  List<Vehicle> getAll() {
    initialize();
    return List.unmodifiable(_vehicles);
  }

  /// Lấy xe đang hoạt động
  List<Vehicle> getActive() {
    initialize();
    return _vehicles.where((v) => v.isActive).toList();
  }

  /// Tìm theo ID
  Vehicle? getById(int id) {
    initialize();
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tìm theo biển số
  Vehicle? getByLicensePlate(String licensePlate) {
    initialize();
    final normalized = licensePlate.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
    try {
      return _vehicles.firstWhere((v) {
        final vPlate = v.licensePlate.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
        return vPlate == normalized;
      });
    } catch (_) {
      return null;
    }
  }

  /// Lấy xe theo khách hàng
  List<Vehicle> getByCustomerId(int customerId) {
    initialize();
    return _vehicles.where((v) => v.customerId == customerId).toList();
  }

  /// Tìm kiếm
  List<Vehicle> search(String query) {
    initialize();
    final lowerQuery = query.toLowerCase();
    return _vehicles.where((v) {
      return v.licensePlate.toLowerCase().contains(lowerQuery) ||
          (v.driverName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (v.customerName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (v.vehicleType?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Thêm xe
  Vehicle add(Vehicle vehicle) {
    initialize();
    final newId = _vehicles.isEmpty ? 1 : _vehicles.map((v) => v.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final newVehicle = vehicle.copyWith(id: newId);
    _vehicles.add(newVehicle);
    return newVehicle;
  }

  /// Cập nhật xe
  bool update(Vehicle vehicle) {
    initialize();
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      _vehicles[index] = vehicle.copyWith(updatedAt: DateTime.now());
      return true;
    }
    return false;
  }

  /// Xóa xe (soft delete)
  bool delete(int id) {
    initialize();
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index >= 0) {
      _vehicles[index] = _vehicles[index].copyWith(isActive: false);
      return true;
    }
    return false;
  }

  /// Đếm tổng số
  int get count {
    initialize();
    return _vehicles.length;
  }

  /// Đếm đang hoạt động
  int get activeCount {
    initialize();
    return _vehicles.where((v) => v.isActive).length;
  }
}
