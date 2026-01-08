import 'package:flutter/material.dart';
import 'package:canoto/data/models/customer.dart';
import 'package:canoto/data/repositories/customer_repository_impl.dart';

/// Màn hình quản lý khách hàng
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repository = CustomerRepositoryImpl.instance;
  final _searchController = TextEditingController();
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _showInactive = false;
  String _sortBy = 'name';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCustomers() {
    setState(() {
      _customers = _showInactive ? _repository.getAll() : _repository.getActive();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    _filteredCustomers = _customers.where((c) {
      if (query.isEmpty) return true;
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          (c.phone?.contains(query) ?? false) ||
          (c.contactPerson?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sort
    _filteredCustomers.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'code':
          result = a.code.compareTo(b.code);
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'createdAt':
          result = a.createdAt.compareTo(b.createdAt);
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
        title: const Text('Quản lý Khách hàng'),
        actions: [
          // Toggle inactive
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Ẩn ngừng hoạt động' : 'Hiện ngừng hoạt động',
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
                _loadCustomers();
              });
            },
          ),
          // Sort menu
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
              _buildSortItem('code', 'Mã KH'),
              _buildSortItem('name', 'Tên'),
              _buildSortItem('createdAt', 'Ngày tạo'),
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
                hintText: 'Tìm kiếm theo mã, tên, SĐT...',
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
                _buildStatChip(
                  'Tổng: ${_repository.count}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Hoạt động: ${_repository.activeCount}',
                  Colors.green,
                ),
                const Spacer(),
                Text(
                  'Hiển thị: ${_filteredCustomers.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Customer list
          Expanded(
            child: _filteredCustomers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có khách hàng nào'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return _CustomerListItem(
                        customer: customer,
                        onTap: () => _showCustomerDetail(customer),
                        onEdit: () => _showCustomerForm(customer),
                        onDelete: () => _deleteCustomer(customer),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm KH'),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showCustomerDetail(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerDetailDialog(customer: customer),
    );
  }

  void _showCustomerForm(Customer? customer) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => _CustomerFormDialog(customer: customer),
    );

    if (result != null) {
      if (customer == null) {
        _repository.add(result);
      } else {
        _repository.update(result);
      }
      _loadCustomers();
    }
  }

  void _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khách hàng "${customer.name}"?'),
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
      _repository.delete(customer.id!);
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa "${customer.name}"')),
        );
      }
    }
  }
}

/// Customer list item widget
class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerListItem({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: customer.isActive 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              customer.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: customer.isActive ? null : Colors.grey,
              ),
            ),
            if (!customer.isActive) ...[
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
            Text('Mã: ${customer.code}'),
            if (customer.phone != null)
              Text('SĐT: ${customer.phone}'),
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
        isThreeLine: customer.phone != null,
      ),
    );
  }
}

/// Customer detail dialog
class _CustomerDetailDialog extends StatelessWidget {
  final Customer customer;

  const _CustomerDetailDialog({required this.customer});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person),
          const SizedBox(width: 8),
          Expanded(child: Text(customer.name)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Mã KH', customer.code),
              _buildInfoRow('Người liên hệ', customer.contactPerson),
              _buildInfoRow('Điện thoại', customer.phone),
              _buildInfoRow('Email', customer.email),
              _buildInfoRow('Địa chỉ', customer.address),
              _buildInfoRow('Mã số thuế', customer.taxCode),
              _buildInfoRow('Số TK ngân hàng', customer.bankAccount),
              _buildInfoRow('Ngân hàng', customer.bankName),
              _buildInfoRow('Ghi chú', customer.note),
              const Divider(),
              _buildInfoRow('Trạng thái', customer.isActive ? 'Hoạt động' : 'Ngừng hoạt động'),
              _buildInfoRow('Ngày tạo', _formatDate(customer.createdAt)),
              _buildInfoRow('Cập nhật', _formatDate(customer.updatedAt)),
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

/// Customer form dialog
class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const _CustomerFormDialog({this.customer});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _bankAccountController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _noteController;
  late bool _isActive;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _codeController = TextEditingController(text: c?.code ?? _generateCode());
    _nameController = TextEditingController(text: c?.name ?? '');
    _contactController = TextEditingController(text: c?.contactPerson ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _taxCodeController = TextEditingController(text: c?.taxCode ?? '');
    _bankAccountController = TextEditingController(text: c?.bankAccount ?? '');
    _bankNameController = TextEditingController(text: c?.bankName ?? '');
    _noteController = TextEditingController(text: c?.note ?? '');
    _isActive = c?.isActive ?? true;
  }

  String _generateCode() {
    final count = CustomerRepositoryImpl.instance.count + 1;
    return 'KH${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxCodeController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Sửa khách hàng' : 'Thêm khách hàng mới'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã KH *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên khách hàng *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Người liên hệ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã số thuế',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ngân hàng',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankAccountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    border: OutlineInputBorder(),
                  ),
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

    final customer = Customer(
      id: widget.customer?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      contactPerson: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      taxCode: _taxCodeController.text.trim().isEmpty ? null : _taxCodeController.text.trim(),
      bankAccount: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
      bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isActive: _isActive,
      createdAt: widget.customer?.createdAt,
    );

    Navigator.pop(context, customer);
  }
}
