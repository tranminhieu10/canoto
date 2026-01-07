import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:canoto/data/models/license_plate_result.dart';
import 'license_plate_service.dart';

/// Implementation cho Vision Master qua TCP
class VisionMasterService implements LicensePlateService {
  final String ipAddress;
  final int port;

  Socket? _socket;
  bool _isConnected = false;
  final StreamController<LicensePlateResult> _resultController =
      StreamController<LicensePlateResult>.broadcast();

  VisionMasterService({
    required this.ipAddress,
    this.port = 8000,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<LicensePlateResult> get resultStream => _resultController.stream;

  @override
  Future<bool> connect() async {
    try {
      _socket = await Socket.connect(ipAddress, port);
      _isConnected = true;

      _socket!.listen(
        (data) {
          _parseResult(data);
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
  Future<LicensePlateResult?> recognizeFromImage(String imagePath) async {
    // TODO: Send image path to Vision Master for recognition
    return null;
  }

  @override
  Future<LicensePlateResult?> recognizeFromBytes(List<int> imageBytes) async {
    // TODO: Send image bytes to Vision Master for recognition
    return null;
  }

  @override
  Future<LicensePlateResult?> trigger() async {
    if (!_isConnected || _socket == null) return null;
    try {
      // Send trigger command
      _socket!.add(utf8.encode('TRIGGER\r\n'));
      // Wait for response
      final completer = Completer<LicensePlateResult?>();
      late StreamSubscription subscription;
      subscription = _resultController.stream.timeout(
        const Duration(seconds: 5),
        onTimeout: (sink) {
          completer.complete(null);
        },
      ).listen((result) {
        subscription.cancel();
        completer.complete(result);
      });
      return completer.future;
    } catch (e) {
      return null;
    }
  }

  void _parseResult(List<int> data) {
    try {
      final str = utf8.decode(data);
      // Parse JSON response from Vision Master
      final json = jsonDecode(str) as Map<String, dynamic>;
      final result = LicensePlateResult(
        licensePlate: json['plate'] ?? '',
        confidence: (json['confidence'] ?? 0).toDouble(),
        imagePath: json['image_path'],
        rawData: json,
      );
      _resultController.add(result);
    } catch (e) {
      // Handle parse error
    }
  }

  @override
  void dispose() {
    disconnect();
    _resultController.close();
  }
}
