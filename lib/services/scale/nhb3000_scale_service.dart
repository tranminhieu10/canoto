import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'scale_service.dart';

/// NHB3000 Scale Service - Kết nối với đầu cân NHB3000 qua TCP/IP
///
/// Đầu cân NHB3000 là dòng đầu cân phổ biến ở Việt Nam:
/// - Giao thức: TCP/IP hoặc Serial RS232
/// - Port mặc định: 8899 hoặc 502 (Modbus)
/// - Format dữ liệu: ASCII hoặc Binary
///
/// Protocol NHB3000:
/// - Gửi liên tục dữ liệu cân dạng ASCII
/// - Format: "=  12345 kg" hoặc "+00012345" (8 digits)
/// - Ký tự kết thúc: CR LF (0x0D 0x0A)
class NHB3000ScaleService implements ScaleService {
  // Singleton pattern
  static NHB3000ScaleService? _instance;
  static NHB3000ScaleService get instance =>
      _instance ??= NHB3000ScaleService._();
  NHB3000ScaleService._();

  // Factory constructor for custom configuration
  factory NHB3000ScaleService({String? ipAddress, int? port}) {
    final service = instance;
    if (ipAddress != null) service._ipAddress = ipAddress;
    if (port != null) service._port = port;
    return service;
  }

  // Connection settings
  String _ipAddress = '192.168.1.100';
  int _port = 8899;

  // Socket connection
  Socket? _socket;
  bool _isConnected = false;
  bool _isStable = false;
  double _currentWeight = 0;
  double _lastWeight = 0;
  int _stableCount = 0;

  // Stability detection
  static const int stableThreshold =
      5; // Số lần đọc liên tiếp giống nhau để xác định ổn định
  static const double stableTolerance = 0.5; // Sai số cho phép (kg)

  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  static const Duration reconnectDelay = Duration(seconds: 5);

  // Stream controllers
  final StreamController<double> _weightController =
      StreamController<double>.broadcast();
  final StreamController<ScaleStatus> _statusController =
      StreamController<ScaleStatus>.broadcast();

  // Buffer for incoming data
  final List<int> _dataBuffer = [];
  StreamSubscription? _socketSubscription;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<double> get weightStream => _weightController.stream;

  /// Stream trạng thái cân
  Stream<ScaleStatus> get statusStream => _statusController.stream;

  /// Trọng lượng hiện tại
  double get currentWeight => _currentWeight;

  /// Cân đang ổn định?
  bool get isWeightStable => _isStable;

  /// Cấu hình địa chỉ IP
  void configure({String? ipAddress, int? port}) {
    if (ipAddress != null) _ipAddress = ipAddress;
    if (port != null) _port = port;
  }

