import 'dart:async';
import 'scale_service.dart';
import 'nhb3000_scale_service.dart';
import 'serial_scale_service_impl.dart';
import '../logging/logging_service.dart';

/// Trạng thái thống nhất cho cả TCP và Serial scale
enum UnifiedScaleStatus {
  disconnected,
  connecting,
  connected,
  reading,
  stable,
  error,
}

extension UnifiedScaleStatusExtension on UnifiedScaleStatus {
  bool get isOk =>
      this == UnifiedScaleStatus.connected ||
      this == UnifiedScaleStatus.reading ||
      this == UnifiedScaleStatus.stable;

  String get displayName {
    switch (this) {
      case UnifiedScaleStatus.disconnected:
        return 'Ngắt kết nối';
      case UnifiedScaleStatus.connecting:
        return 'Đang kết nối...';
      case UnifiedScaleStatus.connected:
        return 'Đã kết nối';
      case UnifiedScaleStatus.reading:
        return 'Đang đọc';
      case UnifiedScaleStatus.stable:
        return 'Ổn định';
      case UnifiedScaleStatus.error:
        return 'Lỗi';
    }
  }
}

/// Manager thống nhất cho cả TCP (NHB3000) và Serial scale
/// Tự động chọn loại kết nối dựa trên cấu hình
class ScaleServiceManager implements ScaleService {
  // Singleton
  static final ScaleServiceManager _instance = ScaleServiceManager._internal();
  static ScaleServiceManager get instance => _instance;
  ScaleServiceManager._internal();

  // Services
  final NHB3000ScaleService _tcpService = NHB3000ScaleService.instance;
  final SerialScaleServiceImpl _serialService = SerialScaleServiceImpl.instance;

  // Current connection type
  String _connectionType = 'tcp'; // 'tcp' or 'serial'
  
  // Configuration
  String _portName = 'COM1';
  int _baudRate = 9600;
  String _ipAddress = '192.168.1.100';
  int _tcpPort = 8899;
  ScaleProtocol _protocol = ScaleProtocol.nhb;
  String _weightUnit = 'kg';

  // State
  bool _isConnected = false;
  double _currentWeight = 0;
  UnifiedScaleStatus _status = UnifiedScaleStatus.disconnected;

  // Streams
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  final StreamController<UnifiedScaleStatus> _statusController = StreamController<UnifiedScaleStatus>.broadcast();

  // Subscriptions
  StreamSubscription<double>? _tcpWeightSub;
  StreamSubscription<ScaleStatus>? _tcpStatusSub;
  StreamSubscription<double>? _serialWeightSub;
  StreamSubscription<SerialScaleStatus>? _serialStatusSub;

  // Logging
  final LoggingService _logger = LoggingService.instance;

  // Getters
  @override
  bool get isConnected => _isConnected;

  double get currentWeight => _currentWeight;

  UnifiedScaleStatus get status => _status;

  String get connectionType => _connectionType;

  String get weightUnit => _weightUnit;

  @override
  Stream<double> get weightStream => _weightController.stream;

  Stream<UnifiedScaleStatus> get statusStream => _statusController.stream;

  /// Cấu hình scale service manager
  void configure({
    required String connectionType,
    String? portName,
    int? baudRate,
    String? ipAddress,
    int? tcpPort,
    ScaleProtocol? protocol,
    String? weightUnit,
  }) {
    _connectionType = connectionType;
    if (portName != null) _portName = portName;
    if (baudRate != null) _baudRate = baudRate;
    if (ipAddress != null) _ipAddress = ipAddress;
    if (tcpPort != null) _tcpPort = tcpPort;
    if (protocol != null) _protocol = protocol;
    if (weightUnit != null) _weightUnit = weightUnit;

    _logger.info('ScaleManager', 
      'Configured: type=$_connectionType, port=$_portName, baud=$_baudRate, '
      'ip=$_ipAddress:$_tcpPort, protocol=${_protocol.name}, unit=$_weightUnit');
  }

  @override
  Future<bool> connect() async {
    if (_isConnected) {
      await disconnect();
    }

    _updateStatus(UnifiedScaleStatus.connecting);
    _logger.info('ScaleManager', 'Connecting via $_connectionType...');

    try {
      bool success = false;

      if (_connectionType == 'serial') {
        // Configure and connect serial
        _serialService.configure(
          portName: _portName,
          baudRate: _baudRate,
          protocol: _protocol,
        );
        success = await _serialService.connect();

        if (success) {
          _setupSerialSubscriptions();
        }
      } else {
        // Configure and connect TCP
        _tcpService.configure(
          ipAddress: _ipAddress,
          port: _tcpPort,
        );
        success = await _tcpService.connect();

        if (success) {
          _setupTcpSubscriptions();
        }
      }

      _isConnected = success;
      _updateStatus(success ? UnifiedScaleStatus.connected : UnifiedScaleStatus.error);
      
      _logger.info('ScaleManager', 'Connection ${success ? "successful" : "failed"}');
      return success;
    } catch (e) {
      _logger.error('ScaleManager', 'Connection error', error: e);
      _updateStatus(UnifiedScaleStatus.error);
      _isConnected = false;
      return false;
    }
  }

