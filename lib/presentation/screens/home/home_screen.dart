import 'package:flutter/material.dart';
import 'package:canoto/presentation/screens/weighing/weighing_screen_new.dart';
import 'package:canoto/presentation/screens/tickets/ticket_list_screen.dart';
import 'package:canoto/presentation/screens/settings/settings_screen.dart';
import 'package:canoto/presentation/screens/customers/customers_screen.dart';
import 'package:canoto/presentation/screens/vehicles/vehicles_screen.dart';
import 'package:canoto/presentation/screens/products/products_screen.dart';
import 'package:canoto/presentation/screens/reports/reports_screen.dart';

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
        return const _DashboardContent();
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
        return const _DashboardContent();
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
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
                status: 'Đã kết nối',
                icon: Icons.scale,
                color: Colors.green,
              ),
              _buildStatusCard(
                context,
                title: 'Camera',
                status: 'Đang hoạt động',
                icon: Icons.videocam,
                color: Colors.green,
              ),
              _buildStatusCard(
                context,
                title: 'Barrier',
                status: 'Đang đóng',
                icon: Icons.fence,
                color: Colors.blue,
              ),
              _buildStatusCard(
                context,
                title: 'Vision Master',
                status: 'Sẵn sàng',
                icon: Icons.document_scanner,
                color: Colors.green,
              ),
              _buildStatusCard(
                context,
                title: 'Máy in',
                status: 'Sẵn sàng',
                icon: Icons.print,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Statistics
          Text(
            'Thống kê hôm nay',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(context, 'Phiếu cân', '15', Icons.receipt),
              _buildStatCard(context, 'Tổng khối lượng', '245.5 tấn', Icons.monitor_weight),
              _buildStatCard(context, 'Xe nhập', '8', Icons.arrow_downward),
              _buildStatCard(context, 'Xe xuất', '7', Icons.arrow_upward),
            ],
          ),
        ],
      ),
    );
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
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(status, style: TextStyle(color: color)),
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
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
