import 'package:canoto/data/models/enums/device_enums.dart';

/// Model cấu hình thiết bị
class DeviceConfig {
  final int? id;
  final String name;
  final DeviceType type;
  final String? connectionType; // serial, tcp, usb
  final String? ipAddress;
  final int? port;
  final String? comPort;
  final int? baudRate;
  final String? username;
  final String? password;
  final Map<String, dynamic>? extraConfig;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceConfig({
    this.id,
    required this.name,
    required this.type,
    this.connectionType,
    this.ipAddress,
    this.port,
    this.comPort,
    this.baudRate,
    this.username,
    this.password,
    this.extraConfig,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DeviceConfig copyWith({
    int? id,
    String? name,
    DeviceType? type,
    String? connectionType,
    String? ipAddress,
    int? port,
    String? comPort,
    int? baudRate,
    String? username,
    String? password,
    Map<String, dynamic>? extraConfig,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      comPort: comPort ?? this.comPort,
      baudRate: baudRate ?? this.baudRate,
      username: username ?? this.username,
      password: password ?? this.password,
      extraConfig: extraConfig ?? this.extraConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'connection_type': connectionType,
      'ip_address': ipAddress,
      'port': port,
      'com_port': comPort,
      'baud_rate': baudRate,
      'username': username,
      'password': password,
      'extra_config': extraConfig?.toString(),
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DeviceConfig.fromMap(Map<String, dynamic> map) {
    return DeviceConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: DeviceType.values.firstWhere(
        (e) => e.value == map['type'],
        orElse: () => DeviceType.weighingIndicator,
      ),
      connectionType: map['connection_type'] as String?,
      ipAddress: map['ip_address'] as String?,
      port: map['port'] as int?,
      comPort: map['com_port'] as String?,
      baudRate: map['baud_rate'] as int?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      extraConfig: null, // Parse from string if needed
      isEnabled: map['is_enabled'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
