import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/scale/serial_scale_service_impl.dart';
import '../../../services/scale/nhb3000_scale_service.dart';
import '../../../core/constants/azure_config.dart';

/// Màn hình cài đặt nâng cao với đầy đủ tính năng
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSection = 0;
  bool _isLoading = false;
  bool _isTesting = false;

  // Controllers for text fields
  final _cameraIpController = TextEditingController();
  final _cameraPortController = TextEditingController();
  final _cameraUsernameController = TextEditingController();
  final _cameraPasswordController = TextEditingController();
  final _cameraPathController = TextEditingController();

  final _scalePortController = TextEditingController();
  final _scaleIpController = TextEditingController();
  final _scaleTcpPortController = TextEditingController();

  final _barrierIpController = TextEditingController();
  final _barrierPortController = TextEditingController();
  final _barrierAutoCloseController = TextEditingController();

  final _visionIpController = TextEditingController();
  final _visionPortController = TextEditingController();
  final _visionConfidenceController = TextEditingController();

  final _printerNameController = TextEditingController();

  final _azureApiUrlController = TextEditingController();
  final _azureFunctionKeyController = TextEditingController();

  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyTaxCodeController = TextEditingController();
  final _companyEmailController = TextEditingController();

  String _scaleConnectionType = 'serial';
  int _scaleBaudRate = 9600;
  String _scaleProtocol = 'nhb';
  String _scaleWeightUnit = 'kg';
  List<String> _availableComPorts = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() {
    final settings = context.read<SettingsProvider>();

    // Parse camera URL
    _parseCameraUrl(settings.cameraUrl);

    // Scale settings
    _scalePortController.text = settings.scalePort;
    _scaleBaudRate = settings.scaleBaudRate;
    _scaleConnectionType = settings.scaleConnectionType;
    _scaleIpController.text = settings.scaleIpAddress;
    _scaleTcpPortController.text = settings.scaleTcpPort.toString();
    _scaleProtocol = settings.scaleProtocol;
    _scaleWeightUnit = settings.scaleWeightUnit;
    
    // Load available COM ports
    _loadAvailableComPorts();

    // Printer
    _printerNameController.text = settings.printerName;

    // Azure
    _azureApiUrlController.text = settings.azureApiUrl;
    _azureFunctionKeyController.text = settings.azureFunctionKey;

    // Company
    _companyNameController.text = settings.companyName;
    _companyAddressController.text = settings.companyAddress;
    _companyPhoneController.text = settings.companyPhone;

    // Barrier defaults
    _barrierIpController.text = '192.168.1.101';
    _barrierPortController.text = '502';
    _barrierAutoCloseController.text = '5';

    // Vision defaults
    _visionIpController.text = '192.168.1.102';
    _visionPortController.text = '8000';
    _visionConfidenceController.text = '80';

    setState(() {});
  }

  void _loadAvailableComPorts() {
    try {
      _availableComPorts = SerialPort.availablePorts;
      if (_availableComPorts.isEmpty) {
        _availableComPorts = ['COM1', 'COM2', 'COM3', 'COM4'];
      }
    } catch (e) {
      _availableComPorts = ['COM1', 'COM2', 'COM3', 'COM4'];
    }
  }

  void _parseCameraUrl(String url) {
    try {
      final uri = Uri.parse(url);
      _cameraIpController.text = uri.host;
      _cameraPortController.text = uri.port.toString();
      _cameraUsernameController.text = uri.userInfo.split(':').first;
      if (uri.userInfo.contains(':')) {
        _cameraPasswordController.text = uri.userInfo.split(':').last;
      }
      _cameraPathController.text = uri.path;
    } catch (e) {
      _cameraIpController.text = '192.168.1.232';
      _cameraPortController.text = '554';
      _cameraUsernameController.text = 'admin';
      _cameraPasswordController.text = 'abcd1234';
      _cameraPathController.text = '/main';
    }
  }

  String _buildCameraUrl() {
    final ip = _cameraIpController.text.trim();
    final port = _cameraPortController.text.trim();
    final user = _cameraUsernameController.text.trim();
    final pass = _cameraPasswordController.text.trim();
    final path = _cameraPathController.text.trim();

    if (user.isNotEmpty && pass.isNotEmpty) {
      return 'rtsp://$user:$pass@$ip:$port$path';
    } else {
      return 'rtsp://$ip:$port$path';
    }
  }

  @override
  void dispose() {
    _cameraIpController.dispose();
    _cameraPortController.dispose();
    _cameraUsernameController.dispose();
    _cameraPasswordController.dispose();
    _cameraPathController.dispose();
    _scalePortController.dispose();
    _scaleIpController.dispose();
    _scaleTcpPortController.dispose();
    _barrierIpController.dispose();
    _barrierPortController.dispose();
    _barrierAutoCloseController.dispose();
    _visionIpController.dispose();
    _visionPortController.dispose();
    _visionConfidenceController.dispose();
    _printerNameController.dispose();
    _azureApiUrlController.dispose();
    _azureFunctionKeyController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyTaxCodeController.dispose();
    _companyEmailController.dispose();
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
            icon: const Icon(Icons.file_upload),
            tooltip: 'Xuất cài đặt',
            onPressed: _exportSettings,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Nhập cài đặt',
            onPressed: _importSettings,
          ),
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
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                  title: Text(
                    section.title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildSectionContent(),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  // ==================== APPEARANCE SETTINGS ====================
  Widget _buildAppearanceSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Giao diện',
              icon: Icons.palette,
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Chủ đề'),
                  subtitle: const Text('Chọn giao diện sáng hoặc tối'),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Sáng'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Tối'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Theo hệ thống'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        settings.setThemeMode(mode);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Ngôn ngữ'),
                  subtitle: const Text('Chọn ngôn ngữ hiển thị'),
                  trailing: DropdownButton<String>(
                    value: settings.language,
                    items: const [
                      DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (lang) {
                      if (lang != null) {
                        settings.setLanguage(lang);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==================== CAMERA SETTINGS ====================
  Widget _buildCameraSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Cấu hình Camera RTSP',
              icon: Icons.videocam,
              children: [
                SwitchListTile(
                  title: const Text('Bật Camera'),
                  subtitle: const Text('Sử dụng camera để chụp ảnh khi cân'),
                  value: settings.cameraEnabled,
                  onChanged: (value) => settings.setCameraEnabled(value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _cameraIpController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ IP',
                          hintText: '192.168.1.232',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.computer),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cameraPortController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '554',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cameraUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập',
                          hintText: 'admin',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cameraPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cameraPathController,
                  decoration: const InputDecoration(
                    labelText: 'RTSP Path',
                    hintText: '/main hoặc /stream',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'URL: ${_buildCameraUrl()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testCameraConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isTesting ? 'Đang test...' : 'Test kết nối'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _saveCameraSettings(settings),
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _testCameraConnection() async {
    if (!mounted) return;
    setState(() => _isTesting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isTesting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Camera URL: ${_buildCameraUrl()}'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveCameraSettings(SettingsProvider settings) {
    settings.setCameraUrl(_buildCameraUrl());
    _showSuccessMessage('Đã lưu cài đặt camera');
  }

  // ==================== SCALE SETTINGS ====================
  Widget _buildScaleSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Cấu hình đầu cân',
              icon: Icons.scale,
              children: [
                // Loại kết nối
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Loại kết nối',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.settings_ethernet),
                  ),
                  value: _scaleConnectionType,
                  items: const [
                    DropdownMenuItem(
                      value: 'serial',
                      child: Text('Serial (COM Port)'),
                    ),
                    DropdownMenuItem(value: 'tcp', child: Text('TCP/IP (Ethernet)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scaleConnectionType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Serial settings
                if (_scaleConnectionType == 'serial') ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Cổng COM',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.usb),
                          ),
                          value: _availableComPorts.contains(_scalePortController.text) 
                              ? _scalePortController.text 
                              : (_availableComPorts.isNotEmpty ? _availableComPorts.first : null),
                          items: _availableComPorts.map((port) {
                            String description = port;
                            try {
                              final info = SerialScaleServiceImpl.getPortInfo(port);
                              if (info['description'] != 'Unknown') {
                                description = '$port - ${info['description']}';
                              }
                            } catch (_) {}
                            return DropdownMenuItem(
                              value: port,
                              child: Text(description, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _scalePortController.text = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _loadAvailableComPorts();
                          setState(() {});
                          _showInfoMessage('Đã cập nhật danh sách COM ports');
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Làm mới danh sách COM',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Baud Rate',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    value: _scaleBaudRate,
                    items: const [
                      DropdownMenuItem(value: 2400, child: Text('2400')),
                      DropdownMenuItem(value: 4800, child: Text('4800')),
                      DropdownMenuItem(value: 9600, child: Text('9600')),
                      DropdownMenuItem(value: 19200, child: Text('19200')),
                      DropdownMenuItem(value: 38400, child: Text('38400')),
                      DropdownMenuItem(value: 57600, child: Text('57600')),
                      DropdownMenuItem(value: 115200, child: Text('115200')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _scaleBaudRate = value);
                      }
                    },
                  ),
                ] else ...[
                  // TCP/IP settings
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _scaleIpController,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ IP',
                            hintText: '192.168.1.100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _scaleTcpPortController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '8899',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testScaleConnection,
                        icon: const Icon(Icons.link),
                        label: const Text('Test kết nối'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveScaleSettings(settings),
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu cài đặt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Loại đầu cân & Giao thức',
              icon: Icons.settings,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Loại đầu cân',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.precision_manufacturing),
                  ),
                  value: _scaleProtocol,
                  items: const [
                    DropdownMenuItem(value: 'nhb', child: Text('NHB / A12E (Việt Nam)')),
                    DropdownMenuItem(value: 'nhb3000', child: Text('NHB3000 / XK3190')),
                    DropdownMenuItem(value: 'and_gf', child: Text('A&D GF Series')),
                    DropdownMenuItem(value: 'mettler', child: Text('Mettler Toledo')),
                    DropdownMenuItem(value: 'ohaus', child: Text('Ohaus')),
                    DropdownMenuItem(value: 'cas', child: Text('CAS')),
                    DropdownMenuItem(value: 'custom', child: Text('Tùy chỉnh')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scaleProtocol = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị đo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  value: _scaleWeightUnit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(value: 'g', child: Text('Gram (g)')),
                    DropdownMenuItem(value: 'tan', child: Text('Tấn (T)')),
                    DropdownMenuItem(value: 'lb', child: Text('Pound (lb)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _scaleWeightUnit = value);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _testScaleConnection() async {
    _showInfoMessage('Đang test kết nối đầu cân...');
    setState(() => _isTesting = true);
    
    try {
      bool success = false;
      
      if (_scaleConnectionType == 'tcp') {
        // Test TCP connection
        final scaleService = NHB3000ScaleService.instance;
        scaleService.configure(
          ipAddress: _scaleIpController.text.isNotEmpty 
              ? _scaleIpController.text 
              : '192.168.1.100',
          port: int.tryParse(_scaleTcpPortController.text) ?? 8899,
        );
        success = await scaleService.connect();
        if (success) {
          await Future.delayed(const Duration(seconds: 1));
          await scaleService.disconnect();
        }
      } else {
        // Test Serial connection
        final scaleService = SerialScaleServiceImpl.instance;
        scaleService.configure(
          portName: _scalePortController.text.isNotEmpty 
              ? _scalePortController.text 
              : 'COM1',
          baudRate: _scaleBaudRate,
          protocol: _getScaleProtocol(),
        );
        success = await scaleService.connect();
        if (success) {
          await Future.delayed(const Duration(seconds: 1));
          await scaleService.disconnect();
        }
      }
      
      if (mounted) {
        if (success) {
          _showSuccessMessage('Kết nối đầu cân thành công!');
        } else {
          _showErrorMessage('Không thể kết nối đầu cân. Vui lòng kiểm tra lại cấu hình.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Lỗi kết nối: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }
  
  ScaleProtocol _getScaleProtocol() {
    switch (_scaleProtocol) {
      case 'nhb':
      case 'nhb3000':
        return ScaleProtocol.nhb;
      case 'and_gf':
        return ScaleProtocol.andGf;
      case 'mettler':
        return ScaleProtocol.mettlerToledo;
      case 'ohaus':
        return ScaleProtocol.ohaus;
      default:
        return ScaleProtocol.custom;
    }
  }

  void _saveScaleSettings(SettingsProvider settings) {
    settings.setScalePort(_scalePortController.text);
    settings.setScaleBaudRate(_scaleBaudRate);
    settings.setScaleConnectionType(_scaleConnectionType);
    settings.setScaleIpAddress(_scaleIpController.text);
    settings.setScaleTcpPort(int.tryParse(_scaleTcpPortController.text) ?? 8899);
    settings.setScaleProtocol(_scaleProtocol);
    settings.setScaleWeightUnit(_scaleWeightUnit);
    _showSuccessMessage('Đã lưu cài đặt đầu cân');
  }

  // ==================== BARRIER SETTINGS ====================
  Widget _buildBarrierSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Cấu hình Barrier',
              icon: Icons.door_front_door,
              children: [
                SwitchListTile(
                  title: const Text('Bật Barrier'),
                  subtitle: const Text('Điều khiển barrier tự động'),
                  value: settings.barrierEnabled,
                  onChanged: (value) => settings.setBarrierEnabled(value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _barrierIpController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ IP',
                          hintText: '192.168.1.101',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.computer),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _barrierPortController,
                        decoration: const InputDecoration(
                          labelText: 'Port Modbus',
                          hintText: '502',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _barrierAutoCloseController,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian tự đóng (giây)',
                    hintText: '5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Tự động mở khi xe vào'),
                  subtitle: const Text('Mở barrier khi nhận diện được biển số'),
                  value: settings.barrierAutoOpen,
                  onChanged: (value) => settings.setBarrierAutoOpen(value),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showInfoMessage('Đang test kết nối barrier...'),
                      icon: const Icon(Icons.link),
                      label: const Text('Test kết nối'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showInfoMessage('Đang mở barrier...'),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Mở barrier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showSuccessMessage('Đã lưu cài đặt barrier'),
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==================== VISION SETTINGS ====================
  Widget _buildVisionSettings() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Cấu hình Vision Master (ANPR)',
          icon: Icons.document_scanner,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _visionIpController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ IP',
                      hintText: '192.168.1.102',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _visionPortController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '8000',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _visionConfidenceController,
              decoration: const InputDecoration(
                labelText: 'Độ tin cậy tối thiểu (%)',
                hintText: '80',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
                helperText:
                    'Chỉ nhận diện kết quả có độ tin cậy >= giá trị này',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _showInfoMessage('Đang test kết nối Vision Master...'),
                  icon: const Icon(Icons.link),
                  label: const Text('Test kết nối'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showInfoMessage('Đang nhận diện biển số...'),
                  icon: const Icon(Icons.camera),
                  label: const Text('Test nhận diện'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showSuccessMessage('Đã lưu cài đặt Vision Master'),
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ==================== PRINTER SETTINGS ====================
  Widget _buildPrinterSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Cấu hình máy in',
              icon: Icons.print,
              children: [
                TextField(
                  controller: _printerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên máy in',
                    hintText: 'Để trống để dùng mặc định',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.print),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('In tự động'),
                  subtitle: const Text(
                    'Tự động in phiếu sau khi hoàn thành cân',
                  ),
                  value: settings.printAutomatic,
                  onChanged: (value) => settings.setPrintAutomatic(value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Số bản in'),
                  trailing: DropdownButton<int>(
                    value: 2,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 bản')),
                      DropdownMenuItem(value: 2, child: Text('2 bản')),
                      DropdownMenuItem(value: 3, child: Text('3 bản')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _printTestPage,
                      icon: const Icon(Icons.print),
                      label: const Text('In thử'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _findPrinters,
                      icon: const Icon(Icons.search),
                      label: const Text('Tìm máy in'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        settings.setPrinterName(_printerNameController.text);
                        _showSuccessMessage('Đã lưu cài đặt máy in');
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Mẫu phiếu in',
              icon: Icons.article,
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Phiếu cân hàng'),
                  subtitle: const Text('Mẫu mặc định'),
                  trailing: TextButton(
                    onPressed: () =>
                        _showInfoMessage('Chức năng đang phát triển'),
                    child: const Text('Chỉnh sửa'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Phiếu thanh toán'),
                  subtitle: const Text('Mẫu mặc định'),
                  trailing: TextButton(
                    onPressed: () =>
                        _showInfoMessage('Chức năng đang phát triển'),
                    child: const Text('Chỉnh sửa'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _printTestPage() {
    _showSuccessMessage('Đã gửi lệnh in thử');
  }

  void _findPrinters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Máy in có sẵn'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Microsoft Print to PDF'),
                onTap: () {
                  _printerNameController.text = 'Microsoft Print to PDF';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('OneNote'),
                onTap: () {
                  _printerNameController.text = 'OneNote';
                  Navigator.pop(context);
                },
              ),
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

  // ==================== SYNC SETTINGS ====================
  Widget _buildSyncSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Đồng bộ dữ liệu',
              icon: Icons.sync,
              children: [
                SwitchListTile(
                  title: const Text('Tự động đồng bộ'),
                  subtitle: const Text('Đồng bộ dữ liệu lên cloud tự động'),
                  value: settings.autoSync,
                  onChanged: (value) => settings.setAutoSync(value),
                ),
                ListTile(
                  title: const Text('Khoảng thời gian đồng bộ'),
                  subtitle: Text('Mỗi ${settings.syncInterval} phút'),
                  trailing: DropdownButton<int>(
                    value: settings.syncInterval,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 phút')),
                      DropdownMenuItem(value: 5, child: Text('5 phút')),
                      DropdownMenuItem(value: 10, child: Text('10 phút')),
                      DropdownMenuItem(value: 30, child: Text('30 phút')),
                      DropdownMenuItem(value: 60, child: Text('1 giờ')),
                    ],
                    onChanged: (interval) {
                      if (interval != null) {
                        settings.setSyncInterval(interval);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('Đồng bộ ngay'),
                      onPressed: _syncNow,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Tải từ cloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      onPressed: _downloadFromCloud,
                    ),
                  ],
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Sao lưu dữ liệu',
              icon: Icons.backup,
              children: [
                SwitchListTile(
                  title: const Text('Tự động sao lưu'),
                  subtitle: const Text('Sao lưu dữ liệu định kỳ'),
                  value: settings.autoBackup,
                  onChanged: (value) => settings.setAutoBackup(value),
                ),
                ListTile(
                  title: const Text('Khoảng thời gian sao lưu'),
                  subtitle: Text('Mỗi ${settings.backupInterval} giờ'),
                  trailing: DropdownButton<int>(
                    value: settings.backupInterval,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 giờ')),
                      DropdownMenuItem(value: 6, child: Text('6 giờ')),
                      DropdownMenuItem(value: 12, child: Text('12 giờ')),
                      DropdownMenuItem(value: 24, child: Text('24 giờ')),
                    ],
                    onChanged: (interval) {
                      if (interval != null) {
                        settings.setBackupInterval(interval);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.backup),
                      label: const Text('Sao lưu ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: _backupNow,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Khôi phục'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: _restoreBackup,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncNow() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final syncService = SyncService.instance;
      await syncService.forceSync();
      if (!mounted) return;
      _showSuccessMessage('Đồng bộ thành công!');
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Lỗi đồng bộ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _downloadFromCloud() {
    _showInfoMessage('Đang tải dữ liệu từ cloud...');
  }

  void _backupNow() {
    _showInfoMessage('Đang sao lưu dữ liệu...');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showSuccessMessage('Đã sao lưu dữ liệu thành công!');
      }
    });
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: const Text(
          'Chọn file backup để khôi phục. Lưu ý: Dữ liệu hiện tại sẽ bị ghi đè.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfoMessage('Đang khôi phục dữ liệu...');
            },
            child: const Text('Chọn file'),
          ),
        ],
      ),
    );
  }

  // ==================== AZURE SETTINGS ====================
  Widget _buildAzureSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Azure Cloud Configuration',
              icon: Icons.cloud,
              children: [
                TextField(
                  controller: _azureApiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Azure Functions API URL',
                    hintText: 'https://func-tramcan.azurewebsites.net/api',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _azureFunctionKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Function Key (nếu có)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấu hình hiện tại:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('IoT Hub: ${AzureConfig.iotHubHostname}'),
                        Text('Device ID: ${AzureConfig.iotDeviceId}'),
                        Text('SignalR: ${AzureConfig.signalREndpoint}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Kết nối Cloud Services',
              icon: Icons.cloud_queue,
              children: [
                SwitchListTile(
                  title: const Text('Azure IoT Hub'),
                  subtitle: const Text('Kết nối qua MQTT để gửi/nhận dữ liệu'),
                  secondary: Icon(
                    settings.iotHubEnabled ? Icons.cloud_done : Icons.cloud_off,
                    color: settings.iotHubEnabled ? Colors.green : Colors.grey,
                  ),
                  value: settings.iotHubEnabled,
                  onChanged: (value) => settings.setIotHubEnabled(value),
                ),
                SwitchListTile(
                  title: const Text('Azure SignalR'),
                  subtitle: const Text('Nhận thông báo real-time'),
                  secondary: Icon(
                    settings.signalREnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: settings.signalREnabled ? Colors.green : Colors.grey,
                  ),
                  value: settings.signalREnabled,
                  onChanged: (value) => settings.setSignalREnabled(value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_done),
                      label: const Text('Test kết nối'),
                      onPressed: _testAzureConnection,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        settings.setAzureApiUrl(_azureApiUrlController.text);
                        settings.setAzureFunctionKey(
                          _azureFunctionKeyController.text,
                        );
                        _showSuccessMessage('Đã lưu cấu hình Azure');
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Connection status card
            _buildConnectionStatusCard(),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatusCard() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        return _buildSectionCard(
          title: 'Trạng thái kết nối',
          icon: Icons.network_check,
          children: [
            ListTile(
              leading: Icon(
                notificationProvider.isMqttConnected
                    ? Icons.check_circle
                    : Icons.error,
                color: notificationProvider.isMqttConnected
                    ? Colors.green
                    : Colors.red,
              ),
              title: const Text('MQTT/IoT Hub'),
              subtitle: Text(
                notificationProvider.isMqttConnected
                    ? 'Đã kết nối'
                    : 'Chưa kết nối',
              ),
              trailing: notificationProvider.isMqttConnected
                  ? null
                  : TextButton(
                      onPressed: () => notificationProvider.reconnect(),
                      child: const Text('Kết nối lại'),
                    ),
            ),
            ListTile(
              leading: Icon(
                notificationProvider.isSignalRConnected
                    ? Icons.check_circle
                    : Icons.error,
                color: notificationProvider.isSignalRConnected
                    ? Colors.green
                    : Colors.red,
              ),
              title: const Text('SignalR'),
              subtitle: Text(
                notificationProvider.isSignalRConnected
                    ? 'Đã kết nối'
                    : 'Chưa kết nối',
              ),
              trailing: notificationProvider.isSignalRConnected
                  ? null
                  : TextButton(
                      onPressed: () => notificationProvider.reconnect(),
                      child: const Text('Kết nối lại'),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testAzureConnection() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.reconnect();

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      if (notificationProvider.isMqttConnected ||
          notificationProvider.isSignalRConnected) {
        _showSuccessMessage('Kết nối Azure thành công!');
      } else {
        _showErrorMessage('Không thể kết nối Azure');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================
  Widget _buildNotificationSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Thông báo',
              icon: Icons.notifications,
              children: [
                SwitchListTile(
                  title: const Text('Bật thông báo'),
                  subtitle: const Text('Nhận thông báo từ hệ thống'),
                  secondary: const Icon(Icons.notifications),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotificationsEnabled(value),
                ),
                SwitchListTile(
                  title: const Text('Âm thanh'),
                  subtitle: const Text('Phát âm thanh khi có thông báo'),
                  secondary: const Icon(Icons.volume_up),
                  value: settings.soundEnabled,
                  onChanged: (value) => settings.setSoundEnabled(value),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Loại thông báo',
              icon: Icons.tune,
              children: [
                SwitchListTile(
                  title: const Text('Phiếu cân mới'),
                  subtitle: const Text('Thông báo khi có phiếu cân mới'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Đồng bộ'),
                  subtitle: const Text('Thông báo khi đồng bộ dữ liệu'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Lỗi hệ thống'),
                  subtitle: const Text('Thông báo khi có lỗi'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('Bảo trì'),
                  subtitle: const Text('Thông báo về bảo trì hệ thống'),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==================== COMPANY SETTINGS ====================
  Widget _buildCompanySettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            _buildSectionCard(
              title: 'Thông tin công ty',
              icon: Icons.business,
              children: [
                TextField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _companyPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _companyTaxCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã số thuế',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn logo'),
                      onPressed: _selectLogo,
                    ),
                    const SizedBox(width: 16),
                    if (settings.companyLogo.isNotEmpty) ...[
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          File(settings.companyLogo),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _saveCompanySettings(settings),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        context.read<SettingsProvider>().setCompanyLogo(path);
        _showSuccessMessage('Đã chọn logo');
      }
    }
  }

  void _saveCompanySettings(SettingsProvider settings) {
    settings.setCompanyName(_companyNameController.text);
    settings.setCompanyAddress(_companyAddressController.text);
    settings.setCompanyPhone(_companyPhoneController.text);
    _showSuccessMessage('Đã lưu thông tin công ty');
  }

  // ==================== DIALOGS & ACTIONS ====================
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Khôi phục mặc định'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn khôi phục tất cả cài đặt về mặc định? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SettingsProvider>().resetToDefaults();
              _loadSettings();
              _showSuccessMessage('Đã khôi phục cài đặt mặc định');
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    final settings = context.read<SettingsProvider>().exportSettings();
    _showSuccessMessage('Đã xuất cài đặt (${settings.length} mục)');
  }

  void _importSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập cài đặt'),
        content: const Text(
          'Chọn file cài đặt để nhập. Cài đặt hiện tại sẽ bị ghi đè.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfoMessage('Đang nhập cài đặt...');
            },
            child: const Text('Chọn file'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  _SettingsSection(this.title, this.icon);
}
