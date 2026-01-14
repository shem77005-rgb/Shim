/// Emergency Alert Model
class EmergencyAlert {
  final int id;
  final String childId;
  final String parentId;
  final bool active;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  EmergencyAlert({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.active,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Create from JSON response
  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as int,
      childId: json['child']?.toString() ?? '',
      parentId: json['parent']?.toString() ?? '',
      active: json['active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt:
          json['resolved_at'] != null
              ? DateTime.parse(json['resolved_at'] as String)
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': childId,
      'parent': parentId,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}
