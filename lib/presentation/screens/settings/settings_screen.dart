import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canoto/providers/settings_provider.dart';

/// Màn hình cài đặt nâng cao
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSection = 0;

  final List<_SettingsSection> _sections = [
    _SettingsSection('Giao diện', Icons.palette),
    _SettingsSection('Camera', Icons.videocam),
    _SettingsSection('Đầu cân', Icons.scale),
    _SettingsSection('Barrier', Icons.door_front_door),
    _SettingsSection('Vision Master', Icons.document_scanner),
    _SettingsSection('Máy in', Icons.print),
    _SettingsSection('Đồng bộ', Icons.sync),
    _SettingsSection('Azure Cloud', Icons.cloud),
    _SettingsSection('Thông báo', Icons.notifications),
    _SettingsSection('Công ty', Icons.business),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Khôi phục mặc định',
            onPressed: _showResetDialog,
          ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 220,
            color: Colors.grey.shade100,
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isSelected = _selectedSection == index;
                
                return ListTile(
                  leading: Icon(
                    section.icon,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                  ),
                  title: Text(
                    section.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.blue.shade50,
                  onTap: () => setState(() => _selectedSection = index),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Right content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildSectionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _buildAppearanceSettings();
      case 1:
        return _buildCameraSettings();
      case 2:
        return _buildScaleSettings();
      case 3:
        return _buildBarrierSettings();
      case 4:
        return _buildVisionSettings();
      case 5:
        return _buildPrinterSettings();
      case 6:
        return _buildSyncSettings();
      case 7:
        return _buildAzureSettings();
      case 8:
        return _buildNotificationSettings();
      case 9:
        return _buildCompanySettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSectionCard(
      title: 'Giao diện',
      children: [
        ListTile(
          title: const Text('Chủ đề'),
          subtitle: const Text('Chọn giao diện sáng hoặc tối'),
          trailing: DropdownButton<ThemeMode>(
            value: ThemeMode.light,
            items: const [
              DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              DropdownMenuItem(value: ThemeMode.system, child: Text('Theo hệ thống')),
            ],
            onChanged: (mode) {},
          ),
        ),
        ListTile(
          title: const Text('Ngôn ngữ'),
          subtitle: const Text('Chọn ngôn ngữ hiển thị'),
          trailing: DropdownButton<String>(
            value: 'vi',
            items: const [
              DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (lang) {},
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSettings() {
    return _buildSectionCard(
      title: 'Đồng bộ dữ liệu',
      children: [
        SwitchListTile(
          title: const Text('Tự động đồng bộ'),
          subtitle: const Text('Đồng bộ dữ liệu lên cloud tự động'),
          value: true,
          onChanged: (value) {},
        ),
        ListTile(
          title: const Text('Khoảng thời gian đồng bộ'),
          subtitle: const Text('Mỗi 5 phút'),
          trailing: DropdownButton<int>(
            value: 5,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 phút')),
              DropdownMenuItem(value: 5, child: Text('5 phút')),
              DropdownMenuItem(value: 10, child: Text('10 phút')),
              DropdownMenuItem(value: 30, child: Text('30 phút')),
            ],
            onChanged: (interval) {},
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Đồng bộ ngay'),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Sao lưu'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAzureSettings() {
    return _buildSectionCard(
      title: 'Azure Cloud',
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Azure API URL',
            hintText: 'https://your-api.azurewebsites.net/api',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Function Key',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('IoT Hub'),
          subtitle: const Text('Kết nối Azure IoT Hub (MQTT)'),
          value: false,
          onChanged: (value) {},
        ),
        SwitchListTile(
          title: const Text('SignalR'),
          subtitle: const Text('Nhận thông báo real-time'),
          value: true,
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.cloud_done),
          label: const Text('Kiểm tra kết nối Azure'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSectionCard(
      title: 'Thông báo',
      children: [
        SwitchListTile(
          title: const Text('Bật thông báo'),
          subtitle: const Text('Nhận thông báo từ hệ thống'),
          value: true,
          onChanged: (value) {},
        ),
        SwitchListTile(
          title: const Text('Âm thanh'),
          subtitle: const Text('Phát âm thanh khi có thông báo'),
          value: true,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildCompanySettings() {
    return _buildSectionCard(
      title: 'Thông tin công ty',
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Tên công ty',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Địa chỉ',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.image),
          label: const Text('Chọn logo'),
          onPressed: () {},
        ),
      ],
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục mặc định'),
        content: const Text('Bạn có chắc muốn khôi phục tất cả cài đặt về mặc định?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã khôi phục cài đặt mặc định')),
              );
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình đầu cân',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Loại kết nối',
                  ),
                  value: 'serial',
                  items: const [
                    DropdownMenuItem(value: 'serial', child: Text('Serial (COM)')),
                    DropdownMenuItem(value: 'tcp', child: Text('TCP/IP')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Cổng COM',
                    hintText: 'COM1',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Baud Rate',
                  ),
                  value: 9600,
                  items: const [
                    DropdownMenuItem(value: 4800, child: Text('4800')),
                    DropdownMenuItem(value: 9600, child: Text('9600')),
                    DropdownMenuItem(value: 19200, child: Text('19200')),
                    DropdownMenuItem(value: 38400, child: Text('38400')),
                    DropdownMenuItem(value: 115200, child: Text('115200')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.link),
                      label: const Text('Kết nối'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình Camera',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ IP',
                    hintText: '192.168.1.100',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Port',
                    hintText: '554',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'RTSP Path',
                    hintText: '/stream',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarrierSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình Barrier',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ IP',
                    hintText: '192.168.1.101',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Port Modbus',
                    hintText: '502',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Thời gian tự đóng (giây)',
                    hintText: '5',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.link),
                      label: const Text('Kết nối'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisionSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình Vision Master',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ IP',
                    hintText: '192.168.1.102',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Port',
                    hintText: '8000',
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Độ tin cậy tối thiểu (%)',
                    hintText: '80',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.link),
                      label: const Text('Kết nối'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterSettings() {
    return _buildSectionCard(
      title: 'Máy in',
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Tên máy in',
            hintText: 'Để trống để dùng mặc định',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('In tự động'),
          subtitle: const Text('Tự động in phiếu sau khi hoàn thành cân'),
          value: false,
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('In thử'),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Tìm máy in'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  _SettingsSection(this.title, this.icon);
}
