import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Singleton quản lý camera - giữ kết nối giữa các màn hình
class CameraManager {
  // Singleton
  static CameraManager? _instance;
  static CameraManager get instance => _instance ??= CameraManager._();
  CameraManager._();

  Player? _player;
  VideoController? _videoController;
  
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _currentUrl;
  
  StreamSubscription? _playingSubscription;
  StreamSubscription? _errorSubscription;

  // Getters
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  Player? get player => _player;
  VideoController? get videoController => _videoController;
  String? get currentUrl => _currentUrl;

  // Stream để thông báo trạng thái thay đổi
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Khởi tạo player (chỉ gọi 1 lần)
  void initialize() {
    if (_isInitialized) return;
    
    _player = Player();
    _videoController = VideoController(_player!);
    
    _playingSubscription = _player!.stream.playing.listen((playing) {
      _isConnected = playing;
      _connectionController.add(_isConnected);
    });
    
    _errorSubscription = _player!.stream.error.listen((error) {
      if (error.isNotEmpty) {
        _isConnected = false;
        _connectionController.add(_isConnected);
      }
    });
    
    _isInitialized = true;
  }

  /// Kết nối camera với URL
  Future<bool> connect(String url) async {
    if (!_isInitialized) {
      initialize();
    }
    
    if (_player == null) return false;
    
    try {
      _currentUrl = url;
      await _player!.open(Media(url));
      // Chờ một chút để kiểm tra kết nối
      await Future.delayed(const Duration(milliseconds: 500));
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(_isConnected);
      return false;
    }
  }

  /// Ngắt kết nối camera
  Future<void> disconnect() async {
    if (_player != null) {
      await _player!.stop();
      _isConnected = false;
      _currentUrl = null;
      _connectionController.add(_isConnected);
    }
  }

  /// Chụp ảnh màn hình
  Future<dynamic> screenshot() async {
    if (_player != null && _isConnected) {
      return await _player!.screenshot();
    }
    return null;
  }

  /// Dispose toàn bộ (chỉ gọi khi app tắt)
  void dispose() {
    _playingSubscription?.cancel();
    _errorSubscription?.cancel();
    _player?.dispose();
    _connectionController.close();
    _player = null;
    _videoController = null;
    _isInitialized = false;
    _isConnected = false;
  }
}
