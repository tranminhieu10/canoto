import 'dart:async';
import 'dart:io';
import 'scale_service.dart';

/// Implementation cho đầu cân thông qua TCP/IP
class TcpScaleService implements ScaleService {
  final String ipAddress;
  final int port;

  Socket? _socket;
  bool _isConnected = false;
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  double _currentWeight = 0;

  TcpScaleService({
    required this.ipAddress,
    this.port = 502,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<double> get weightStream => _weightController.stream;

  @override
  Future<bool> connect() async {
    try {
      _socket = await Socket.connect(ipAddress, port);
      _isConnected = true;

      _socket!.listen(
        (data) {
          // Parse weight data from received bytes
          _parseWeightData(data);
        },
        onError: (error) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );

      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isConnected = false;
  }

  @override
  Future<double> readWeight() async {
    if (!_isConnected || _socket == null) {
      throw Exception('Scale not connected');
    }
    // TODO: Send read weight command
    return _currentWeight;
  }

  @override
  Future<bool> zero() async {
    if (!_isConnected || _socket == null) return false;
    // TODO: Send zero command
    return true;
  }

  @override
  Future<bool> tare() async {
    if (!_isConnected || _socket == null) return false;
    // TODO: Send tare command
    return true;
  }

  @override
  Future<bool> isStable() async {
    // TODO: Check stability from response data
    return true;
  }

  void _parseWeightData(List<int> data) {
    // TODO: Implement parsing logic based on protocol
    // Example: Parse ASCII or binary data
    try {
      final str = String.fromCharCodes(data);
      final weight = double.tryParse(str.trim()) ?? 0;
      _currentWeight = weight;
      _weightController.add(weight);
    } catch (e) {
      // Handle parse error
    }
  }

  @override
  void dispose() {
    disconnect();
    _weightController.close();
  }
}
