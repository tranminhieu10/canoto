import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio Service - Manages sound effects and text-to-speech
class AudioService {
  // Singleton pattern
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  // TTS engine
  FlutterTts? _tts;
  
  // Audio player for sound effects
  AudioPlayer? _audioPlayer;
  
  // State
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _soundEnabled = true;
  bool _voiceEnabled = true;
  double _volume = 1.0;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _language = 'vi-VN';
  String? _currentVoice;
  
  // Available voices
  List<Map<String, String>> _availableVoices = [];
  
  // Queue for TTS messages
  final List<String> _speechQueue = [];
  bool _isProcessingQueue = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get soundEnabled => _soundEnabled;
  bool get voiceEnabled => _voiceEnabled;
  double get volume => _volume;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get language => _language;
  String? get currentVoice => _currentVoice;
  List<Map<String, String>> get availableVoices => _availableVoices;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('AudioService: Initializing...');
      
      // Initialize TTS
      _tts = FlutterTts();
      
      // Set up TTS
      await _tts!.setLanguage(_language);
      await _tts!.setSpeechRate(_speechRate);
      await _tts!.setVolume(_volume);
      await _tts!.setPitch(_pitch);
      
      // Get available voices
      final voices = await _tts!.getVoices;
      if (voices != null) {
        _availableVoices = List<Map<String, String>>.from(
          voices.map((v) => Map<String, String>.from(v as Map)),
        );
        
        // Try to find Vietnamese voice
        final viVoice = _availableVoices.firstWhere(
          (v) => v['locale']?.startsWith('vi') == true,
          orElse: () => {},
        );
        if (viVoice.isNotEmpty && viVoice['name'] != null) {
          await _tts!.setVoice({'name': viVoice['name']!, 'locale': viVoice['locale']!});
          _currentVoice = viVoice['name'];
        }
      }
      
