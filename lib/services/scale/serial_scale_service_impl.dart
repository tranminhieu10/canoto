import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'scale_service.dart';
import '../logging/logging_service.dart';

/// Trạng thái kết nối cân Serial
enum SerialScaleStatus {
  disconnected,
  connecting,
  connected,
  reading,
  stable,
  error,
}

extension SerialScaleStatusExtension on SerialScaleStatus {
  bool get isOk =>
      this == SerialScaleStatus.connected ||
      this == SerialScaleStatus.reading ||
      this == SerialScaleStatus.stable;

  String get displayName {
    switch (this) {
      case SerialScaleStatus.disconnected:
        return 'Ngắt kết nối';
      case SerialScaleStatus.connecting:
        return 'Đang kết nối...';
      case SerialScaleStatus.connected:
        return 'Đã kết nối';
      case SerialScaleStatus.reading:
        return 'Đang đọc';
      case SerialScaleStatus.stable:
        return 'Ổn định';
      case SerialScaleStatus.error:
        return 'Lỗi';
    }
  }
}

/// Implementation cho đầu cân thông qua Serial Port (COM Port)
/// Hỗ trợ các loại cân phổ biến: NHB, A&D, Mettler Toledo, Ohaus
class SerialScaleServiceImpl implements ScaleService {
  // Singleton instance
  static final SerialScaleServiceImpl _instance = SerialScaleServiceImpl._internal();
  static SerialScaleServiceImpl get instance => _instance;
  SerialScaleServiceImpl._internal();

  // Serial port configuration
  String _portName = 'COM1';
  int _baudRate = 9600;
  int _dataBits = 8;
  int _stopBits = 1;
  int _parity = 0; // 0=None, 1=Odd, 2=Even

  // Scale protocol
  ScaleProtocol _protocol = ScaleProtocol.nhb;

  // Serial port
  SerialPort? _port;
  SerialPortReader? _reader;

  // State
  bool _isConnected = false;
  double _currentWeight = 0;
  bool _isStable = false;
  SerialScaleStatus _status = SerialScaleStatus.disconnected;

  // Streams
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  final StreamController<SerialScaleStatus> _statusController =
      StreamController<SerialScaleStatus>.broadcast();

  // Buffer for incoming data
  final StringBuffer _dataBuffer = StringBuffer();

  // Stability detection
  final List<double> _weightHistory = [];
  static const int _stabilityWindow = 5;
  static const double _stabilityThreshold = 0.5; // kg

  // Logging
  final LoggingService _logger = LoggingService.instance;

  // Getters
  @override
  bool get isConnected => _isConnected;

  @override
  Stream<double> get weightStream => _weightController.stream;

  Stream<SerialScaleStatus> get statusStream => _statusController.stream;

  SerialScaleStatus get status => _status;

  double get currentWeight => _currentWeight;

  bool get isWeightStable => _isStable;

