import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:canoto/services/sync/sync_service.dart';
import 'package:canoto/services/scale/scale_service_manager.dart';
import 'package:canoto/services/scale/nhb3000_scale_service.dart';
import 'package:canoto/services/scale/serial_scale_service_impl.dart';
import 'package:canoto/services/print/print_service.dart';
import 'package:canoto/services/logging/logging_service.dart';
import 'package:canoto/providers/settings_provider.dart';
import 'package:canoto/data/repositories/weighing_ticket_repository_impl.dart';
import 'package:canoto/data/models/weighing_ticket.dart';
import 'package:canoto/data/models/enums/weighing_enums.dart';

/// Màn hình cân xe chính - Thiết kế chuyên nghiệp
class WeighingScreenNew extends StatefulWidget {
  const WeighingScreenNew({super.key});

  @override
  State<WeighingScreenNew> createState() => _WeighingScreenNewState();
}

class _WeighingScreenNewState extends State<WeighingScreenNew> {
  // RTSP Camera
  late final Player _player;
  late final VideoController _videoController;
  bool _isCameraConnected = false;
  bool _isCameraLoading = true;

  // Scale Service Manager (hỗ trợ cả TCP và Serial)
  final ScaleServiceManager _scaleService = ScaleServiceManager.instance;
  StreamSubscription<double>? _weightSubscription;
  StreamSubscription<UnifiedScaleStatus>? _scaleStatusSubscription;
  UnifiedScaleStatus _scaleStatus = UnifiedScaleStatus.disconnected;
  String _weightUnit = 'kg';

  // Stream subscriptions for proper cleanup
  StreamSubscription? _playingSubscription;
  StreamSubscription? _errorSubscription;
  late final void Function(SyncStatus) _syncListener;

  // Weight data - Real data from NHB3000
  double _currentWeight = 0;
  double _grossWeight = 0; // Trọng lượng tổng
  double _tareWeight = 0; // Trọng lượng bì
  double _netWeight = 0; // Trọng lượng hàng
  bool _isStable = false;
  bool _isScaleConnected = false;

  // Form data
  String _ticketNumber = '';
  String _ticketType = 'incoming'; // incoming, outgoing, service
  String _buyer = '';
  String _seller = '';
  String _warehouse = '';
  String _productType = '';
  double _ratio = 0; // kg/m3
  double _volume = 0; // m3
  double _unitPrice = 0;
  double _totalAmount = 0;

  // Sync status
  bool _isSynced = false;

