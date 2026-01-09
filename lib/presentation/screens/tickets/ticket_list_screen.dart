import 'package:flutter/material.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/repositories/weighing_ticket_sqlite_repository.dart';
import 'package:canoto/services/export/export_excel_service.dart';
import 'package:canoto/services/print/print_service.dart';

/// Màn hình danh sách phiếu cân
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String _searchText = '';
  String _statusFilter = 'all';
  
  // Dữ liệu thực từ database
  List<WeighingTicket> _allTickets = [];
  List<WeighingTicket> _filteredTickets = [];
  bool _isLoading = false;
  
  // Pagination
  int _currentPage = 1;
  int _pageSize = 50; // Có thể thay đổi
  bool _showAll = false; // Hiển thị tất cả không phân trang

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() async {
    setState(() => _isLoading = true);
    
    try {
      final tickets = await WeighingTicketSqliteRepository.instance.getAll();
      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredTickets = _allTickets.where((ticket) {
      // Lọc theo ngày
      final inDateRange = ticket.createdAt.isAfter(_fromDate.subtract(const Duration(days: 1))) &&
          ticket.createdAt.isBefore(_toDate.add(const Duration(days: 1)));
      
      // Lọc theo text search
      final matchesSearch = _searchText.isEmpty ||
          ticket.ticketNumber.toLowerCase().contains(_searchText.toLowerCase()) ||
          ticket.licensePlate.toLowerCase().contains(_searchText.toLowerCase()) ||
          (ticket.customerName?.toLowerCase().contains(_searchText.toLowerCase()) ?? false);
      
      // Lọc theo status
      final matchesStatus = _statusFilter == 'all' || ticket.status.value == _statusFilter;
      
      return inDateRange && matchesSearch && matchesStatus;
    }).toList();
    
    // Sắp xếp theo ngày giảm dần
    _filteredTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Reset về trang 1
    _currentPage = 1;
  }

  List<WeighingTicket> get _pageTickets {
    if (_showAll) return _filteredTickets;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= _filteredTickets.length) return [];
    return _filteredTickets.sublist(startIndex, endIndex.clamp(0, _filteredTickets.length));
  }

  int get _totalPages => _showAll ? 1 : (_filteredTickets.length / _pageSize).ceil();

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
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'pending', child: Text('Chờ cân')),
                      DropdownMenuItem(value: 'first_weighed', child: Text('Đã cân lần 1')),
                      DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _statusFilter = value;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  // Search button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _applyFilters());
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Tìm'),
                  ),
                ],
              ),
            ),
          ),
          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
              margin: const EdgeInsets.all(8),
              child: SingleChildScrollView(
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
          ),
          // Pagination
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Số phiếu mỗi trang
                  Row(
                    children: [
                      const Text('Hiển thị: '),
                      DropdownButton<int>(
                        value: _showAll ? -1 : _pageSize,
                        items: const [
                          DropdownMenuItem(value: 20, child: Text('20')),
                          DropdownMenuItem(value: 50, child: Text('50')),
                          DropdownMenuItem(value: 100, child: Text('100')),
                          DropdownMenuItem(value: 200, child: Text('200')),
                          DropdownMenuItem(value: -1, child: Text('Tất cả')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value == -1) {
                              _showAll = true;
                            } else {
                              _showAll = false;
                              _pageSize = value!;
                            }
                            _currentPage = 1;
                          });
                        },
                      ),
                      const Text(' phiếu/trang'),
                    ],
                  ),
                  // Thông tin & điều hướng
                  Row(
                    children: [
                      Text('Tổng: ${_filteredTickets.length} phiếu'),
                      if (!_showAll) ...[
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage = 1)
                              : null,
                          tooltip: 'Trang đầu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          tooltip: 'Trang trước',
                        ),
                        Text('Trang $_currentPage / ${_totalPages > 0 ? _totalPages : 1}'),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          tooltip: 'Trang sau',
                        ),
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          onPressed: _currentPage < _totalPages
                              ? () => setState(() => _currentPage = _totalPages)
                              : null,
                          tooltip: 'Trang cuối',
                        ),
                      ],
                    ],
                  ),
                  // Nút tạo phiếu mới
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _createNewTicket,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo phiếu mới'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildRows() {
    if (_pageTickets.isEmpty) {
      return [
        const DataRow(cells: [
          DataCell(Text('Không có dữ liệu', style: TextStyle(fontStyle: FontStyle.italic))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
        ]),
      ];
    }

    return _pageTickets.map((ticket) {
      final weighTime = ticket.firstWeightTime ?? ticket.createdAt;
      return DataRow(
        cells: [
          DataCell(Text(ticket.ticketNumber)),
          DataCell(Text(ticket.licensePlate)),
          DataCell(Text(ticket.customerName ?? '-')),
          DataCell(Text(ticket.productName ?? '-')),
          DataCell(Text(_formatWeight(ticket.firstWeight))),
          DataCell(Text(_formatWeight(ticket.secondWeight))),
          DataCell(Text(_formatWeight(ticket.netWeight))),
          DataCell(Text(_formatDateTime(weighTime))),
          DataCell(_buildStatusChip(ticket.status.value)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _viewTicket(ticket),
                  tooltip: 'Xem',
                ),
                IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  onPressed: () => _printTicket(ticket),
                  tooltip: 'In',
                ),
                if (ticket.isSynced)
                  const Icon(Icons.cloud_done, size: 18, color: Colors.green)
                else
                  const Icon(Icons.cloud_off, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  String _formatWeight(double? weight) {
    if (weight == null || weight == 0) return '-';
    return weight.toStringAsFixed(0);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
        _applyFilters();
      });
    }
  }

  void _exportExcel() async {
    if (_filteredTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất')),
      );
      return;
    }
    
    try {
      final excelService = ExportExcelService.instance;
      await excelService.exportWeighingTickets(tickets: _filteredTickets);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xuất file Excel'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _createNewTicket() {
    // Navigate to weighing screen
    Navigator.pushNamed(context, '/weighing');
  }

  void _viewTicket(WeighingTicket ticket) {
    // Show ticket details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phiếu cân: ${ticket.ticketNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Biển số', ticket.licensePlate),
              _buildDetailRow('Khách hàng', ticket.customerName ?? '-'),
              _buildDetailRow('Sản phẩm', ticket.productName ?? '-'),
              _buildDetailRow('Cân lần 1', '${ticket.firstWeight?.toStringAsFixed(0) ?? '-'} kg'),
              _buildDetailRow('Cân lần 2', '${ticket.secondWeight?.toStringAsFixed(0) ?? '-'} kg'),
              _buildDetailRow('Khối lượng', '${ticket.netWeight?.toStringAsFixed(0) ?? '-'} kg'),
              _buildDetailRow('Trạng thái', ticket.status.value),
              _buildDetailRow('Ghi chú', ticket.note ?? '-'),
              _buildDetailRow('Đồng bộ', ticket.isSynced ? 'Đã đồng bộ' : 'Chưa đồng bộ'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _printTicket(WeighingTicket ticket) async {
    try {
      final printService = PrintService.instance;
      await printService.printWeighingTicket(ticket);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang in phiếu...'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
