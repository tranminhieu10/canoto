/// Model người dùng
class User {
  final int? id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final List<String>? permissions;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.username,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.permissions,
    this.isActive = true,
    this.lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    List<String>? permissions,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'permissions': permissions?.join(','),
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String?,
      permissions: map['permissions']?.toString().split(','),
      isActive: map['is_active'] == 1,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