  /// Lấy danh sách các COM port khả dụng
  static List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      debugPrint('Error getting available ports: $e');
      return [];
    }
  }

  /// Lấy thông tin chi tiết của port
  static Map<String, String> getPortInfo(String portName) {
    try {
      final port = SerialPort(portName);
      return {
        'name': portName,
        'description': port.description ?? 'Unknown',
        'manufacturer': port.manufacturer ?? 'Unknown',
        'serialNumber': port.serialNumber ?? 'Unknown',
        'productId': port.productId?.toString() ?? 'Unknown',
        'vendorId': port.vendorId?.toString() ?? 'Unknown',
      };
    } catch (e) {
      return {'name': portName, 'error': e.toString()};
    }
  }

  /// Cấu hình serial port
  void configure({
    String? portName,
    int? baudRate,
    int? dataBits,
    int? stopBits,
    int? parity,
    ScaleProtocol? protocol,
  }) {
    if (portName != null) _portName = portName;
    if (baudRate != null) _baudRate = baudRate;
    if (dataBits != null) _dataBits = dataBits;
    if (stopBits != null) _stopBits = stopBits;
    if (parity != null) _parity = parity;
    if (protocol != null) _protocol = protocol;

    _logger.info('SerialScale', 'Configured: $_portName, $_baudRate baud, protocol: ${_protocol.name}');
  }

  @override
  Future<bool> connect() async {
    if (_isConnected) {
      await disconnect();
    }

    _updateStatus(SerialScaleStatus.connecting);
    _logger.info('SerialScale', 'Connecting to $_portName...');

    try {
      // Create and open port
      _port = SerialPort(_portName);

      // Configure port
      final config = SerialPortConfig();
      config.baudRate = _baudRate;
      config.bits = _dataBits;
      config.stopBits = _stopBits;
      config.parity = _parity;
      config.setFlowControl(SerialPortFlowControl.none);

      _port!.config = config;

      // Open port for reading
      if (!_port!.openReadWrite()) {
        throw Exception('Failed to open port $_portName: ${SerialPort.lastError}');
      }

      // Create reader
      _reader = SerialPortReader(_port!);

      // Start reading data
      _startReading();

      _isConnected = true;
      _updateStatus(SerialScaleStatus.connected);
      _logger.info('SerialScale', 'Connected to $_portName successfully');

      return true;
    } catch (e) {
      _logger.error('SerialScale', 'Connection failed', error: e);
      _updateStatus(SerialScaleStatus.error);
      _isConnected = false;
      await disconnect();
      return false;
    }
  }

  void _startReading() {
    _reader?.stream.listen(
      (Uint8List data) {
        _processIncomingData(data);
      },
      onError: (error) {
        _logger.error('SerialScale', 'Read error', error: error);
        _updateStatus(SerialScaleStatus.error);
      },
      onDone: () {
        _logger.info('SerialScale', 'Reader stream closed');
        if (_isConnected) {
          _updateStatus(SerialScaleStatus.disconnected);
          _isConnected = false;
        }
      },
    );
  }

  void _processIncomingData(Uint8List data) {
    try {
      // Convert bytes to string
      final String incoming = String.fromCharCodes(data);
      _dataBuffer.write(incoming);

      // Check for complete message based on protocol
      String bufferContent = _dataBuffer.toString();

      // Different protocols use different terminators
      final terminator = _getTerminator();
      
      while (bufferContent.contains(terminator)) {
        final endIndex = bufferContent.indexOf(terminator);
        final message = bufferContent.substring(0, endIndex);
        bufferContent = bufferContent.substring(endIndex + terminator.length);
        
        // Parse the message
        _parseMessage(message.trim());
      }

      // Update buffer with remaining data
      _dataBuffer.clear();
      _dataBuffer.write(bufferContent);
    } catch (e) {
      _logger.error('SerialScale', 'Error processing data', error: e);
    }
  }

  String _getTerminator() {
    switch (_protocol) {
      case ScaleProtocol.nhb:
      case ScaleProtocol.andGf:
      case ScaleProtocol.mettlerToledo:
        return '\r\n';
      case ScaleProtocol.ohaus:
        return '\n';
      case ScaleProtocol.custom:
        return '\r\n';
    }
  }

  void _parseMessage(String message) {
    if (message.isEmpty) return;

    _updateStatus(SerialScaleStatus.reading);
    _logger.debug('SerialScale', 'Parsing message: "$message" with protocol: ${_protocol.name}');

    try {
      double? weight;
      bool stable = false;

      switch (_protocol) {
        case ScaleProtocol.nhb:
          // NHB format: "ST,+001234.5 kg" hoặc "ST,GS  39.80 g" (A&D style)
          // ST = Stable, US = Unstable
          // Thử match format đơn giản trước
          var nhbMatch = RegExp(r'(ST|US)[,\s]*([+-]?\d+\.?\d*)\s*(kg|g|lb)?', caseSensitive: false)
              .firstMatch(message);
          
          // Nếu không match, thử format có mã trạng thái ở giữa (như A&D: ST,GS  39.80 g)
          if (nhbMatch == null || nhbMatch.group(2)?.isEmpty == true) {
            nhbMatch = RegExp(r'(ST|US)[,\s]+\w*[,\s]+([+-]?\d+\.?\d*)\s*(kg|g|lb)?', caseSensitive: false)
                .firstMatch(message);
          }
          
          if (nhbMatch != null) {
            stable = nhbMatch.group(1)?.toUpperCase() == 'ST';
            weight = double.tryParse(nhbMatch.group(2) ?? '');
            // Convert to kg if needed
            final unit = nhbMatch.group(3)?.toLowerCase() ?? 'kg';
            if (unit == 'g' && weight != null) weight = weight / 1000;
            if (unit == 'lb' && weight != null) weight = weight * 0.453592;
          }
          break;

        case ScaleProtocol.andGf:
          // A&D format: "ST,GS  39.80 g" or "ST,GS,+001.234  kg" or "US,GS  39.80 g"
          // Có thể có dấu phẩy hoặc khoảng trắng sau mã trạng thái
          final andMatch = RegExp(r'(ST|US)[,\s]+\w+[,\s]+([+-]?\d+\.?\d*)\s*(kg|g)?', caseSensitive: false)
              .firstMatch(message);
          if (andMatch != null) {
            stable = andMatch.group(1)?.toUpperCase() == 'ST';
            weight = double.tryParse(andMatch.group(2) ?? '');
            final unit = andMatch.group(3)?.toLowerCase() ?? 'kg';
            if (unit == 'g' && weight != null) weight = weight / 1000;
          }
          break;

        case ScaleProtocol.mettlerToledo:
          // Mettler format: "S S     123.45 kg" or "S D     123.45 kg"
          // S S = Stable, S D = Dynamic
          final mtMatch = RegExp(r'S\s+([SD])\s+([+-]?\d+\.?\d*)\s*(kg|g)?', caseSensitive: false)
              .firstMatch(message);
          if (mtMatch != null) {
            stable = mtMatch.group(1)?.toUpperCase() == 'S';
            weight = double.tryParse(mtMatch.group(2) ?? '');
            final unit = mtMatch.group(3)?.toLowerCase() ?? 'kg';
            if (unit == 'g' && weight != null) weight = weight / 1000;
          }
          break;

        case ScaleProtocol.ohaus:
          // Ohaus format: "  123.45 kg" (simple weight)
          final ohausMatch = RegExp(r'([+-]?\d+\.?\d*)\s*(kg|g|lb)?', caseSensitive: false)
              .firstMatch(message);
          if (ohausMatch != null) {
            weight = double.tryParse(ohausMatch.group(1) ?? '');
            final unit = ohausMatch.group(2)?.toLowerCase() ?? 'kg';
            if (unit == 'g' && weight != null) weight = weight / 1000;
            if (unit == 'lb' && weight != null) weight = weight * 0.453592;
            // Check stability by weight history
            stable = _checkStabilityByHistory(weight ?? 0);
          }
          break;

        case ScaleProtocol.custom:
          // Try generic number extraction
          final customMatch = RegExp(r'([+-]?\d+\.?\d*)').firstMatch(message);
          if (customMatch != null) {
            weight = double.tryParse(customMatch.group(1) ?? '');
            stable = _checkStabilityByHistory(weight ?? 0);
          }
          break;
      }

      if (weight != null) {
        _logger.info('SerialScale', 'Parsed weight: $weight kg, stable: $stable');
        _currentWeight = weight;
        _isStable = stable;
        _weightController.add(weight);

        if (stable) {
          _updateStatus(SerialScaleStatus.stable);
        }

        // Update weight history for stability check
        _weightHistory.add(weight);
        if (_weightHistory.length > _stabilityWindow) {
          _weightHistory.removeAt(0);
        }
      } else {
        _logger.warning('SerialScale', 'Could not parse weight from message: "$message"');
      }
    } catch (e) {
      _logger.error('SerialScale', 'Error parsing message: $message', error: e);
    }
  }

  bool _checkStabilityByHistory(double currentWeight) {
    if (_weightHistory.length < _stabilityWindow) return false;

    double maxDiff = 0;
    for (final w in _weightHistory) {
      final diff = (w - currentWeight).abs();
      if (diff > maxDiff) maxDiff = diff;
    }

    return maxDiff < _stabilityThreshold;
  }

  @override
  Future<void> disconnect() async {
    _logger.info('SerialScale', 'Disconnecting...');

    try {
      _reader?.close();
      _reader = null;

      _port?.close();
      _port?.dispose();
      _port = null;

      _isConnected = false;
      _currentWeight = 0;
      _isStable = false;
      _dataBuffer.clear();
      _weightHistory.clear();

      _updateStatus(SerialScaleStatus.disconnected);
      _logger.info('SerialScale', 'Disconnected');
    } catch (e) {
      _logger.error('SerialScale', 'Error during disconnect', error: e);
    }
  }

  @override
  Future<double> readWeight() async {
    return _currentWeight;
  }

  @override
  Future<bool> zero() async {
    if (!_isConnected || _port == null) return false;

    try {
      final command = _getZeroCommand();
      _port!.write(Uint8List.fromList(command.codeUnits));
      _logger.info('SerialScale', 'Zero command sent');
      return true;
    } catch (e) {
      _logger.error('SerialScale', 'Failed to send zero command', error: e);
      return false;
    }
  }

  @override
  Future<bool> tare() async {
    if (!_isConnected || _port == null) return false;

    try {
      final command = _getTareCommand();
      _port!.write(Uint8List.fromList(command.codeUnits));
      _logger.info('SerialScale', 'Tare command sent');
      return true;
    } catch (e) {
      _logger.error('SerialScale', 'Failed to send tare command', error: e);
      return false;
    }
  }

  String _getZeroCommand() {
    switch (_protocol) {
      case ScaleProtocol.nhb:
        return 'Z\r\n';
      case ScaleProtocol.andGf:
        return 'Z\r\n';
      case ScaleProtocol.mettlerToledo:
        return 'Z\r\n';
      case ScaleProtocol.ohaus:
        return 'Z\r\n';
      case ScaleProtocol.custom:
        return 'Z\r\n';
    }
  }

  String _getTareCommand() {
    switch (_protocol) {
      case ScaleProtocol.nhb:
        return 'T\r\n';
      case ScaleProtocol.andGf:
        return 'T\r\n';
      case ScaleProtocol.mettlerToledo:
        return 'T\r\n';
      case ScaleProtocol.ohaus:
        return 'T\r\n';
      case ScaleProtocol.custom:
        return 'T\r\n';
    }
  }

  /// Gửi lệnh tùy chỉnh đến cân
  Future<bool> sendCommand(String command) async {
    if (!_isConnected || _port == null) return false;

    try {
      _port!.write(Uint8List.fromList('$command\r\n'.codeUnits));
      _logger.info('SerialScale', 'Command sent: $command');
      return true;
    } catch (e) {
      _logger.error('SerialScale', 'Failed to send command', error: e);
      return false;
    }
  }

  @override
  Future<bool> isStable() async {
    return _isStable;
  }

  void _updateStatus(SerialScaleStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  @override
  void dispose() {
    disconnect();
    _weightController.close();
    _statusController.close();
  }
}

/// Các protocol cân phổ biến
enum ScaleProtocol {
  nhb,           // NHB/A12E và các loại cân Việt Nam
  andGf,         // A&D GF series
  mettlerToledo, // Mettler Toledo
  ohaus,         // Ohaus
  custom,        // Tùy chỉnh
}

extension ScaleProtocolExtension on ScaleProtocol {
  String get displayName {
    switch (this) {
      case ScaleProtocol.nhb:
        return 'NHB / A12E';
      case ScaleProtocol.andGf:
        return 'A&D GF Series';
      case ScaleProtocol.mettlerToledo:
        return 'Mettler Toledo';
      case ScaleProtocol.ohaus:
        return 'Ohaus';
      case ScaleProtocol.custom:
        return 'Tùy chỉnh';
    }
  }
}
