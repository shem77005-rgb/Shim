/// Notification Model - Represents a notification in the system
class NotificationModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final DateTime timestamp;
  final String? parentId; // To filter notifications for specific parent

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.parentId,
  });

  /// Create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? json['message'] ?? '',
      category: json['category'] ?? json['notification_type'] ?? 'system',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
      parentId: json['user']?.toString() ?? json['user_id']?.toString(),
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      if (parentId != null) 'parent': parentId,
    };
  }
}

/// Notification Create Request Model
class NotificationCreateRequest {
  final String title;
  final String description;
  final String category;
  final String? parentId; // Send notification to specific parent

  NotificationCreateRequest({
    required this.title,
    required this.description,
    this.category = 'system',
    this.parentId,
  });

  /// Convert to JSON for API request
  /// Django expects: title, description, category, parent (as integer ID)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'title': title,
      'description': description,
      'category': category,
    };

    // Add parent as integer if provided
    if (parentId != null && parentId!.isNotEmpty) {
      json['parent'] = int.tryParse(parentId!) ?? parentId;
    }

    return json;
  }
}
