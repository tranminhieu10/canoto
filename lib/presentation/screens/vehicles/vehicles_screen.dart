import 'package:flutter/material.dart';
import 'package:canoto/data/models/vehicle.dart';
import 'package:canoto/data/repositories/vehicle_repository_impl.dart';
import 'package:canoto/data/repositories/customer_repository_impl.dart';

/// Màn hình quản lý xe
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _repository = VehicleRepositoryImpl.instance;
  final _searchController = TextEditingController();
  
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _showInactive = false;
  String _sortBy = 'licensePlate';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadVehicles() {
    setState(() {
      _vehicles = _showInactive ? _repository.getAll() : _repository.getActive();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    _filteredVehicles = _vehicles.where((v) {
      if (query.isEmpty) return true;
      return v.licensePlate.toLowerCase().contains(query) ||
          (v.driverName?.toLowerCase().contains(query) ?? false) ||
          (v.customerName?.toLowerCase().contains(query) ?? false) ||
          (v.vehicleType?.toLowerCase().contains(query) ?? false);
    }).toList();

    _filteredVehicles.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'licensePlate':
          result = a.licensePlate.compareTo(b.licensePlate);
          break;
        case 'customerName':
          result = (a.customerName ?? '').compareTo(b.customerName ?? '');
          break;
        case 'tareWeight':
          result = (a.tareWeight ?? 0).compareTo(b.tareWeight ?? 0);
          break;
        default:
          result = 0;
      }
      return _sortAsc ? result : -result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Xe'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Ẩn xe ngừng HĐ' : 'Hiện xe ngừng HĐ',
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
                _loadVehicles();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = value;
                  _sortAsc = true;
                }
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              _buildSortItem('licensePlate', 'Biển số'),
              _buildSortItem('customerName', 'Khách hàng'),
              _buildSortItem('tareWeight', 'Trọng lượng bì'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo biển số, tài xế, khách hàng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilters());
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _applyFilters()),
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatChip('Tổng: ${_repository.count}', Colors.blue),
                const SizedBox(width: 8),
                _buildStatChip('Hoạt động: ${_repository.activeCount}', Colors.green),
                const Spacer(),
                Text(
                  'Hiển thị: ${_filteredVehicles.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Vehicle list
          Expanded(
            child: _filteredVehicles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có xe nào'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _filteredVehicles[index];
                      return _VehicleListItem(
                        vehicle: vehicle,
                        onTap: () => _showVehicleDetail(vehicle),
                        onEdit: () => _showVehicleForm(vehicle),
                        onDelete: () => _deleteVehicle(vehicle),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVehicleForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm xe'),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(label),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  void _showVehicleDetail(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => _VehicleDetailDialog(vehicle: vehicle),
    );
  }

  void _showVehicleForm(Vehicle? vehicle) async {
    final result = await showDialog<Vehicle>(
      context: context,
      builder: (context) => _VehicleFormDialog(vehicle: vehicle),
    );

    if (result != null) {
      if (vehicle == null) {
        _repository.add(result);
      } else {
        _repository.update(result);
      }
      _loadVehicles();
    }
  }

  void _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa xe "${vehicle.licensePlate}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _repository.delete(vehicle.id!);
      _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa xe "${vehicle.licensePlate}"')),
        );
      }
    }
  }
}

/// Vehicle list item
class _VehicleListItem extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleListItem({
    required this.vehicle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 40,
          decoration: BoxDecoration(
            color: vehicle.isActive 
                ? Theme.of(context).colorScheme.primaryContainer 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: vehicle.isActive 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              _getVehicleIcon(vehicle.vehicleType),
              color: vehicle.isActive 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              vehicle.licensePlate,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: vehicle.isActive ? null : Colors.grey,
              ),
            ),
            if (!vehicle.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ngừng HĐ',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle.vehicleType != null)
              Text('${vehicle.vehicleType} • ${vehicle.brand ?? ""} ${vehicle.model ?? ""}'),
            if (vehicle.customerName != null)
              Text('KH: ${vehicle.customerName}', style: const TextStyle(fontSize: 12)),
            if (vehicle.tareWeight != null)
              Text(
                'Trọng lượng bì: ${vehicle.tareWeight!.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                onTap();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'xe tải':
      case 'xe tải nhỏ':
        return Icons.local_shipping;
      case 'xe ben':
        return Icons.fire_truck;
      case 'xe container':
        return Icons.view_in_ar;
      default:
        return Icons.directions_car;
    }
  }
}

