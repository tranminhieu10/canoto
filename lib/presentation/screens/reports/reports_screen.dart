import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/models/enums/weighing_enums.dart';
import 'package:canoto/data/repositories/weighing_ticket_sqlite_repository.dart';

/// Màn hình báo cáo thống kê
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = WeighingTicketSqliteRepository.instance;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<WeighingTicket> _tickets = [];
  bool _isLoading = false;
  
  // Bộ lọc tìm kiếm
  String? _filterCustomer;
  String? _filterVehicle;
  String? _filterProduct;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      final allTickets = await _repository.getAll();
      setState(() {
        _tickets = allTickets.where((t) {
          // Date filter
          if (!t.createdAt.isAfter(_startDate.subtract(const Duration(days: 1))) ||
              !t.createdAt.isBefore(_endDate.add(const Duration(days: 1)))) {
            return false;
          }
          // Customer filter
          if (_filterCustomer != null && t.customerName != _filterCustomer) {
            return false;
          }
          // Vehicle filter
          if (_filterVehicle != null && t.licensePlate != _filterVehicle) {
            return false;
          }
          // Product filter
          if (_filterProduct != null && t.productName != _filterProduct) {
            return false;
          }
          // Search filter
          final query = _searchController.text.toLowerCase();
          if (query.isNotEmpty) {
            return t.ticketNumber.toLowerCase().contains(query) ||
                t.licensePlate.toLowerCase().contains(query) ||
                (t.customerName?.toLowerCase().contains(query) ?? false) ||
                (t.productName?.toLowerCase().contains(query) ?? false) ||
                (t.driverName?.toLowerCase().contains(query) ?? false);
          }
          return true;
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Theo ngày'),
            Tab(icon: Icon(Icons.people), text: 'Khách hàng'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Xe'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Hàng hóa'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Chọn khoảng thời gian',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'In báo cáo',
            onPressed: _printReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Từ ${_formatDate(_startDate)} đến ${_formatDate(_endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Đổi'),
                ),
              ],
            ),
          ),
          
          // Search and filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã phiếu, biển số, khách hàng, hàng hóa...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadData();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Badge(
                    isLabelVisible: _hasActiveFilters,
                    child: const Icon(Icons.filter_list),
                  ),
                  tooltip: 'Bộ lọc nâng cao',
                  onPressed: _showAdvancedFilters,
                ),
              ],
            ),
          ),
          
          // Active filters chips
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_filterCustomer != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('KH: $_filterCustomer'),
                        onDeleted: () {
                          setState(() => _filterCustomer = null);
                          _loadData();
                        },
                      ),
                    ),
                  if (_filterVehicle != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Xe: $_filterVehicle'),
                        onDeleted: () {
                          setState(() => _filterVehicle = null);
                          _loadData();
                        },
                      ),
                    ),
                  if (_filterProduct != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('HH: $_filterProduct'),
                        onDeleted: () {
                          setState(() => _filterProduct = null);
                          _loadData();
                        },
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Xóa tất cả'),
                  ),
                ],
              ),
            ),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDailyTab(),
                      _buildCustomerTab(),
                      _buildVehicleTab(),
                      _buildProductTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters => 
      _filterCustomer != null || 
      _filterVehicle != null || 
      _filterProduct != null;

  void _clearAllFilters() {
    setState(() {
      _filterCustomer = null;
      _filterVehicle = null;
      _filterProduct = null;
      _searchController.clear();
    });
    _loadData();
  }

  void _showAdvancedFilters() async {
    // Lấy danh sách unique từ tickets
    final customers = _tickets.map((t) => t.customerName).whereType<String>().toSet().toList()..sort();
    final vehicles = _tickets.map((t) => t.licensePlate).toSet().toList()..sort();
    final products = _tickets.map((t) => t.productName).whereType<String>().toSet().toList()..sort();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc nâng cao'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _filterCustomer,
                decoration: const InputDecoration(
                  labelText: 'Khách hàng',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...customers.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _filterCustomer = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _filterVehicle,
                decoration: const InputDecoration(
                  labelText: 'Biển số xe',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                ],
                onChanged: (v) => setState(() => _filterVehicle = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _filterProduct,
                decoration: const InputDecoration(
                  labelText: 'Hàng hóa',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ...products.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                ],
                onChanged: (v) => setState(() => _filterProduct = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearAllFilters();
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  /// Tab Tổng quan
  Widget _buildOverviewTab() {
    final completedTickets = _tickets.where((t) => t.status == WeighingStatus.completed).toList();
    final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
    final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
    
    final incoming = _tickets.where((t) => t.weighingType == WeighingType.incoming).length;
    final outgoing = _tickets.where((t) => t.weighingType == WeighingType.outgoing).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                'Tổng phiếu cân',
                _tickets.length.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Đã hoàn thành',
                completedTickets.length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildSummaryCard(
                'Tổng KL (tấn)',
                (totalWeight / 1000).toStringAsFixed(1),
                Icons.scale,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Tổng tiền',
                _formatCurrencyShort(totalAmount),
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Weighing type breakdown
          Text(
            'Phân loại phiếu cân',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTypeCard('Cân vào', incoming, Colors.green, Icons.arrow_downward),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeCard('Cân ra', outgoing, Colors.red, Icons.arrow_upward),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Status breakdown
          Text(
            'Trạng thái phiếu cân',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildStatusBreakdown(),
          
          const SizedBox(height: 24),
          
          // Recent tickets
          Text(
            'Phiếu cân gần đây',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildRecentTicketsList(),
        ],
      ),
    );
  }

  /// Tab Theo ngày
  Widget _buildDailyTab() {
    // Group by date
    final Map<String, List<WeighingTicket>> groupedByDate = {};
    for (final ticket in _tickets) {
      final dateKey = _formatDate(ticket.createdAt);
      groupedByDate.putIfAbsent(dateKey, () => []).add(ticket);
    }
    
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTickets = groupedByDate[date]!;
        final completedTickets = dayTickets.where((t) => t.status == WeighingStatus.completed);
        final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  date.split('/')[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${dayTickets.length} phiếu • ${(totalWeight / 1000).toStringAsFixed(2)} tấn'),
            trailing: Text(
              _formatCurrencyShort(totalAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            children: dayTickets.map((t) => _buildTicketListTile(t)).toList(),
          ),
        );
      },
    );
  }

  /// Tab Khách hàng
  Widget _buildCustomerTab() {
    // Group by customer
    final Map<String, List<WeighingTicket>> groupedByCustomer = {};
    for (final ticket in _tickets) {
      final customerKey = ticket.customerName ?? 'Không xác định';
      groupedByCustomer.putIfAbsent(customerKey, () => []).add(ticket);
    }
    
    final sortedCustomers = groupedByCustomer.entries.toList()
      ..sort((a, b) {
        final aWeight = a.value.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final bWeight = b.value.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        return bWeight.compareTo(aWeight);
      });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCustomers.length,
      itemBuilder: (context, index) {
        final entry = sortedCustomers[index];
        final customerTickets = entry.value;
        final completedTickets = customerTickets.where((t) => t.status == WeighingStatus.completed);
        final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${customerTickets.length} phiếu cân'),
                Text(
                  'Tổng KL: ${(totalWeight / 1000).toStringAsFixed(2)} tấn',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrencyShort(totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${((totalWeight / _tickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0))) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  /// Tab Xe
  Widget _buildVehicleTab() {
    // Group by vehicle
    final Map<String, List<WeighingTicket>> groupedByVehicle = {};
    for (final ticket in _tickets) {
      groupedByVehicle.putIfAbsent(ticket.licensePlate, () => []).add(ticket);
    }
    
    final sortedVehicles = groupedByVehicle.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedVehicles.length,
      itemBuilder: (context, index) {
        final entry = sortedVehicles[index];
        final vehicleTickets = entry.value;
        final completedTickets = vehicleTickets.where((t) => t.status == WeighingStatus.completed);
        final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text('${vehicleTickets.length} lượt cân'),
            subtitle: Text('Tổng KL: ${(totalWeight / 1000).toStringAsFixed(2)} tấn'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => _showVehicleDetail(entry.key, vehicleTickets),
          ),
        );
      },
    );
  }

  /// Tab Hàng hóa/Sản phẩm
  Widget _buildProductTab() {
    // Group by product
    final Map<String, List<WeighingTicket>> groupedByProduct = {};
    for (final ticket in _tickets) {
      final productKey = ticket.productName ?? 'Không xác định';
      groupedByProduct.putIfAbsent(productKey, () => []).add(ticket);
    }
    
    final sortedProducts = groupedByProduct.entries.toList()
      ..sort((a, b) {
        final aWeight = a.value.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final bWeight = b.value.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        return bWeight.compareTo(aWeight);
      });
    
    if (sortedProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có dữ liệu hàng hóa', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final entry = sortedProducts[index];
        final productTickets = entry.value;
        final completedTickets = productTickets.where((t) => t.status == WeighingStatus.completed);
        final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
        final totalAllWeight = _tickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
        final percentage = totalAllWeight > 0 ? (totalWeight / totalAllWeight) * 100 : 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getProductColor(index),
              child: Icon(
                _getProductIcon(entry.key),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${productTickets.length} phiếu cân'),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(_getProductColor(index)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(totalWeight / 1000).toStringAsFixed(2)} tấn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (totalAmount > 0)
                  Text(
                    _formatCurrencyShort(totalAmount),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _showProductDetail(entry.key, productTickets),
          ),
        );
      },
    );
  }

  Color _getProductColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  IconData _getProductIcon(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('cá') || lower.contains('fish')) return Icons.set_meal;
    if (lower.contains('tôm') || lower.contains('shrimp')) return Icons.water;
    if (lower.contains('thức ăn') || lower.contains('feed')) return Icons.grass;
    if (lower.contains('phân') || lower.contains('fertilizer')) return Icons.eco;
    return Icons.inventory_2;
  }

  void _showProductDetail(String productName, List<WeighingTicket> tickets) {
    final completedTickets = tickets.where((t) => t.status == WeighingStatus.completed).toList();
    final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
    final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
    final avgWeight = completedTickets.isNotEmpty ? totalWeight / completedTickets.length : 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_2),
            const SizedBox(width: 8),
            Expanded(child: Text(productName)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tổng phiếu cân:', '${tickets.length}'),
              _buildDetailRow('Hoàn thành:', '${completedTickets.length}'),
              _buildDetailRow('Tổng khối lượng:', '${(totalWeight / 1000).toStringAsFixed(2)} tấn'),
              _buildDetailRow('KL trung bình:', '${avgWeight.toStringAsFixed(0)} kg/phiếu'),
              _buildDetailRow('Tổng tiền:', _formatCurrency(totalAmount)),
              const Divider(),
              const Text('Khách hàng mua nhiều nhất:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._getTopCustomersForProduct(tickets).take(3).map((e) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• ${e.key}: ${(e.value / 1000).toStringAsFixed(2)} tấn'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _getTopCustomersForProduct(List<WeighingTicket> tickets) {
    final Map<String, double> customerWeights = {};
    for (final ticket in tickets) {
      final customer = ticket.customerName ?? 'Không xác định';
      customerWeights[customer] = (customerWeights[customer] ?? 0) + (ticket.netWeight ?? 0);
    }
    final sorted = customerWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(title, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final pending = _tickets.where((t) => t.status == WeighingStatus.pending).length;
    final firstWeighed = _tickets.where((t) => t.status == WeighingStatus.firstWeighed).length;
    final completed = _tickets.where((t) => t.status == WeighingStatus.completed).length;
    final cancelled = _tickets.where((t) => t.status == WeighingStatus.cancelled).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusRow('Chờ xử lý', pending, Colors.orange),
            const Divider(),
            _buildStatusRow('Đã cân lần 1', firstWeighed, Colors.blue),
            const Divider(),
            _buildStatusRow('Hoàn thành', completed, Colors.green),
            const Divider(),
            _buildStatusRow('Đã hủy', cancelled, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    final percentage = _tickets.isEmpty ? 0.0 : (count / _tickets.length);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTicketsList() {
    final recentTickets = _tickets.take(5).toList();
    
    return Card(
      child: Column(
        children: recentTickets.map((t) => _buildTicketListTile(t)).toList(),
      ),
    );
  }

  Widget _buildTicketListTile(WeighingTicket ticket) {
    Color statusColor;
    switch (ticket.status) {
      case WeighingStatus.completed:
        statusColor = Colors.green;
        break;
      case WeighingStatus.firstWeighed:
        statusColor = Colors.blue;
        break;
      case WeighingStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }
    
    return ListTile(
      leading: Container(
        width: 8,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(ticket.ticketNumber),
      subtitle: Text('${ticket.licensePlate} • ${ticket.customerName ?? "N/A"}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            ticket.netWeight != null 
                ? '${ticket.netWeight!.toStringAsFixed(0)} kg' 
                : '--',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _formatTime(ticket.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _printReport() async {
    if (_tickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để in báo cáo')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang chuẩn bị báo cáo...')),
    );
    
    try {
      final pdf = await _generateReportPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: 'BaoCao_${_formatDate(_startDate)}_${_formatDate(_endDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in báo cáo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<Uint8List> _generateReportPdf() async {
    final pdf = pw.Document();
    
    // Thống kê
    final completedTickets = _tickets.where((t) => t.status == WeighingStatus.completed).toList();
    final totalWeight = completedTickets.fold<double>(0, (sum, t) => sum + (t.netWeight ?? 0));
    final totalAmount = completedTickets.fold<double>(0, (sum, t) => sum + (t.totalAmount ?? 0));
    final incoming = _tickets.where((t) => t.weighingType == WeighingType.incoming).length;
    final outgoing = _tickets.where((t) => t.weighingType == WeighingType.outgoing).length;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'BÁO CÁO THỐNG KÊ CÂN XE',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Từ ${_formatDate(_startDate)} đến ${_formatDate(_endDate)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
          ],
        ),
        build: (context) => [
          // Tổng quan
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfStatItem('Tổng phiếu cân', _tickets.length.toString()),
                _buildPdfStatItem('Hoàn thành', completedTickets.length.toString()),
                _buildPdfStatItem('Tổng KL (tấn)', (totalWeight / 1000).toStringAsFixed(2)),
                _buildPdfStatItem('Tổng tiền', _formatCurrencyShort(totalAmount)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          
          // Phân loại
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('CÂN VÀO', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(incoming.toString(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('CÂN RA', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(outgoing.toString(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          
          // Bảng chi tiết
          pw.Text('DANH SÁCH PHIỀU CÂN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildPdfTableHeader('Số phiếu'),
                  _buildPdfTableHeader('Biển số'),
                  _buildPdfTableHeader('Khách hàng'),
                  _buildPdfTableHeader('Cân 1 (kg)'),
                  _buildPdfTableHeader('Cân 2 (kg)'),
                  _buildPdfTableHeader('KL (kg)'),
                ],
              ),
              // Data rows
              ..._tickets.take(50).map((t) => pw.TableRow(
                children: [
                  _buildPdfTableCell(t.ticketNumber),
                  _buildPdfTableCell(t.licensePlate),
                  _buildPdfTableCell(t.customerName ?? '-'),
                  _buildPdfTableCell(t.firstWeight?.toStringAsFixed(0) ?? '-'),
                  _buildPdfTableCell(t.secondWeight?.toStringAsFixed(0) ?? '-'),
                  _buildPdfTableCell(t.netWeight?.toStringAsFixed(0) ?? '-'),
                ],
              )),
            ],
          ),
          
          if (_tickets.length > 50)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                '... và ${_tickets.length - 50} phiếu khác',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Trang ${context.pageNumber}/${context.pagesCount} - In lúc: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );
    
    return pdf.save();
  }
  
  pw.Widget _buildPdfStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }
  
  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
    );
  }
  
  pw.Widget _buildPdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
    );
  }

  void _showVehicleDetail(String licensePlate, List<WeighingTicket> tickets) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết xe $licensePlate'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) => _buildTicketListTile(tickets[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    final length = formatted.length;
    for (int i = 0; i < length; i++) {
      buffer.write(formatted[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()} đ';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
