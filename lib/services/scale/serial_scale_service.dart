import 'dart:async';
import 'scale_service.dart';

/// Implementation cho đầu cân thông qua Serial Port
class SerialScaleService implements ScaleService {
  final String comPort;
  final int baudRate;

  bool _isConnected = false;
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  Timer? _readTimer;
  double _currentWeight = 0;

  SerialScaleService({
    required this.comPort,
    this.baudRate = 9600,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<double> get weightStream => _weightController.stream;

  @override
  Future<bool> connect() async {
    try {
      // TODO: Implement serial port connection
      // Sử dụng package flutter_libserialport hoặc serial_port_win32
      _isConnected = true;
      _startReading();
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _readTimer?.cancel();
    _isConnected = false;
    // TODO: Close serial port
  }

  @override
  Future<double> readWeight() async {
    // TODO: Implement reading from serial port
    return _currentWeight;
  }

  @override
  Future<bool> zero() async {
    // TODO: Send zero command to scale
    return true;
  }

  @override
  Future<bool> tare() async {
    // TODO: Send tare command to scale
    return true;
  }

  @override
  Future<bool> isStable() async {
    // TODO: Check if weight is stable
    return true;
  }

  void _startReading() {
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_isConnected) {
        final weight = await readWeight();
        _currentWeight = weight;
        _weightController.add(weight);
      }
    });
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _weightController.close();
  }
}
