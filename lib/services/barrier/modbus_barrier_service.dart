import 'dart:async';
import 'package:canoto/data/models/enums/device_enums.dart';
import 'barrier_service.dart';

/// Implementation cho Barrier điều khiển qua Modbus TCP
class ModbusBarrierService implements BarrierService {
  final String ipAddress;
  final int port;

  bool _isConnected = false;
  BarrierStatus _currentStatus = BarrierStatus.closed;
  final StreamController<BarrierStatus> _statusController =
      StreamController<BarrierStatus>.broadcast();
  Timer? _autoCloseTimer;

  ModbusBarrierService({
    required this.ipAddress,
    this.port = 502,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  BarrierStatus get currentStatus => _currentStatus;

  @override
  Stream<BarrierStatus> get statusStream => _statusController.stream;

  @override
  Future<bool> connect() async {
    try {
      // TODO: Implement Modbus TCP connection
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _autoCloseTimer?.cancel();
    _isConnected = false;
  }

  @override
  Future<bool> open() async {
    if (!_isConnected) return false;
    try {
      _updateStatus(BarrierStatus.moving);
      // TODO: Send open command via Modbus
      await Future.delayed(const Duration(seconds: 2));
      _updateStatus(BarrierStatus.open);
      return true;
    } catch (e) {
      _updateStatus(BarrierStatus.error);
      return false;
    }
  }

  @override
  Future<bool> close() async {
    if (!_isConnected) return false;
    try {
      _updateStatus(BarrierStatus.moving);
      // TODO: Send close command via Modbus
      await Future.delayed(const Duration(seconds: 2));
      _updateStatus(BarrierStatus.closed);
      return true;
    } catch (e) {
      _updateStatus(BarrierStatus.error);
      return false;
    }
  }

  @override
  Future<bool> openTemporary({
    Duration duration = const Duration(seconds: 5),
  }) async {
    final opened = await open();
    if (opened) {
      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(duration, () {
        close();
      });
    }
    return opened;
  }

  @override
  Future<bool> stop() async {
    _autoCloseTimer?.cancel();
    // TODO: Send emergency stop command
    _updateStatus(BarrierStatus.closed);
    return true;
  }

  void _updateStatus(BarrierStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _statusController.close();
  }
}
