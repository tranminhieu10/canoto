import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:canoto/core/constants/azure_config.dart';

/// Settings Provider - Manages app settings and preferences
class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Settings keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keySyncInterval = 'sync_interval';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyBackupInterval = 'backup_interval';
  static const String _keyCameraEnabled = 'camera_enabled';
  static const String _keyCameraUrl = 'camera_url';
  static const String _keyBarrierEnabled = 'barrier_enabled';
  static const String _keyBarrierAutoOpen = 'barrier_auto_open';
  static const String _keyScalePort = 'scale_port';
  static const String _keyScaleBaudRate = 'scale_baud_rate';
  static const String _keyScaleConnectionType = 'scale_connection_type';
  static const String _keyScaleIpAddress = 'scale_ip_address';
  static const String _keyScaleTcpPort = 'scale_tcp_port';
  static const String _keyScaleProtocol = 'scale_protocol';
  static const String _keyScaleWeightUnit = 'scale_weight_unit';
  static const String _keyPrinterName = 'printer_name';
  static const String _keyPrintAutomatic = 'print_automatic';
  static const String _keyAzureApiUrl = 'azure_api_url';
  static const String _keyAzureFunctionKey = 'azure_function_key';
  static const String _keyIotHubEnabled = 'iot_hub_enabled';
  static const String _keySignalREnabled = 'signalr_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVoiceEnabled = 'voice_enabled';
  static const String _keyVoiceVolume = 'voice_volume';
  static const String _keyVoiceSpeechRate = 'voice_speech_rate';
  static const String _keyVoicePitch = 'voice_pitch';
  static const String _keyNotifyWeighing = 'notify_weighing';
  static const String _keyNotifySync = 'notify_sync';
  static const String _keyNotifyError = 'notify_error';
  static const String _keyNotifyMaintenance = 'notify_maintenance';
  static const String _keyAnnounceWeight = 'announce_weight';
  static const String _keyAnnounceVehicle = 'announce_vehicle';
  static const String _keyLanguage = 'language';
  static const String _keyCompanyName = 'company_name';
  static const String _keyCompanyAddress = 'company_address';
  static const String _keyCompanyPhone = 'company_phone';
  static const String _keyCompanyLogo = 'company_logo';

  // Default values
  ThemeMode _themeMode = ThemeMode.light;
  bool _autoSync = true;
  int _syncInterval = 5; // minutes
  bool _autoBackup = true;
  int _backupInterval = 24; // hours
  bool _cameraEnabled = true;
  String _cameraUrl = 'rtsp://192.168.1.232:554/main';
  bool _barrierEnabled = true;
  bool _barrierAutoOpen = false;
  String _scalePort = 'COM1';
  int _scaleBaudRate = 9600;
  String _scaleConnectionType = 'tcp'; // 'serial' or 'tcp'
  String _scaleIpAddress = '192.168.1.100';
  int _scaleTcpPort = 8899;
  String _scaleProtocol = 'nhb'; // 'nhb', 'a_d', 'mettler', 'ohaus', 'custom'
  String _scaleWeightUnit = 'kg'; // 'kg', 'g', 'tan', 'lb'
  String _printerName = '';
  bool _printAutomatic = false;
  String _azureApiUrl = AzureConfig.apiBaseUrl;
  String _azureFunctionKey = AzureConfig.functionHostKey;
  bool _iotHubEnabled = false;
  bool _signalREnabled = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _voiceEnabled = true;
  double _voiceVolume = 1.0;
  double _voiceSpeechRate = 0.5;
  double _voicePitch = 1.0;
  bool _notifyWeighing = true;
  bool _notifySync = true;
  bool _notifyError = true;
  bool _notifyMaintenance = false;
  bool _announceWeight = true;
  bool _announceVehicle = true;
  String _language = 'vi';
  String _companyName = 'Công ty TNHH Nuôi trồng Thủy sản';
  String _companyAddress = '';
  String _companyPhone = '';
  String _companyLogo = '';

  // Getters
  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  bool get autoSync => _autoSync;
  int get syncInterval => _syncInterval;
  bool get autoBackup => _autoBackup;
  int get backupInterval => _backupInterval;
  bool get cameraEnabled => _cameraEnabled;
  String get cameraUrl => _cameraUrl;
  bool get barrierEnabled => _barrierEnabled;
  bool get barrierAutoOpen => _barrierAutoOpen;
  String get scalePort => _scalePort;
  int get scaleBaudRate => _scaleBaudRate;
  String get scaleConnectionType => _scaleConnectionType;
  String get scaleIpAddress => _scaleIpAddress;
  int get scaleTcpPort => _scaleTcpPort;
  String get scaleProtocol => _scaleProtocol;
  String get scaleWeightUnit => _scaleWeightUnit;
  String get printerName => _printerName;
  bool get printAutomatic => _printAutomatic;
  String get azureApiUrl => _azureApiUrl;
  String get azureFunctionKey => _azureFunctionKey;
  bool get iotHubEnabled => _iotHubEnabled;
  bool get signalREnabled => _signalREnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get voiceEnabled => _voiceEnabled;
  double get voiceVolume => _voiceVolume;
  double get voiceSpeechRate => _voiceSpeechRate;
  double get voicePitch => _voicePitch;
  bool get notifyWeighing => _notifyWeighing;
  bool get notifySync => _notifySync;
  bool get notifyError => _notifyError;
  bool get notifyMaintenance => _notifyMaintenance;
  bool get announceWeight => _announceWeight;
  bool get announceVehicle => _announceVehicle;
  String get language => _language;
  String get companyName => _companyName;
  String get companyAddress => _companyAddress;
  String get companyPhone => _companyPhone;
  String get companyLogo => _companyLogo;

  /// Initialize settings
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    // Theme
    final themeModeIndex = _prefs.getInt(_keyThemeMode) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];

    // Sync
    _autoSync = _prefs.getBool(_keyAutoSync) ?? true;
    _syncInterval = _prefs.getInt(_keySyncInterval) ?? 5;

    // Backup
    _autoBackup = _prefs.getBool(_keyAutoBackup) ?? true;
    _backupInterval = _prefs.getInt(_keyBackupInterval) ?? 24;

    // Camera
    _cameraEnabled = _prefs.getBool(_keyCameraEnabled) ?? true;
    _cameraUrl = _prefs.getString(_keyCameraUrl) ?? _cameraUrl;

    // Barrier
    _barrierEnabled = _prefs.getBool(_keyBarrierEnabled) ?? true;
    _barrierAutoOpen = _prefs.getBool(_keyBarrierAutoOpen) ?? false;

    // Scale
    _scalePort = _prefs.getString(_keyScalePort) ?? 'COM1';
    _scaleBaudRate = _prefs.getInt(_keyScaleBaudRate) ?? 9600;
    _scaleConnectionType = _prefs.getString(_keyScaleConnectionType) ?? 'tcp';
    _scaleIpAddress = _prefs.getString(_keyScaleIpAddress) ?? '192.168.1.100';
    _scaleTcpPort = _prefs.getInt(_keyScaleTcpPort) ?? 8899;
    _scaleProtocol = _prefs.getString(_keyScaleProtocol) ?? 'nhb';
    _scaleWeightUnit = _prefs.getString(_keyScaleWeightUnit) ?? 'kg';

    // Printer
    _printerName = _prefs.getString(_keyPrinterName) ?? '';
    _printAutomatic = _prefs.getBool(_keyPrintAutomatic) ?? false;

    // Azure
    _azureApiUrl = _prefs.getString(_keyAzureApiUrl) ?? _azureApiUrl;
    // Migration: Fix old incorrect URL
    if (_azureApiUrl.contains('canoto-api.azurewebsites.net')) {
      _azureApiUrl = AzureConfig.apiBaseUrl; // Use correct URL from config
      await _prefs.setString(_keyAzureApiUrl, _azureApiUrl);
    }
    _azureFunctionKey = _prefs.getString(_keyAzureFunctionKey) ?? '';
    // Note: Function key should be configured in Settings, not hardcoded
    _iotHubEnabled = _prefs.getBool(_keyIotHubEnabled) ?? false;
    _signalREnabled = _prefs.getBool(_keySignalREnabled) ?? true;

    // Notifications
    _notificationsEnabled = _prefs.getBool(_keyNotificationsEnabled) ?? true;
    _soundEnabled = _prefs.getBool(_keySoundEnabled) ?? true;
    _voiceEnabled = _prefs.getBool(_keyVoiceEnabled) ?? true;
    _voiceVolume = _prefs.getDouble(_keyVoiceVolume) ?? 1.0;
    _voiceSpeechRate = _prefs.getDouble(_keyVoiceSpeechRate) ?? 0.5;
    _voicePitch = _prefs.getDouble(_keyVoicePitch) ?? 1.0;
    _notifyWeighing = _prefs.getBool(_keyNotifyWeighing) ?? true;
    _notifySync = _prefs.getBool(_keyNotifySync) ?? true;
    _notifyError = _prefs.getBool(_keyNotifyError) ?? true;
    _notifyMaintenance = _prefs.getBool(_keyNotifyMaintenance) ?? false;
    _announceWeight = _prefs.getBool(_keyAnnounceWeight) ?? true;
    _announceVehicle = _prefs.getBool(_keyAnnounceVehicle) ?? true;

    // Localization
    _language = _prefs.getString(_keyLanguage) ?? 'vi';

    // Company
    _companyName = _prefs.getString(_keyCompanyName) ?? _companyName;
    _companyAddress = _prefs.getString(_keyCompanyAddress) ?? '';
    _companyPhone = _prefs.getString(_keyCompanyPhone) ?? '';
    _companyLogo = _prefs.getString(_keyCompanyLogo) ?? '';
  }

  // Setters with persistence
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool(_keyAutoSync, value);
    notifyListeners();
  }

  Future<void> setSyncInterval(int minutes) async {
    _syncInterval = minutes;
    await _prefs.setInt(_keySyncInterval, minutes);
    notifyListeners();
  }

  Future<void> setAutoBackup(bool value) async {
    _autoBackup = value;
    await _prefs.setBool(_keyAutoBackup, value);
    notifyListeners();
  }

  Future<void> setBackupInterval(int hours) async {
    _backupInterval = hours;
    await _prefs.setInt(_keyBackupInterval, hours);
    notifyListeners();
  }

  Future<void> setCameraEnabled(bool value) async {
    _cameraEnabled = value;
    await _prefs.setBool(_keyCameraEnabled, value);
    notifyListeners();
  }

  Future<void> setCameraUrl(String url) async {
    _cameraUrl = url;
    await _prefs.setString(_keyCameraUrl, url);
    notifyListeners();
  }

  Future<void> setBarrierEnabled(bool value) async {
    _barrierEnabled = value;
    await _prefs.setBool(_keyBarrierEnabled, value);
    notifyListeners();
  }

  Future<void> setBarrierAutoOpen(bool value) async {
    _barrierAutoOpen = value;
    await _prefs.setBool(_keyBarrierAutoOpen, value);
    notifyListeners();
  }

  Future<void> setScalePort(String port) async {
    _scalePort = port;
    await _prefs.setString(_keyScalePort, port);
    notifyListeners();
  }

  Future<void> setScaleBaudRate(int baudRate) async {
    _scaleBaudRate = baudRate;
    await _prefs.setInt(_keyScaleBaudRate, baudRate);
    notifyListeners();
  }

  Future<void> setScaleConnectionType(String type) async {
    _scaleConnectionType = type;
    await _prefs.setString(_keyScaleConnectionType, type);
    notifyListeners();
  }

  Future<void> setScaleIpAddress(String ip) async {
    _scaleIpAddress = ip;
    await _prefs.setString(_keyScaleIpAddress, ip);
    notifyListeners();
  }

  Future<void> setScaleTcpPort(int port) async {
    _scaleTcpPort = port;
    await _prefs.setInt(_keyScaleTcpPort, port);
    notifyListeners();
  }

  Future<void> setScaleProtocol(String protocol) async {
    _scaleProtocol = protocol;
    await _prefs.setString(_keyScaleProtocol, protocol);
    notifyListeners();
  }

  Future<void> setScaleWeightUnit(String unit) async {
    _scaleWeightUnit = unit;
    await _prefs.setString(_keyScaleWeightUnit, unit);
    notifyListeners();
  }

  Future<void> setPrinterName(String name) async {
    _printerName = name;
    await _prefs.setString(_keyPrinterName, name);
    notifyListeners();
  }

  Future<void> setPrintAutomatic(bool value) async {
    _printAutomatic = value;
    await _prefs.setBool(_keyPrintAutomatic, value);
    notifyListeners();
  }

  Future<void> setAzureApiUrl(String url) async {
    _azureApiUrl = url;
    await _prefs.setString(_keyAzureApiUrl, url);
    notifyListeners();
  }

  Future<void> setAzureFunctionKey(String key) async {
    _azureFunctionKey = key;
    await _prefs.setString(_keyAzureFunctionKey, key);
    notifyListeners();
  }

  Future<void> setIotHubEnabled(bool value) async {
    _iotHubEnabled = value;
    await _prefs.setBool(_keyIotHubEnabled, value);
    notifyListeners();
  }

  Future<void> setSignalREnabled(bool value) async {
    _signalREnabled = value;
    await _prefs.setBool(_keySignalREnabled, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_keyNotificationsEnabled, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool(_keySoundEnabled, value);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    await _prefs.setBool(_keyVoiceEnabled, value);
    notifyListeners();
  }

  Future<void> setVoiceVolume(double value) async {
    _voiceVolume = value.clamp(0.0, 1.0);
    await _prefs.setDouble(_keyVoiceVolume, _voiceVolume);
    notifyListeners();
  }

  Future<void> setVoiceSpeechRate(double value) async {
    _voiceSpeechRate = value.clamp(0.0, 1.0);
    await _prefs.setDouble(_keyVoiceSpeechRate, _voiceSpeechRate);
    notifyListeners();
  }

  Future<void> setVoicePitch(double value) async {
    _voicePitch = value.clamp(0.5, 2.0);
    await _prefs.setDouble(_keyVoicePitch, _voicePitch);
    notifyListeners();
  }

  Future<void> setNotifyWeighing(bool value) async {
    _notifyWeighing = value;
    await _prefs.setBool(_keyNotifyWeighing, value);
    notifyListeners();
  }

  Future<void> setNotifySync(bool value) async {
    _notifySync = value;
    await _prefs.setBool(_keyNotifySync, value);
    notifyListeners();
  }

  Future<void> setNotifyError(bool value) async {
    _notifyError = value;
    await _prefs.setBool(_keyNotifyError, value);
    notifyListeners();
  }

  Future<void> setNotifyMaintenance(bool value) async {
    _notifyMaintenance = value;
    await _prefs.setBool(_keyNotifyMaintenance, value);
    notifyListeners();
  }

  Future<void> setAnnounceWeight(bool value) async {
    _announceWeight = value;
    await _prefs.setBool(_keyAnnounceWeight, value);
    notifyListeners();
  }

  Future<void> setAnnounceVehicle(bool value) async {
    _announceVehicle = value;
    await _prefs.setBool(_keyAnnounceVehicle, value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> setCompanyName(String name) async {
    _companyName = name;
    await _prefs.setString(_keyCompanyName, name);
    notifyListeners();
  }

  Future<void> setCompanyAddress(String address) async {
    _companyAddress = address;
    await _prefs.setString(_keyCompanyAddress, address);
    notifyListeners();
  }

  Future<void> setCompanyPhone(String phone) async {
    _companyPhone = phone;
    await _prefs.setString(_keyCompanyPhone, phone);
    notifyListeners();
  }

  Future<void> setCompanyLogo(String path) async {
    _companyLogo = path;
    await _prefs.setString(_keyCompanyLogo, path);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.clear();
    await _loadSettings();
    notifyListeners();
  }

  /// Export settings to JSON
  Map<String, dynamic> exportSettings() {
    return {
      'themeMode': _themeMode.index,
      'autoSync': _autoSync,
      'syncInterval': _syncInterval,
      'autoBackup': _autoBackup,
      'backupInterval': _backupInterval,
      'cameraEnabled': _cameraEnabled,
      'cameraUrl': _cameraUrl,
      'barrierEnabled': _barrierEnabled,
      'barrierAutoOpen': _barrierAutoOpen,
      'scalePort': _scalePort,
      'scaleBaudRate': _scaleBaudRate,
      'printerName': _printerName,
      'printAutomatic': _printAutomatic,
      'azureApiUrl': _azureApiUrl,
      'iotHubEnabled': _iotHubEnabled,
      'signalREnabled': _signalREnabled,
      'notificationsEnabled': _notificationsEnabled,
      'soundEnabled': _soundEnabled,
      'language': _language,
      'companyName': _companyName,
      'companyAddress': _companyAddress,
      'companyPhone': _companyPhone,
    };
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['themeMode'] != null) {
      await setThemeMode(ThemeMode.values[settings['themeMode'] as int]);
    }
    if (settings['autoSync'] != null) {
      await setAutoSync(settings['autoSync'] as bool);
    }
    if (settings['syncInterval'] != null) {
      await setSyncInterval(settings['syncInterval'] as int);
    }
    if (settings['autoBackup'] != null) {
      await setAutoBackup(settings['autoBackup'] as bool);
    }
    if (settings['backupInterval'] != null) {
      await setBackupInterval(settings['backupInterval'] as int);
    }
    if (settings['cameraEnabled'] != null) {
      await setCameraEnabled(settings['cameraEnabled'] as bool);
    }
    if (settings['cameraUrl'] != null) {
      await setCameraUrl(settings['cameraUrl'] as String);
    }
    if (settings['barrierEnabled'] != null) {
      await setBarrierEnabled(settings['barrierEnabled'] as bool);
    }
    if (settings['barrierAutoOpen'] != null) {
      await setBarrierAutoOpen(settings['barrierAutoOpen'] as bool);
    }
    if (settings['scalePort'] != null) {
      await setScalePort(settings['scalePort'] as String);
    }
    if (settings['scaleBaudRate'] != null) {
      await setScaleBaudRate(settings['scaleBaudRate'] as int);
    }
    if (settings['printerName'] != null) {
      await setPrinterName(settings['printerName'] as String);
    }
    if (settings['printAutomatic'] != null) {
      await setPrintAutomatic(settings['printAutomatic'] as bool);
    }
    if (settings['azureApiUrl'] != null) {
      await setAzureApiUrl(settings['azureApiUrl'] as String);
    }
    if (settings['iotHubEnabled'] != null) {
      await setIotHubEnabled(settings['iotHubEnabled'] as bool);
    }
    if (settings['signalREnabled'] != null) {
      await setSignalREnabled(settings['signalREnabled'] as bool);
    }
    if (settings['notificationsEnabled'] != null) {
      await setNotificationsEnabled(settings['notificationsEnabled'] as bool);
    }
    if (settings['soundEnabled'] != null) {
      await setSoundEnabled(settings['soundEnabled'] as bool);
    }
    if (settings['language'] != null) {
      await setLanguage(settings['language'] as String);
    }
    if (settings['companyName'] != null) {
      await setCompanyName(settings['companyName'] as String);
    }
    if (settings['companyAddress'] != null) {
      await setCompanyAddress(settings['companyAddress'] as String);
    }
    if (settings['companyPhone'] != null) {
      await setCompanyPhone(settings['companyPhone'] as String);
    }
  }
}
