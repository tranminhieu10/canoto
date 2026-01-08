import 'package:flutter/material.dart';

/// Màn hình danh sách phiếu cân
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  // ignore: unused_field
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  // ignore: unused_field
  DateTime _toDate = DateTime.now();
  // ignore: unused_field
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phiếu cân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportExcel,
            tooltip: 'Xuất Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tìm kiếm',
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Biển số, số phiếu, khách hàng...',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date range picker
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status filter
                  DropdownButton<String>(
                    value: 'all',
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'pending', child: Text('Chờ cân')),
                      DropdownMenuItem(value: 'first_weighed', child: Text('Đã cân lần 1')),
                      DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                    ],
                    onChanged: (value) {
                      // Filter by status
                    },
                  ),
                ],
              ),
            ),
          ),
          // Data table
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Số phiếu')),
                    DataColumn(label: Text('Biển số')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Hàng hóa')),
                    DataColumn(label: Text('Cân lần 1'), numeric: true),
                    DataColumn(label: Text('Cân lần 2'), numeric: true),
                    DataColumn(label: Text('Khối lượng'), numeric: true),
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Trạng thái')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: _buildRows(),
                ),
              ),
            ),
          ),
          // Pagination
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Tổng: 100 phiếu'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {},
                  ),
                  const Text('Trang 1 / 10'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu mới'),
      ),
    );
  }

  List<DataRow> _buildRows() {
    // TODO: Replace with actual data
    return List.generate(
      10,
      (index) => DataRow(
        cells: [
          DataCell(Text('PC${1000 + index}')),
          DataCell(Text('51A-${12345 + index}')),
          DataCell(const Text('Công ty ABC')),
          DataCell(const Text('Thức ăn chăn nuôi')),
          DataCell(Text('${25000 + index * 100}')),
          DataCell(Text('${10000 + index * 50}')),
          DataCell(Text('${15000 + index * 50}')),
          const DataCell(Text('07/01/2026 08:30')),
          DataCell(_buildStatusChip('completed')),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _viewTicket(index),
                  tooltip: 'Xem',
                ),
                IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  onPressed: () => _printTicket(index),
                  tooltip: 'In',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editTicket(index),
                  tooltip: 'Sửa',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Chờ cân';
        break;
      case 'first_weighed':
        color = Colors.blue;
        label = 'Đã cân lần 1';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Hoàn thành';
        break;
      default:
        color = Colors.grey;
        label = 'Không xác định';
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _loadTickets() {
    // TODO: Load tickets from database
  }

  void _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
      _loadTickets();
    }
  }

  void _exportExcel() {
    // TODO: Export to Excel
  }

  void _createNewTicket() {
    // TODO: Navigate to create ticket screen
  }

  void _viewTicket(int index) {
    // TODO: View ticket details
  }

  void _printTicket(int index) {
    // TODO: Print ticket
  }

  void _editTicket(int index) {
    // TODO: Edit ticket
  }
}