  void _setupSerialSubscriptions() {
    // Cancel existing subscriptions
    _serialWeightSub?.cancel();
    _serialStatusSub?.cancel();

    // Subscribe to serial weight stream
    _serialWeightSub = _serialService.weightStream.listen((weight) {
      _currentWeight = _convertWeight(weight);
      _weightController.add(_currentWeight);
    });

    // Subscribe to serial status stream
    _serialStatusSub = _serialService.statusStream.listen((status) {
      _updateStatus(_convertSerialStatus(status));
    });
  }

  void _setupTcpSubscriptions() {
    // Cancel existing subscriptions
    _tcpWeightSub?.cancel();
    _tcpStatusSub?.cancel();

    // Subscribe to TCP weight stream
    _tcpWeightSub = _tcpService.weightStream.listen((weight) {
      _currentWeight = _convertWeight(weight);
      _weightController.add(_currentWeight);
    });

    // Subscribe to TCP status stream
    _tcpStatusSub = _tcpService.statusStream.listen((status) {
      _updateStatus(_convertTcpStatus(status));
    });
  }

  /// Chuyển đổi trọng lượng theo đơn vị cấu hình
  double _convertWeight(double weightInKg) {
    switch (_weightUnit) {
      case 'g':
        return weightInKg * 1000; // kg -> gram
      case 'tan':
        return weightInKg / 1000; // kg -> tấn
      case 'lb':
        return weightInKg * 2.20462; // kg -> pound
      default:
        return weightInKg; // kg
    }
  }

  /// Lấy suffix đơn vị
  String getWeightUnitSuffix() {
    switch (_weightUnit) {
      case 'g':
        return 'g';
      case 'tan':
        return 'T';
      case 'lb':
        return 'lb';
      default:
        return 'kg';
    }
  }

  UnifiedScaleStatus _convertSerialStatus(SerialScaleStatus status) {
    switch (status) {
      case SerialScaleStatus.disconnected:
        return UnifiedScaleStatus.disconnected;
      case SerialScaleStatus.connecting:
        return UnifiedScaleStatus.connecting;
      case SerialScaleStatus.connected:
        return UnifiedScaleStatus.connected;
      case SerialScaleStatus.reading:
        return UnifiedScaleStatus.reading;
      case SerialScaleStatus.stable:
        return UnifiedScaleStatus.stable;
      case SerialScaleStatus.error:
        return UnifiedScaleStatus.error;
    }
  }

  UnifiedScaleStatus _convertTcpStatus(ScaleStatus status) {
    switch (status) {
      case ScaleStatus.disconnected:
        return UnifiedScaleStatus.disconnected;
      case ScaleStatus.connecting:
        return UnifiedScaleStatus.connecting;
      case ScaleStatus.connected:
        return UnifiedScaleStatus.connected;
      case ScaleStatus.weighing:
        return UnifiedScaleStatus.reading;
      case ScaleStatus.stable:
        return UnifiedScaleStatus.stable;
      case ScaleStatus.error:
        return UnifiedScaleStatus.error;
    }
  }

  void _updateStatus(UnifiedScaleStatus status) {
    _status = status;
    _isConnected = status.isOk;
    _statusController.add(status);
  }

  @override
  Future<void> disconnect() async {
    _logger.info('ScaleManager', 'Disconnecting...');

    // Cancel subscriptions
    _tcpWeightSub?.cancel();
    _tcpStatusSub?.cancel();
    _serialWeightSub?.cancel();
    _serialStatusSub?.cancel();

    // Disconnect services
    if (_connectionType == 'serial') {
      await _serialService.disconnect();
    } else {
      await _tcpService.disconnect();
    }

    _isConnected = false;
    _currentWeight = 0;
    _updateStatus(UnifiedScaleStatus.disconnected);
  }

  @override
  Future<double> readWeight() async {
    if (_connectionType == 'serial') {
      return await _serialService.readWeight();
    } else {
      return await _tcpService.readWeight();
    }
  }

  @override
  Future<bool> zero() async {
    if (_connectionType == 'serial') {
      return await _serialService.zero();
    } else {
      return await _tcpService.zero();
    }
  }

  @override
  Future<bool> tare() async {
    if (_connectionType == 'serial') {
      return await _serialService.tare();
    } else {
      return await _tcpService.tare();
    }
  }

  @override
  Future<bool> isStable() async {
    if (_connectionType == 'serial') {
      return await _serialService.isStable();
    } else {
      return await _tcpService.isStable();
    }
  }

  @override
  void dispose() {
    _tcpWeightSub?.cancel();
    _tcpStatusSub?.cancel();
    _serialWeightSub?.cancel();
    _serialStatusSub?.cancel();
    _weightController.close();
    _statusController.close();
  }
}