  // Controllers
  final _licensePlateController = TextEditingController();
  final _containerController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateTicketNumber();
    _initCamera();
    _initScale();
    _initSync();
  }

  void _initScale() {
    // Get scale settings from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();

      // Lấy đơn vị cân
      _weightUnit = settings.scaleWeightUnit;

      // Cấu hình ScaleServiceManager - tự động chọn Serial hoặc TCP
      _scaleService.configure(
        connectionType: settings.scaleConnectionType,
        portName: settings.scalePort.isNotEmpty ? settings.scalePort : 'COM1',
        baudRate: settings.scaleBaudRate > 0 ? settings.scaleBaudRate : 9600,
        ipAddress: settings.scaleIpAddress.isNotEmpty
            ? settings.scaleIpAddress
            : '192.168.1.100',
        tcpPort: settings.scaleTcpPort > 0 ? settings.scaleTcpPort : 8899,
        protocol: _getScaleProtocol(settings.scaleProtocol),
        weightUnit: settings.scaleWeightUnit,
      );

      // Subscribe to weight stream
      _weightSubscription = _scaleService.weightStream.listen((weight) {
        if (mounted) {
          setState(() {
            _currentWeight = weight;
          });
        }
      });

      // Subscribe to status stream
      _scaleStatusSubscription = _scaleService.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _scaleStatus = status;
            _isScaleConnected = status.isOk;
            _isStable = status == UnifiedScaleStatus.stable;
          });
        }
      });

      // Connect to scale
      _connectScale();
    });
  }

  ScaleProtocol _getScaleProtocol(String protocol) {
    switch (protocol) {
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

  Future<void> _connectScale() async {
    final settings = context.read<SettingsProvider>();
    final connType = settings.scaleConnectionType;
    debugPrint('WeighingScreen: Connecting to scale via $connType...');
    final success = await _scaleService.connect();
    if (mounted) {
      setState(() {
        _isScaleConnected = success;
      });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đầu cân ${connType == "serial" ? "Serial" : "NHB3000"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initSync() {
    // Get Azure settings from provider
    final settings = context.read<SettingsProvider>();
    
    // Initialize sync service with Azure configuration
    SyncService.instance.initialize(
      apiKey: settings.azureFunctionKey,
      baseUrl: settings.azureApiUrl,
    );

    // Listen for sync status changes with removable listener
    _syncListener = (status) {
      if (mounted) {
        setState(() {
          _isSynced = status == SyncStatus.synced;
        });
      }
    };
    SyncService.instance.addListener(_syncListener);
  }

  void _initCamera() {
    _player = Player();
    _videoController = VideoController(_player);

    // Listen for player state changes with cancellable subscription
    _playingSubscription = _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isCameraConnected = playing;
          _isCameraLoading = false;
        });
      }
    });

    _errorSubscription = _player.stream.error.listen((error) {
      if (mounted) {
        setState(() {
          _isCameraConnected = false;
          _isCameraLoading = false;
        });
        debugPrint('Camera error: $error');
      }
    });

    // Connect to RTSP stream
    _connectCamera();
  }

  Future<void> _connectCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraLoading = true;
    });

    try {
      // Get camera URL from settings
      final settings = context.read<SettingsProvider>();
      final cameraUrl = settings.cameraUrl.isNotEmpty
          ? settings.cameraUrl
          : 'rtsp://192.168.1.232:554/main';

      await _player.open(Media(cameraUrl));
    } catch (e) {
      debugPrint('Failed to connect camera: $e');
      if (mounted) {
        setState(() {
          _isCameraConnected = false;
          _isCameraLoading = false;
        });
      }
    }
  }

  void _generateTicketNumber() {
    final now = DateTime.now();
    // Format: YYMMDDXXXX where XXXX is sequential number
    _ticketNumber =
        'PC-${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-0001';
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _playingSubscription?.cancel();
    _errorSubscription?.cancel();
    _weightSubscription?.cancel();
    _scaleStatusSubscription?.cancel();
    SyncService.instance.removeListener(_syncListener);

    // Disconnect scale
    _scaleService.disconnect();

    _player.dispose();
    _licensePlateController.dispose();
    _containerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Left Panel - Weight Display & Camera (38%)
            Expanded(
              flex: 38,
              child: Column(
                children: [
                  // Weight Display Section (50% of left panel)
                  Expanded(flex: 50, child: _buildWeightDisplaySection()),
                  const SizedBox(height: 10),
                  // Camera Section (50% of left panel)
                  Expanded(flex: 50, child: _buildCameraSection()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right Panel - Form & Data Table (62%)
            Expanded(
              flex: 62,
              child: Column(
                children: [
                  // Form Section (48% of right panel)
                  Expanded(flex: 48, child: _buildFormSection()),
                  const SizedBox(height: 10),
                  // Data Table Section (52% of right panel)
                  Expanded(flex: 52, child: _buildDataTableSection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị trọng lượng
  Widget _buildWeightDisplaySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2D4A6F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isScaleConnected ? Colors.greenAccent : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isScaleConnected
                                    ? Colors.greenAccent
                                    : Colors.red)
                                .withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NHB3000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _scaleStatus.displayName,
                      style: TextStyle(
                        color: _isScaleConnected
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildStatusChip(
                  _isStable ? 'Ổn định' : 'Đang cân',
                  _isStable ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ],
            ),
          ),
          // Main Weight Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Current Weight Display
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF30363D),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentWeight > 0
                                      ? _formatWeight(_currentWeight)
                                      : 'No Data',
                                  style: TextStyle(
                                    color: _currentWeight > 0
                                        ? const Color(0xFF39FF14)
                                        : const Color(0xFFFF4444),
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    letterSpacing: 6,
                                    shadows: [
                                      Shadow(
                                        color:
                                            (_currentWeight > 0
                                                    ? const Color(0xFF39FF14)
                                                    : const Color(0xFFFF4444))
                                                .withOpacity(0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _scaleService.getWeightUnitSuffix(),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Weight Summary Row
                  Flexible(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildWeightCard(
                            'Tổng',
                            _grossWeight,
                            const Color(0xFF4FC3F7),
                            Icons.scale,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildWeightCard(
                            'Bì',
                            _tareWeight,
                            const Color(0xFFFFB74D),
                            Icons.inventory_2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildWeightCard(
                            'Hàng',
                            _netWeight,
                            const Color(0xFF81C784),
                            Icons.local_shipping,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action Buttons Row
                  Flexible(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButtonCompact(
                            'Mới',
                            Icons.add_circle_outline,
                            const Color(0xFF42A5F5),
                            _onNewWeighing,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildActionButtonCompact(
                            'Lưu',
                            Icons.save,
                            const Color(0xFF26A69A),
                            _onSave,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildActionButtonCompact(
                            'Cân tổng',
                            Icons.arrow_downward,
                            const Color(0xFF5C6BC0),
                            _onWeighGross,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildActionButtonCompact(
                            'Cân bì',
                            Icons.arrow_upward,
                            const Color(0xFFAB47BC),
                            _onWeighTare,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonCompact(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(
    String label,
    double weight,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatWeight(weight),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  /// Widget Camera Section
  Widget _buildCameraSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Camera Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF37474F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildCameraButton(Icons.camera_alt, 'Chụp', _onCapture),
                const SizedBox(width: 6),
                _buildCameraButton(Icons.refresh, 'Làm mới', _onRefreshCamera),
              ],
            ),
          ),
          // Camera View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade800, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _buildCameraContent(),
              ),
            ),
          ),
          // License Plate Recognition
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.document_scanner,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _licensePlateController,
                    decoration: const InputDecoration(
                      hintText: 'Biển số xe',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _onRecognizePlate,
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  tooltip: 'Nhận diện biển số',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: _onClearPlate,
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  tooltip: 'Xóa',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_isCameraLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Đang kết nối camera...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (!_isCameraConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Không thể kết nối camera',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _onRefreshCamera,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị video từ camera RTSP
    return Video(controller: _videoController, fill: Colors.black);
  }

  /// Widget Form Section
  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Form Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'THÔNG TIN PHIẾU CÂN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Ticket Info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Số phiếu: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _ticketNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Sync Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isSynced ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSynced ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSynced ? 'Đã đồng bộ' : 'Chưa đồng bộ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Row 1: Time & Ticket Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          'Thời gian cân',
                          _formatDateTime(DateTime.now()),
                          icon: Icons.access_time,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTicketTypeSelector()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Container
                  _buildFormField(
                    'Container',
                    _containerController,
                    icon: Icons.inventory,
                    hasDropdown: true,
                  ),
                  const SizedBox(height: 12),
                  // Row 3: Buyer & Seller
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'Bên Mua',
                          _buyer,
                          ['Bê tông Bảo An', 'Công ty ABC', 'Công ty XYZ'],
                          (value) => setState(() => _buyer = value ?? ''),
                          icon: Icons.person,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          'Bên Bán',
                          _seller,
                          ['Bê tông Bảo An', 'Công ty ABC', 'Công ty XYZ'],
                          (value) => setState(() => _seller = value ?? ''),
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 4: Warehouse & Product Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'Kho Hàng',
                          _warehouse,
                          ['Kho 1', 'Kho 2', 'Kho 3'],
                          (value) => setState(() => _warehouse = value ?? ''),
                          icon: Icons.warehouse,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          'Loại Hàng',
                          _productType,
                          ['Cát', 'Đá', 'Xi măng', 'Thép'],
                          (value) => setState(() => _productType = value ?? ''),
                          icon: Icons.category,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 5: Calculations
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                'Tỉ lệ',
                                _ratio,
                                'kg/m³',
                                (value) => setState(() => _ratio = value),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumberField(
                                'Thể tích',
                                _volume,
                                'm³',
                                (value) => setState(() => _volume = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                'Đơn giá',
                                _unitPrice,
                                'VNĐ/Tấn',
                                (value) => setState(() => _unitPrice = value),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumberField(
                                'Tiền cân',
                                _totalAmount,
                                'VNĐ',
                                (value) => setState(() => _totalAmount = value),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 6: Note
                  _buildFormField(
                    'Ghi chú',
                    _noteController,
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          // Form Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                _buildActionButton(
                  onPressed: _onPrint,
                  icon: Icons.print,
                  label: 'In phiếu',
                  color: const Color(0xFF607D8B),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  onPressed: _onSync,
                  icon: Icons.cloud_upload,
                  label: 'Đồng bộ',
                  color: const Color(0xFF43A047),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  onPressed: _onOpenBarrier,
                  icon: Icons.fence,
                  label: 'Mở barrier',
                  color: const Color(0xFFEF6C00),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                _buildRadioOption('incoming', 'Nhập', Colors.green),
                _buildRadioOption('outgoing', 'Xuất', Colors.blue),
                _buildRadioOption('service', 'DV', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, Color color) {
    final isSelected = _ticketType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ticketType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? Colors.grey, size: 16),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool hasDropdown = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (hasDropdown)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.grey, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.isEmpty ? null : value,
                isExpanded: true,
                isDense: true,
                hint: const Text('Chọn...', style: TextStyle(fontSize: 12)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF1976D2)),
            tooltip: 'Thêm mới',
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    String unit,
    ValueChanged<double> onChanged, {
    bool readOnly = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade200 : null,
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 45,
          child: Text(
            unit,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Widget Data Table Section
  Widget _buildDataTableSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF546E7A)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DỮ LIỆU 30 NGÀY GẦN NHẤT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Filter chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip('Tất cả', true),
                    _buildFilterChip('Nhập', false),
                    _buildFilterChip('Xuất', false),
                  ],
                ),
                const SizedBox(width: 8),
                // Search button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Table Content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF5F5F5),
                  ),
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Phiếu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Biển số',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Loại',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tổng (kg)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Bì (kg)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Hàng (kg)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Thời gian',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Icon(
                        Icons.cloud_sync,
                        size: 16,
                        color: Color(0xFF546E7A),
                      ),
                    ),
                  ],
                  rows: _buildTableRows(),
                ),
              ),
            ),
          ),
          // Log Section
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF37474F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LOG',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      _buildLogEntry('09:39:09', 'Check thẻ: 12345678'),
                      _buildLogEntry('09:39:05', 'Kết nối cân thành công'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF37474F) : Colors.white70,
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows() {
    // Real data from local repository
    final tickets = WeighingTicketRepositoryImpl.instance.tickets;

    if (tickets.isEmpty) {
      // Return empty row with message
      return [
        DataRow(
          cells: [
            const DataCell(
              Text(
                'Chưa có phiếu cân',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
            const DataCell(Text('')),
          ],
        ),
      ];
    }

    return tickets.take(10).map((ticket) {
      final weighTime = ticket.firstWeightTime ?? ticket.createdAt;
      final time =
          '${weighTime.hour.toString().padLeft(2, '0')}:${weighTime.minute.toString().padLeft(2, '0')}';
      final type = ticket.weighingType.value == 'incoming'
          ? 'Nhập'
          : (ticket.weighingType.value == 'outgoing' ? 'Xuất' : 'Dịch vụ');

      return _buildDataRow(
        ticket.ticketNumber,
        ticket.licensePlate,
        type,
        ticket.firstWeight ?? 0,
        ticket.secondWeight ?? 0,
        ticket.netWeight ?? 0,
        time,
        ticket.isSynced,
      );
    }).toList();
  }

  DataRow _buildDataRow(
    String ticket,
    String plate,
    String type,
    double gross,
    double tare,
    double net,
    String time,
    bool synced,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            ticket,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFFB300)),
            ),
            child: Text(
              plate,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        ),
        DataCell(_buildTypeChip(type)),
        DataCell(
          Text('${gross.toInt()}', style: const TextStyle(fontSize: 11)),
        ),
        DataCell(Text('${tare.toInt()}', style: const TextStyle(fontSize: 11))),
        DataCell(
          Text(
            '${net.toInt()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        DataCell(Text(time, style: const TextStyle(fontSize: 11))),
        DataCell(
          Icon(
            synced ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: synced ? const Color(0xFF43A047) : const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    IconData icon;
    switch (type) {
      case 'Nhập':
        color = const Color(0xFF43A047);
        icon = Icons.arrow_downward;
        break;
      case 'Xuất':
        color = const Color(0xFF1976D2);
        icon = Icons.arrow_upward;
        break;
      default:
        color = const Color(0xFF7B1FA2);
        icon = Icons.swap_horiz;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            type,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String time, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '[$time] ',
            style: const TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatWeight(double weight) {
    return weight.toStringAsFixed(0);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // Action handlers
  void _onNewWeighing() {
    setState(() {
      _currentWeight = 0;
      _grossWeight = 0;
      _tareWeight = 0;
      _netWeight = 0;
      _generateTicketNumber();
    });
  }

  void _onSave() async {
    // Create ticket from current data
    final ticket = WeighingTicket(
      ticketNumber: _ticketNumber,
      licensePlate: _licensePlateController.text.isNotEmpty
          ? _licensePlateController.text
          : 'N/A',
      driverName: '',
      productName: _productType.isNotEmpty ? _productType : 'Hàng hóa',
      vehicleType: 'Xe tải',
      firstWeight: _grossWeight,
      secondWeight: _tareWeight,
      netWeight: _netWeight,
      firstWeightTime: DateTime.now(),
      status: WeighingStatus.completed,
      weighingType: _ticketType == 'incoming'
          ? WeighingType.incoming
          : WeighingType.outgoing,
      note: _noteController.text,
      unitPrice: _unitPrice,
      totalAmount: _totalAmount,
    );

    try {
      // Save to repository
      await WeighingTicketRepositoryImpl.instance.insert(ticket);
      LoggingService.instance.info(
        'WeighingScreen',
        'Ticket saved: ${ticket.ticketNumber}',
      );

      if (mounted) {
        setState(() {}); // Refresh to show new ticket in table
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu phiếu cân'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LoggingService.instance.error(
        'WeighingScreen',
        'Failed to save ticket',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu phiếu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onWeighGross() {
    setState(() {
      _grossWeight = _currentWeight;
      _netWeight = _grossWeight - _tareWeight;
    });
  }

  void _onWeighTare() {
    setState(() {
      _tareWeight = _currentWeight;
      _netWeight = _grossWeight - _tareWeight;
    });
  }

  void _onCapture() async {
    // Capture screenshot from video
    try {
      final screenshot = await _player.screenshot();
      if (screenshot != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã chụp ảnh từ camera')));
        // TODO: Save screenshot and trigger license plate recognition
      }
    } catch (e) {
      debugPrint('Failed to capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể chụp ảnh')));
      }
    }
  }

  void _onRefreshCamera() {
    _connectCamera();
  }

  void _onRecognizePlate() {
    // TODO: Trigger Vision Master
  }

  void _onClearPlate() {
    _licensePlateController.clear();
  }

  void _onPrint() async {
    // Create ticket from current data
    final ticket = WeighingTicket(
      ticketNumber: _ticketNumber,
      licensePlate: _licensePlateController.text.isNotEmpty
          ? _licensePlateController.text
          : 'N/A',
      driverName: '',
      productName: _productType.isNotEmpty ? _productType : 'Hàng hóa',
      vehicleType: 'Xe tải',
      firstWeight: _grossWeight,
      secondWeight: _tareWeight,
      netWeight: _netWeight,
      firstWeightTime: DateTime.now(),
      status: WeighingStatus.completed,
      weighingType: _ticketType == 'incoming'
          ? WeighingType.incoming
          : WeighingType.outgoing,
      note: _noteController.text,
      unitPrice: _unitPrice,
      totalAmount: _totalAmount,
    );

    try {
      // Show printing dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang chuẩn bị in phiếu...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get company info from settings (for future use in printWeighingTicket)
      // final settings = context.read<SettingsProvider>();

      // Print the ticket
      final success = await PrintService.instance.printWeighingTicket(ticket);

      if (mounted) {
        if (success) {
          LoggingService.instance.info(
            'WeighingScreen',
            'Ticket printed: ${ticket.ticketNumber}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('In phiếu thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hủy in phiếu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      LoggingService.instance.error(
        'WeighingScreen',
        'Failed to print ticket',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi in phiếu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onSync() async {
    // Reset sync state if stuck
    if (SyncService.instance.isSyncing) {
      debugPrint('WeighingScreen: Sync was stuck, resetting...');
      SyncService.instance.resetSyncState();
    }

    // Show syncing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang đồng bộ dữ liệu...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Log current settings
    final settings = context.read<SettingsProvider>();
    debugPrint('WeighingScreen: Syncing with URL=${settings.azureApiUrl}, hasKey=${settings.azureFunctionKey.isNotEmpty}');

    // Sync using SyncService
    final repo = WeighingTicketRepositoryImpl.instance;
    final result = await SyncService.instance.syncData(
      getUnsyncedTickets: () => repo.getUnsynced(),
      markAsSynced: (ids, azureIds) => repo.markAsSynced(ids, azureIds),
    );

    if (mounted) {
      setState(() => _isSynced = result.success);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Đồng bộ thành công: ${result.syncedCount} phiếu'
                : 'Lỗi: ${result.message}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onOpenBarrier() {
    // TODO: Open barrier
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã mở barrier'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