  @override
  Future<bool> connect() async {
    if (_isConnected) {
      debugPrint('NHB3000: Already connected');
      return true;
    }

    debugPrint('NHB3000: Connecting to $_ipAddress:$_port...');
    _statusController.add(ScaleStatus.connecting);

    try {
      _socket = await Socket.connect(
        _ipAddress,
        _port,
        timeout: const Duration(seconds: 10),
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _statusController.add(ScaleStatus.connected);
      debugPrint('NHB3000: Connected successfully');

      // Listen for data from scale
      _socketSubscription = _socket!.listen(
        _onDataReceived,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Request continuous weight data (if needed by protocol)
      // Some NHB3000 models send data automatically, others need a request
      _requestWeight();

      return true;
    } catch (e) {
      debugPrint('NHB3000: Connection failed: $e');
      _isConnected = false;
      _statusController.add(ScaleStatus.error);
      _scheduleReconnect();
      return false;
    }
  }

  void _requestWeight() {
    // NHB3000 protocol: Send request for weight data
    // Common commands: "R" for read, "W" for weight
    // Most models send continuously without request
    if (_socket != null && _isConnected) {
      try {
        // Send read command (depends on model)
        // _socket!.add([0x52]); // 'R' command
      } catch (e) {
        debugPrint('NHB3000: Failed to send command: $e');
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    // Add to buffer
    _dataBuffer.addAll(data);

    // Process complete frames (ending with CR LF)
    _processBuffer();
  }

  void _processBuffer() {
    // Look for complete frames (CR LF terminated)
    while (true) {
      // Find CR LF (0x0D 0x0A) or just LF (0x0A)
      int lfIndex = _dataBuffer.indexOf(0x0A);
      if (lfIndex == -1) break;

      // Extract frame
      List<int> frame;
      if (lfIndex > 0 && _dataBuffer[lfIndex - 1] == 0x0D) {
        frame = _dataBuffer.sublist(0, lfIndex - 1);
        _dataBuffer.removeRange(0, lfIndex + 1);
      } else {
        frame = _dataBuffer.sublist(0, lfIndex);
        _dataBuffer.removeRange(0, lfIndex + 1);
      }

      // Parse weight from frame
      _parseWeightData(frame);
    }

    // Prevent buffer overflow
    if (_dataBuffer.length > 1024) {
      _dataBuffer.clear();
    }
  }

  void _parseWeightData(List<int> data) {
    if (data.isEmpty) return;

    try {
      final str = String.fromCharCodes(data).trim();
      debugPrint('NHB3000 Raw: $str');

      // Parse different NHB3000 formats
      double? weight = _parseNHB3000Format(str);

      if (weight != null && weight >= 0) {
        _lastWeight = _currentWeight;
        _currentWeight = weight;

        // Check stability
        _checkStability();

        // Broadcast weight
        _weightController.add(_currentWeight);

        debugPrint(
          'NHB3000: Weight = ${_currentWeight.toStringAsFixed(1)} kg (${_isStable ? "Stable" : "Unstable"})',
        );
      }
    } catch (e) {
      debugPrint('NHB3000: Parse error: $e');
    }
  }

  double? _parseNHB3000Format(String data) {
    // Format 1: "=  12345 kg" hoặc "+  12345 kg"
    // Format 2: "+00012345" (8 digits, đơn vị 0.1kg)
    // Format 3: "ST,GS,+00012345kg" (comma separated)
    // Format 4: "  12345" (space padded)
    // Format 5: "WT:12345.0 KG" (with prefix)

    String cleaned = data.toUpperCase().replaceAll('KG', '').trim();

    // Remove status prefixes
    final prefixes = ['=', '+', '-', 'ST', 'GS', 'NT', 'WT', 'WT:', ','];
    for (final prefix in prefixes) {
      cleaned = cleaned.replaceAll(prefix, '');
    }
    cleaned = cleaned.trim();

    // Try parsing as double directly
    double? weight = double.tryParse(cleaned);

    // If parsing fails, try extracting numbers only
    if (weight == null) {
      final numbers = RegExp(r'[\d.]+').firstMatch(cleaned);
      if (numbers != null) {
        weight = double.tryParse(numbers.group(0)!);
      }
    }

    // Check for format with implicit decimal (8 digits = 0.1kg resolution)
    if (weight != null &&
        weight > 100000 &&
        cleaned.length >= 8 &&
        !cleaned.contains('.')) {
      weight = weight / 10; // Convert to kg if in 0.1kg units
    }

    return weight;
  }

  void _checkStability() {
    // Check if weight is stable (not changing)
    if ((_currentWeight - _lastWeight).abs() <= stableTolerance) {
      _stableCount++;
      if (_stableCount >= stableThreshold && !_isStable) {
        _isStable = true;
        _statusController.add(ScaleStatus.stable);
        debugPrint(
          'NHB3000: Weight is STABLE at ${_currentWeight.toStringAsFixed(1)} kg',
        );
      }
    } else {
      if (_stableCount >= stableThreshold || _isStable) {
        _isStable = false;
        _statusController.add(ScaleStatus.weighing);
      }
      _stableCount = 0;
    }
  }

  void _onError(dynamic error) {
    debugPrint('NHB3000: Socket error: $error');
    _isConnected = false;
    _statusController.add(ScaleStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('NHB3000: Connection closed');
    _isConnected = false;
    _statusController.add(ScaleStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('NHB3000: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('NHB3000: Reconnect attempt $_reconnectAttempts');
      connect();
    });
  }

  @override
  Future<void> disconnect() async {
    debugPrint('NHB3000: Disconnecting...');
    _reconnectTimer?.cancel();
    await _socketSubscription?.cancel();
    await _socket?.close();
    _socket = null;
    _isConnected = false;
    _dataBuffer.clear();
    _statusController.add(ScaleStatus.disconnected);
  }

  @override
  Future<double> readWeight() async {
    return _currentWeight;
  }

  @override
  Future<bool> zero() async {
    // NHB3000 Zero command
    if (!_isConnected || _socket == null) return false;

    try {
      // Common zero commands: "Z", "ZERO", 0x5A
      _socket!.add([0x5A]); // 'Z' command
      debugPrint('NHB3000: Zero command sent');
      return true;
    } catch (e) {
      debugPrint('NHB3000: Zero command failed: $e');
      return false;
    }
  }

  @override
  Future<bool> tare() async {
    // NHB3000 Tare command
    if (!_isConnected || _socket == null) return false;

    try {
      // Common tare commands: "T", "TARE", 0x54
      _socket!.add([0x54]); // 'T' command
      debugPrint('NHB3000: Tare command sent');
      return true;
    } catch (e) {
      debugPrint('NHB3000: Tare command failed: $e');
      return false;
    }
  }

  @override
  Future<bool> isStable() async {
    return _isStable;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    _weightController.close();
    _statusController.close();
    _instance = null;
  }
}

/// Trạng thái đầu cân
enum ScaleStatus {
  disconnected,
  connecting,
  connected,
  weighing,
  stable,
  error,
}

/// Extension cho ScaleStatus
extension ScaleStatusExtension on ScaleStatus {
  String get displayName {
    switch (this) {
      case ScaleStatus.disconnected:
        return 'Mất kết nối';
      case ScaleStatus.connecting:
        return 'Đang kết nối...';
      case ScaleStatus.connected:
        return 'Đã kết nối';
      case ScaleStatus.weighing:
        return 'Đang cân...';
      case ScaleStatus.stable:
        return 'Ổn định';
      case ScaleStatus.error:
        return 'Lỗi';
    }
  }

  bool get isOk =>
      this == ScaleStatus.connected ||
      this == ScaleStatus.weighing ||
      this == ScaleStatus.stable;
}
