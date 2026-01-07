import 'package:canoto/data/models/enums/alert_enums.dart';

/// Model cảnh báo
class Alert {
  final int? id;
  final String title;
  final String message;
  final AlertType type;
  final AlertSeverity severity;
  final String? source;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Alert({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    this.severity = AlertSeverity.info,
    this.source,
    this.isRead = false,
    this.isResolved = false,
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Alert copyWith({
    int? id,
    String? title,
    String? message,
    AlertType? type,
    AlertSeverity? severity,
    String? source,
    bool? isRead,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.value,
      'severity': severity.value,
      'source': source,
      'is_read': isRead ? 1 : 0,
      'is_resolved': isResolved ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.value == map['type'],
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.value == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      source: map['source'] as String?,
      isRead: map['is_read'] == 1,
      isResolved: map['is_resolved'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'])
          : null,
    );
  }
}
