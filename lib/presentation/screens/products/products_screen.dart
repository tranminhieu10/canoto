import 'package:flutter/material.dart';
import 'package:canoto/data/models/product.dart';
import 'package:canoto/data/repositories/product_repository_impl.dart';

/// Màn hình quản lý hàng hóa/sản phẩm
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repository = ProductRepositoryImpl.instance;
  final _searchController = TextEditingController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _showInactive = false;
  String? _selectedCategory;
  String _sortBy = 'name';
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _products = _showInactive ? _repository.getAll() : _repository.getActive();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    _filteredProducts = _products.where((p) {
      // Category filter
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      // Search filter
      if (query.isEmpty) return true;
      return p.code.toLowerCase().contains(query) ||
          p.name.toLowerCase().contains(query) ||
          (p.category?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sort
    _filteredProducts.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'code':
          result = a.code.compareTo(b.code);
          break;
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'category':
          result = (a.category ?? '').compareTo(b.category ?? '');
          break;
        case 'unitPrice':
          result = (a.unitPrice ?? 0).compareTo(b.unitPrice ?? 0);
          break;
        default:
          result = 0;
      }
      return _sortAsc ? result : -result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _repository.getCategories();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Hàng hóa'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Ẩn ngừng HĐ' : 'Hiện ngừng HĐ',
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
                _loadProducts();
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
              _buildSortItem('code', 'Mã SP'),
              _buildSortItem('name', 'Tên'),
              _buildSortItem('category', 'Danh mục'),
              _buildSortItem('unitPrice', 'Đơn giá'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...categories.map((c) => 
                        DropdownMenuItem(value: c, child: Text(c))
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
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
                  'Hiển thị: ${_filteredProducts.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Product grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có hàng hóa nào'),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200 
                          ? 4 
                          : constraints.maxWidth > 800 
                              ? 3 
                              : 2;
                      
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _ProductCard(
                            product: product,
                            onTap: () => _showProductDetail(product),
                            onEdit: () => _showProductForm(product),
                            onDelete: () => _deleteProduct(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm hàng'),
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

  void _showProductDetail(Product product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDetailDialog(product: product),
    );
  }

  void _showProductForm(Product? product) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );

    if (result != null) {
      if (product == null) {
        _repository.add(result);
      } else {
        _repository.update(result);
      }
      _loadProducts();
    }
  }

  void _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
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
      _repository.delete(product.id!);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa "${product.name}"')),
        );
      }
    }
  }
}

/// Product card widget
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(product.category),
                          color: _getCategoryColor(product.category),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.code,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: product.isActive ? null : Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Category
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(product.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(product.category),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.unitPrice != null)
                        Text(
                          '${_formatCurrency(product.unitPrice!)}/${product.unit ?? 'kg'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        )
                      else
                        const Text(
                          'Chưa có giá',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
                icon: const Icon(Icons.more_vert, size: 20),
              ),
            ),
            
            // Inactive badge
            if (!product.isActive)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ngừng HĐ',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'thủy sản':
        return Colors.blue;
      case 'nông sản':
        return Colors.green;
      case 'phụ phẩm':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'thủy sản':
        return Icons.set_meal;
      case 'nông sản':
        return Icons.grass;
      case 'phụ phẩm':
        return Icons.recycling;
      default:
        return Icons.inventory;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// Product detail dialog
class _ProductDetailDialog extends StatelessWidget {
  final Product product;

  const _ProductDetailDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.inventory_2),
          const SizedBox(width: 8),
          Expanded(child: Text(product.name)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Mã SP', product.code),
              _buildInfoRow('Danh mục', product.category),
              _buildInfoRow('Đơn vị', product.unit),
              _buildInfoRow('Đơn giá', product.unitPrice != null 
                  ? _formatCurrency(product.unitPrice!) 
                  : null),
              _buildInfoRow('Mô tả', product.description),
              const Divider(),
              _buildInfoRow('Trạng thái', product.isActive ? 'Hoạt động' : 'Ngừng hoạt động'),
              _buildInfoRow('Ngày tạo', _formatDate(product.createdAt)),
              _buildInfoRow('Cập nhật', _formatDate(product.updatedAt)),
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
            width: 100,
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

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Product form dialog
class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _descriptionController;
  
  String? _category;
  String? _unit;
  late bool _isActive;

  final _categories = ['Thủy sản', 'Nông sản', 'Phụ phẩm', 'Khác'];
  final _units = ['kg', 'tấn', 'con', 'thùng', 'bao', 'cái'];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeController = TextEditingController(text: p?.code ?? _generateCode());
    _nameController = TextEditingController(text: p?.name ?? '');
    _unitPriceController = TextEditingController(text: p?.unitPrice?.toStringAsFixed(0) ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _category = p?.category;
    _unit = p?.unit ?? 'kg';
    _isActive = p?.isActive ?? true;
  }

  String _generateCode() {
    final count = ProductRepositoryImpl.instance.count + 1;
    return 'SP${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Sửa hàng hóa' : 'Thêm hàng hóa mới'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã SP *',
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
                          labelText: 'Tên hàng hóa *',
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
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((c) => 
                          DropdownMenuItem(value: c, child: Text(c))
                        ).toList(),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị tính',
                          border: OutlineInputBorder(),
                        ),
                        items: _units.map((u) => 
                          DropdownMenuItem(value: u, child: Text(u))
                        ).toList(),
                        onChanged: (v) => setState(() => _unit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn giá (VNĐ)',
                    border: OutlineInputBorder(),
                    suffixText: 'đ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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

    final product = Product(
      id: widget.product?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      category: _category,
      unit: _unit,
      unitPrice: double.tryParse(_unitPriceController.text.trim()),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      isActive: _isActive,
      createdAt: widget.product?.createdAt,
    );

    Navigator.pop(context, product);
  }
}
