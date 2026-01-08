import 'package:flutter/material.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/models/enums/weighing_enums.dart';
import 'package:canoto/data/repositories/weighing_ticket_repository_impl.dart';

/// Màn hình báo cáo thống kê
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = WeighingTicketRepositoryImpl.instance;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<WeighingTicket> _tickets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          return t.createdAt.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.createdAt.isBefore(_endDate.add(const Duration(days: 1)));
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
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Theo ngày'),
            Tab(icon: Icon(Icons.people), text: 'Khách hàng'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Xe'),
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
                    ],
                  ),
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

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang chuẩn bị báo cáo để in...')),
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
}
