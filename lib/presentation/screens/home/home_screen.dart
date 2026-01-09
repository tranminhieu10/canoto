import 'package:flutter/material.dart';
import 'dart:async';
import 'package:canoto/presentation/screens/weighing/weighing_screen_new.dart';
import 'package:canoto/presentation/screens/tickets/ticket_list_screen.dart';
import 'package:canoto/presentation/screens/settings/settings_screen.dart';
import 'package:canoto/presentation/screens/customers/customers_screen.dart';
import 'package:canoto/presentation/screens/vehicles/vehicles_screen.dart';
import 'package:canoto/presentation/screens/products/products_screen.dart';
import 'package:canoto/presentation/screens/reports/reports_screen.dart';
import 'package:canoto/data/repositories/weighing_ticket_sqlite_repository.dart';
import 'package:canoto/services/scale/scale_service_manager.dart';
import 'package:canoto/services/signalr/signalr_service.dart';
import 'package:canoto/services/camera/camera_manager.dart';

/// Màn hình chính - Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.scale_outlined),
                selectedIcon: Icon(Icons.scale),
                label: Text('Cân xe'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Phiếu cân'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Khách hàng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Xe'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Hàng hóa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Báo cáo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Cài đặt'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardContent(onNavigate: _navigateTo);
      case 1:
        return const WeighingScreenNew();
      case 2:
        return const TicketListScreen();
      case 3:
        return const CustomersScreen();
      case 4:
        return const VehiclesScreen();
      case 5:
        return const ProductsScreen();
      case 6:
        return const ReportsScreen();
      case 7:
        return const SettingsScreen();
      default:
        return _DashboardContent(onNavigate: _navigateTo);
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _DashboardContent extends StatefulWidget {
  final Function(int)? onNavigate;

  const _DashboardContent({this.onNavigate});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  // Số liệu thống kê thực từ database
  int _todayTicketCount = 0;
  double _todayTotalWeight = 0;
  int _incomingCount = 0;
  int _outgoingCount = 0;
  int _pendingCount = 0;
  int _syncedCount = 0;
  bool _isLoading = true;

  // Trạng thái kết nối thiết bị
  bool _isScaleConnected = false;
  bool _isCameraConnected = false;
  bool _isAzureSyncConnected = false;
  bool _isVisionMasterConnected = false;

  // Subscriptions
  StreamSubscription? _scaleStatusSubscription;
  StreamSubscription? _signalRSubscription;
  StreamSubscription? _cameraSubscription;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _setupDeviceStatusListeners();
    
    // Refresh trạng thái thiết bị mỗi 2 giây
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _updateDeviceStatus();
      }
    });
  }

  @override
  void dispose() {
    _scaleStatusSubscription?.cancel();
    _signalRSubscription?.cancel();
    _cameraSubscription?.cancel();
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  void _updateDeviceStatus() {
    final scaleConnected = ScaleServiceManager.instance.isConnected;
    final azureConnected = SignalRService.instance.isConnected;
    final cameraConnected = CameraManager.instance.isConnected;
    
    if (_isScaleConnected != scaleConnected || 
        _isAzureSyncConnected != azureConnected ||
        _isCameraConnected != cameraConnected) {
      setState(() {
        _isScaleConnected = scaleConnected;
        _isAzureSyncConnected = azureConnected;
        _isCameraConnected = cameraConnected;
      });
    }
  }

  void _setupDeviceStatusListeners() {
    // Kiểm tra trạng thái ban đầu ngay lập tức (sync)
    _isScaleConnected = ScaleServiceManager.instance.isConnected;
    _isAzureSyncConnected = SignalRService.instance.isConnected;
    _isCameraConnected = CameraManager.instance.isConnected;

    // Lắng nghe trạng thái cân
    _scaleStatusSubscription = ScaleServiceManager.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isScaleConnected = status.isOk;
        });
      }
    });

    // Lắng nghe trạng thái SignalR
    _signalRSubscription = SignalRService.instance.connectionStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAzureSyncConnected = state == SignalRConnectionState.connected;
        });
      }
    });

    // Lắng nghe trạng thái Camera
    _cameraSubscription = CameraManager.instance.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isCameraConnected = connected;
        });
      }
    });

    // Kiểm tra trạng thái đầy đủ
    _checkDeviceStatus();
  }

  Future<void> _checkDeviceStatus() async {
    if (mounted) {
      setState(() {
        // Luôn lấy trạng thái thực từ service
        _isScaleConnected = ScaleServiceManager.instance.isConnected;
        _isCameraConnected = CameraManager.instance.isConnected;
        _isAzureSyncConnected = SignalRService.instance.isConnected;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = WeighingTicketSqliteRepository.instance;
      
      // Lấy tất cả phiếu cân
      final allTickets = await repo.getAll();
      
      // Lọc phiếu cân trong ngày hôm nay
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayTickets = allTickets.where((t) => 
        t.createdAt.isAfter(startOfDay) || 
        t.createdAt.isAtSameMomentAs(startOfDay)
      ).toList();
      
      // Tính toán thống kê
      int incoming = 0;
      int outgoing = 0;
      int pending = 0;
      int synced = 0;
      double totalWeight = 0;
      
      for (final ticket in todayTickets) {
        // Đếm theo loại
        if (ticket.weighingType.value == 'incoming') {
          incoming++;
        } else if (ticket.weighingType.value == 'outgoing') {
          outgoing++;
        }
        
        // Đếm phiếu chưa hoàn thành
        if (ticket.status.value == 'pending' || ticket.status.value == 'first_weighed') {
          pending++;
        }
        
        // Đếm phiếu đã đồng bộ
        if (ticket.isSynced) {
          synced++;
        }
        
        // Tổng khối lượng
        totalWeight += ticket.netWeight ?? 0;
      }
      
      if (mounted) {
        setState(() {
          _todayTicketCount = todayTickets.length;
          _todayTotalWeight = totalWeight;
          _incomingCount = incoming;
          _outgoingCount = outgoing;
          _pendingCount = pending;
          _syncedCount = synced;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatWeight(double weight) {
    if (weight >= 1000) {
      return '${(weight / 1000).toStringAsFixed(2)} tấn';
    }
    return '${weight.toStringAsFixed(0)} kg';
  }

  Future<void> _refreshAll() async {
    await _checkDeviceStatus();
    await _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshAll,
                    tooltip: 'Làm mới',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Status cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatusCard(
                    context,
                    title: 'Đầu cân',
                    status: _isScaleConnected ? 'Đã kết nối' : 'Chưa kết nối',
                    icon: Icons.scale,
                    color: _isScaleConnected ? Colors.green : Colors.grey,
                  ),
                  _buildStatusCard(
                    context,
                    title: 'Camera',
                    status: _isCameraConnected ? 'Đang hoạt động' : 'Chưa kết nối',
                    icon: Icons.videocam,
                    color: _isCameraConnected ? Colors.green : Colors.grey,
                  ),
                  _buildStatusCard(
                    context,
                    title: 'Azure Sync',
                    status: _isAzureSyncConnected 
                        ? (_syncedCount > 0 ? 'Đã đồng bộ $_syncedCount phiếu' : 'Đã kết nối') 
                        : 'Chưa kết nối',
                    icon: _isAzureSyncConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isAzureSyncConnected ? Colors.green : Colors.grey,
                  ),
                  _buildStatusCard(
                    context,
                    title: 'Chờ xử lý',
                    status: '$_pendingCount phiếu',
                    icon: Icons.pending_actions,
                    color: _pendingCount > 0 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thống kê hôm nay',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard(
                          context, 
                          'Tổng phiếu cân', 
                          '$_todayTicketCount', 
                          Icons.receipt,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          context, 
                          'Tổng khối lượng', 
                          _formatWeight(_todayTotalWeight), 
                          Icons.monitor_weight,
                          color: Colors.purple,
                        ),
                        _buildStatCard(
                          context, 
                          'Xe nhập', 
                          '$_incomingCount', 
                          Icons.arrow_downward,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          context, 
                          'Xe xuất', 
                          '$_outgoingCount', 
                          Icons.arrow_upward,
                          color: Colors.orange,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              // Quick actions
              Text(
                'Thao tác nhanh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Cân xe mới',
                    icon: Icons.add_circle,
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to weighing screen (index 1)
                      widget.onNavigate?.call(1);
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Xem phiếu cân',
                    icon: Icons.list_alt,
                    color: Colors.green,
                    onTap: () {
                      // Navigate to ticket list (index 2)
                      widget.onNavigate?.call(2);
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Báo cáo',
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to reports (index 6)
                      widget.onNavigate?.call(6);
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Đồng bộ Azure',
                    icon: Icons.cloud_sync,
                    color: Colors.teal,
                    onTap: () async {
                      // Sync with Azure
                      _syncWithAzure();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncWithAzure() async {
    // Hiển thị loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Đang đồng bộ với Azure...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Kiểm tra kết nối SignalR
      if (!SignalRService.instance.isConnected) {
        await SignalRService.instance.connect();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              SignalRService.instance.isConnected 
                  ? 'Đồng bộ thành công!' 
                  : 'Không thể kết nối Azure'
            ),
            backgroundColor: SignalRService.instance.isConnected 
                ? Colors.green 
                : Colors.red,
          ),
        );
        _checkDeviceStatus();
        _loadStatistics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đồng bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(status, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final cardColor = color ?? Theme.of(context).primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24, color: cardColor),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 11, color: cardColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 140,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
