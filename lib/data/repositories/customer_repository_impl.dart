import 'package:flutter/foundation.dart';
import 'package:canoto/data/models/customer.dart';

/// Customer Repository Implementation với dữ liệu mẫu
class CustomerRepositoryImpl {
  CustomerRepositoryImpl._();
  static final CustomerRepositoryImpl instance = CustomerRepositoryImpl._();

  final List<Customer> _customers = [];
  bool _initialized = false;

  /// Khởi tạo dữ liệu mẫu
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    _customers.addAll([
      Customer(
        id: 1,
        code: 'KH001',
        name: 'Công ty TNHH Thủy Sản Miền Tây',
        contactPerson: 'Nguyễn Văn An',
        phone: '0901234567',
        email: 'contact@thuysan-mientay.vn',
        address: '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
        taxCode: '0312345678',
        bankAccount: '123456789012',
        bankName: 'Vietcombank',
        note: 'Khách hàng VIP',
        isActive: true,
      ),
      Customer(
        id: 2,
        code: 'KH002',
        name: 'Công ty CP Nông Sản Việt',
        contactPerson: 'Trần Thị Bình',
        phone: '0912345678',
        email: 'info@nongsanviet.com',
        address: '456 Đường Lê Lợi, Quận 3, TP.HCM',
        taxCode: '0398765432',
        bankAccount: '987654321098',
        bankName: 'Techcombank',
        isActive: true,
      ),
      Customer(
        id: 3,
        code: 'KH003',
        name: 'HTX Nông nghiệp Cần Thơ',
        contactPerson: 'Lê Văn Cường',
        phone: '0923456789',
        email: 'htx-cantho@gmail.com',
        address: '789 Đường 30/4, Ninh Kiều, Cần Thơ',
        taxCode: '1800123456',
        isActive: true,
      ),
      Customer(
        id: 4,
        code: 'KH004',
        name: 'Công ty TNHH Xuất Nhập Khẩu Đông Á',
        contactPerson: 'Phạm Minh Đức',
        phone: '0934567890',
        email: 'dongaxnk@gmail.com',
        address: '321 Đường Hai Bà Trưng, Quận 1, TP.HCM',
        taxCode: '0311112222',
        bankAccount: '111222333444',
        bankName: 'BIDV',
        isActive: true,
      ),
      Customer(
        id: 5,
        code: 'KH005',
        name: 'Cửa hàng Thực phẩm Sạch',
        contactPerson: 'Hoàng Thị Em',
        phone: '0945678901',
        email: 'thucphamsach@yahoo.com',
        address: '567 Đường Cách Mạng Tháng 8, Quận 10, TP.HCM',
        isActive: false,
        note: 'Tạm ngừng hợp tác',
      ),
    ]);
    
    debugPrint('CustomerRepository: Initialized with ${_customers.length} customers');
  }

  /// Lấy tất cả khách hàng
  List<Customer> getAll() {
    initialize();
    return List.unmodifiable(_customers);
  }

  /// Lấy khách hàng đang hoạt động
  List<Customer> getActive() {
    initialize();
    return _customers.where((c) => c.isActive).toList();
  }

  /// Tìm theo ID
  Customer? getById(int id) {
    initialize();
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tìm theo mã
  Customer? getByCode(String code) {
    initialize();
    try {
      return _customers.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Tìm kiếm
  List<Customer> search(String query) {
    initialize();
    final lowerQuery = query.toLowerCase();
    return _customers.where((c) {
      return c.code.toLowerCase().contains(lowerQuery) ||
          c.name.toLowerCase().contains(lowerQuery) ||
          (c.phone?.contains(query) ?? false) ||
          (c.contactPerson?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Thêm khách hàng
  Customer add(Customer customer) {
    initialize();
    final newId = _customers.isEmpty ? 1 : _customers.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    final newCustomer = customer.copyWith(id: newId);
    _customers.add(newCustomer);
    return newCustomer;
  }

  /// Cập nhật khách hàng
  bool update(Customer customer) {
    initialize();
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer.copyWith(updatedAt: DateTime.now());
      return true;
    }
    return false;
  }

  /// Xóa khách hàng (soft delete)
  bool delete(int id) {
    initialize();
    final index = _customers.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _customers[index] = _customers[index].copyWith(isActive: false);
      return true;
    }
    return false;
  }

  /// Xóa vĩnh viễn
  bool hardDelete(int id) {
    initialize();
    final index = _customers.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _customers.removeAt(index);
      return true;
    }
    return false;
  }

  /// Đếm tổng số
  int get count {
    initialize();
    return _customers.length;
  }

  /// Đếm đang hoạt động
  int get activeCount {
    initialize();
    return _customers.where((c) => c.isActive).length;
  }
}