/// Vehicle detail dialog
class _VehicleDetailDialog extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleDetailDialog({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.local_shipping),
          const SizedBox(width: 8),
          Expanded(child: Text(vehicle.licensePlate)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Loại xe', vehicle.vehicleType),
              _buildInfoRow('Hãng xe', vehicle.brand),
              _buildInfoRow('Model', vehicle.model),
              _buildInfoRow('Màu sắc', vehicle.color),
              _buildInfoRow('Trọng lượng bì', vehicle.tareWeight != null 
                  ? '${vehicle.tareWeight!.toStringAsFixed(0)} kg' 
                  : null),
              const Divider(),
              _buildInfoRow('Khách hàng', vehicle.customerName),
              _buildInfoRow('Tài xế', vehicle.driverName),
              _buildInfoRow('SĐT tài xế', vehicle.driverPhone),
              _buildInfoRow('Ghi chú', vehicle.note),
              const Divider(),
              _buildInfoRow('Trạng thái', vehicle.isActive ? 'Hoạt động' : 'Ngừng hoạt động'),
              _buildInfoRow('Ngày tạo', _formatDate(vehicle.createdAt)),
              _buildInfoRow('Cập nhật', _formatDate(vehicle.updatedAt)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Vehicle form dialog
class _VehicleFormDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const _VehicleFormDialog({this.vehicle});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licensePlateController;
  late final TextEditingController _tareWeightController;
  late final TextEditingController _driverNameController;
  late final TextEditingController _driverPhoneController;
  late final TextEditingController _noteController;
  
  String? _vehicleType;
  String? _brand;
  String? _color;
  int? _customerId;
  late bool _isActive;

  final _vehicleTypes = ['Xe tải', 'Xe tải nhỏ', 'Xe ben', 'Xe container', 'Xe bồn', 'Khác'];
  final _brands = ['Hyundai', 'Isuzu', 'Hino', 'Howo', 'Mercedes', 'Kia', 'Khác'];
  final _colors = ['Trắng', 'Xanh', 'Đỏ', 'Vàng', 'Xám', 'Đen', 'Khác'];

  bool get isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _licensePlateController = TextEditingController(text: v?.licensePlate ?? '');
    _tareWeightController = TextEditingController(text: v?.tareWeight?.toStringAsFixed(0) ?? '');
    _driverNameController = TextEditingController(text: v?.driverName ?? '');
    _driverPhoneController = TextEditingController(text: v?.driverPhone ?? '');
    _noteController = TextEditingController(text: v?.note ?? '');
    _vehicleType = v?.vehicleType;
    _brand = v?.brand;
    _color = v?.color;
    _customerId = v?.customerId;
    _isActive = v?.isActive ?? true;
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _tareWeightController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = CustomerRepositoryImpl.instance.getActive();
    
    return AlertDialog(
      title: Text(isEditing ? 'Sửa thông tin xe' : 'Thêm xe mới'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'Biển số xe *',
                    hintText: 'VD: 51C-12345',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Loại xe',
                          border: OutlineInputBorder(),
                        ),
                        items: _vehicleTypes.map((t) => 
                          DropdownMenuItem(value: t, child: Text(t))
                        ).toList(),
                        onChanged: (v) => setState(() => _vehicleType = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _brand,
                        decoration: const InputDecoration(
                          labelText: 'Hãng xe',
                          border: OutlineInputBorder(),
                        ),
                        items: _brands.map((b) => 
                          DropdownMenuItem(value: b, child: Text(b))
                        ).toList(),
                        onChanged: (v) => setState(() => _brand = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _color,
                        decoration: const InputDecoration(
                          labelText: 'Màu sắc',
                          border: OutlineInputBorder(),
                        ),
                        items: _colors.map((c) => 
                          DropdownMenuItem(value: c, child: Text(c))
                        ).toList(),
                        onChanged: (v) => setState(() => _color = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _tareWeightController,
                        decoration: const InputDecoration(
                          labelText: 'Trọng lượng bì (kg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _customerId,
                  decoration: const InputDecoration(
                    labelText: 'Khách hàng',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-- Chọn khách hàng --')),
                    ...customers.map((c) => 
                      DropdownMenuItem(value: c.id, child: Text(c.name))
                    ),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _driverNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên tài xế',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _driverPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'SĐT tài xế',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Đang hoạt động'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final customer = _customerId != null 
        ? CustomerRepositoryImpl.instance.getById(_customerId!) 
        : null;

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      vehicleType: _vehicleType,
      brand: _brand,
      color: _color,
      tareWeight: double.tryParse(_tareWeightController.text.trim()),
      customerId: _customerId,
      customerName: customer?.name,
      driverName: _driverNameController.text.trim().isEmpty ? null : _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim().isEmpty ? null : _driverPhoneController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isActive: _isActive,
      createdAt: widget.vehicle?.createdAt,
    );

    Navigator.pop(context, vehicle);
  }
}