      // Set up TTS callbacks
      _tts!.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('AudioService: Started speaking');
      });
      
      _tts!.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('AudioService: Finished speaking');
        _processNextInQueue();
      });
      
      _tts!.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('AudioService: Speech cancelled');
      });
      
      _tts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('AudioService: TTS Error: $msg');
        _processNextInQueue();
      });

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setVolume(_volume);
      
      _isInitialized = true;
      debugPrint('AudioService: Initialized successfully');
    } catch (e) {
      debugPrint('AudioService: Initialization error: $e');
    }
  }

  /// Set sound enabled
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    debugPrint('AudioService: Sound ${enabled ? "enabled" : "disabled"}');
  }

  /// Set voice enabled
  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled) {
      stop();
    }
    debugPrint('AudioService: Voice ${enabled ? "enabled" : "disabled"}');
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _tts?.setVolume(_volume);
    await _audioPlayer?.setVolume(_volume);
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts?.setSpeechRate(_speechRate);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitchValue) async {
    _pitch = pitchValue.clamp(0.5, 2.0);
    await _tts?.setPitch(_pitch);
  }

  /// Set language
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _tts?.setLanguage(lang);
  }

  /// Set voice
  Future<void> setVoice(String name, String locale) async {
    await _tts?.setVoice({'name': name, 'locale': locale});
    _currentVoice = name;
  }

  // ==================== SOUND EFFECTS ====================

  /// Play notification sound
  Future<void> playNotificationSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/notification.mp3');
  }

  /// Play success sound
  Future<void> playSuccessSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/success.mp3');
  }

  /// Play error sound
  Future<void> playErrorSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/error.mp3');
  }

  /// Play warning sound
  Future<void> playWarningSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/warning.mp3');
  }

  /// Play weighing complete sound
  Future<void> playWeighingCompleteSound() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/weighing_complete.mp3');
  }

  /// Play beep sound
  Future<void> playBeep() async {
    if (!_soundEnabled || !_isInitialized) return;
    await _playAsset('assets/sounds/beep.mp3');
  }

  /// Play asset sound file
  Future<void> _playAsset(String assetPath) async {
    try {
      await _audioPlayer?.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      // If asset doesn't exist, skip silently (sounds are optional)
      debugPrint('AudioService: Sound file not found: $assetPath (this is OK)');
    }
  }

  /// Play system beep (fallback when no audio files)
  Future<void> playSystemBeep() async {
    // On Windows, we can use the console beep
    // For now, just log - in production, add proper system sound
    debugPrint('AudioService: System beep');
  }

  // ==================== TEXT-TO-SPEECH ====================

  /// Speak text immediately
  Future<void> speak(String text) async {
    if (!_voiceEnabled || !_isInitialized || text.isEmpty) return;
    
    try {
      await stop(); // Stop any current speech
      await _tts?.speak(text);
      debugPrint('AudioService: Speaking: $text');
    } catch (e) {
      debugPrint('AudioService: Speak error: $e');
    }
  }

  /// Add text to speech queue
  void speakQueued(String text) {
    if (!_voiceEnabled || !_isInitialized || text.isEmpty) return;
    
    _speechQueue.add(text);
    if (!_isProcessingQueue) {
      _processNextInQueue();
    }
  }

  /// Process next item in speech queue
  Future<void> _processNextInQueue() async {
    if (_speechQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }
    
    _isProcessingQueue = true;
    final text = _speechQueue.removeAt(0);
    await speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    _speechQueue.clear();
    await _tts?.stop();
    _isSpeaking = false;
  }

  /// Pause speaking
  Future<void> pause() async {
    await _tts?.pause();
  }

  // ==================== WEIGHING ANNOUNCEMENTS ====================

  /// Announce weight reading
  Future<void> announceWeight(double weight, {String unit = 'kg'}) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    final weightStr = _formatWeight(weight);
    await speak('Trọng lượng $weightStr $unit');
  }

  /// Announce first weight
  Future<void> announceFirstWeight(double weight, String licensePlate) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    final weightStr = _formatWeight(weight);
    await speak('Xe $licensePlate, cân lần 1: $weightStr kg');
  }

  /// Announce second weight
  Future<void> announceSecondWeight(double weight, String licensePlate) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    final weightStr = _formatWeight(weight);
    await speak('Xe $licensePlate, cân lần 2: $weightStr kg');
  }

  /// Announce net weight
  Future<void> announceNetWeight(double netWeight, String licensePlate) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    final weightStr = _formatWeight(netWeight);
    await speak('Xe $licensePlate, trọng lượng hàng: $weightStr kg');
  }

  /// Announce weighing complete
  Future<void> announceWeighingComplete({
    required String licensePlate,
    required double netWeight,
    double? totalAmount,
  }) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    final weightStr = _formatWeight(netWeight);
    String message = 'Hoàn thành cân xe $licensePlate. Trọng lượng hàng $weightStr kg';
    
    if (totalAmount != null && totalAmount > 0) {
      final amountStr = _formatCurrency(totalAmount);
      message += '. Thành tiền $amountStr đồng';
    }
    
    await speak(message);
  }

  /// Announce vehicle arrival
  Future<void> announceVehicleArrival(String licensePlate) async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Xe $licensePlate đã vào trạm cân');
  }

  /// Announce vehicle departure
  Future<void> announceVehicleDeparture(String licensePlate) async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Xe $licensePlate đã rời trạm cân');
  }

  /// Announce barrier opening
  Future<void> announceBarrierOpening() async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Mở barrier');
  }

  /// Announce barrier closing
  Future<void> announceBarrierClosing() async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Đóng barrier');
  }

  // ==================== NOTIFICATION ANNOUNCEMENTS ====================

  /// Announce notification
  Future<void> announceNotification(String title, String message) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    if (_soundEnabled) {
      await playNotificationSound();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    await speak('$title. $message');
  }

  /// Announce alert
  Future<void> announceAlert(String message, {bool isEmergency = false}) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    if (_soundEnabled) {
      if (isEmergency) {
        await playErrorSound();
      } else {
        await playWarningSound();
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    final prefix = isEmergency ? 'Cảnh báo khẩn cấp!' : 'Cảnh báo!';
    await speak('$prefix $message');
  }

  /// Announce error
  Future<void> announceError(String error) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    if (_soundEnabled) {
      await playErrorSound();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    await speak('Lỗi: $error');
  }

  /// Announce success
  Future<void> announceSuccess(String message) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    if (_soundEnabled) {
      await playSuccessSound();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    await speak(message);
  }

  // ==================== SYSTEM ANNOUNCEMENTS ====================

  /// Announce system ready
  Future<void> announceSystemReady() async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Hệ thống cân ô tô sẵn sàng hoạt động');
  }

  /// Announce sync complete
  Future<void> announceSyncComplete(int count) async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Đồng bộ hoàn tất. Đã đồng bộ $count phiếu cân');
  }

  /// Announce connection status
  Future<void> announceConnectionStatus(bool isConnected) async {
    if (!_voiceEnabled || !_isInitialized) return;
    
    if (isConnected) {
      await speak('Đã kết nối máy chủ');
    } else {
      await speak('Mất kết nối máy chủ');
    }
  }

  /// Announce print started
  Future<void> announcePrintStarted() async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak('Đang in phiếu cân');
  }

  /// Announce custom message
  Future<void> announceCustom(String message) async {
    if (!_voiceEnabled || !_isInitialized) return;
    await speak(message);
  }

  // ==================== HELPER METHODS ====================

  /// Format weight for speech
  String _formatWeight(double weight) {
    if (weight >= 1000) {
      final tons = weight / 1000;
      if (tons == tons.toInt()) {
        return '${tons.toInt()} tấn';
      }
      return '${tons.toStringAsFixed(2)} tấn';
    }
    
    if (weight == weight.toInt()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  /// Format currency for speech
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(1)} triệu';
    }
    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(0)} nghìn';
    }
    return amount.toStringAsFixed(0);
  }

  /// Dispose resources
  void dispose() {
    _speechQueue.clear();
    _tts?.stop();
    _audioPlayer?.dispose();
    _isInitialized = false;
    debugPrint('AudioService: Disposed');
  }
}
