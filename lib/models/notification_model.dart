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
      description: json['description'] ?? json['message'] ?? json['msg'] ?? '',
      category:
          json['category'] ??
          json['notification_type'] ??
          json['type'] ??
          'system',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
      parentId:
          json['parent']?.toString() ??
          json['user']?.toString() ??
          json['user_id']?.toString(),
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
      if (parentId != null) 'parent': int.tryParse(parentId!) ?? parentId,
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
  /// Django expects: title, message, notification_type, user (as integer ID)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'title': title,
      'message': description, // Backend uses 'message' instead of 'description'
      'notification_type':
          category, // Backend uses 'notification_type' instead of 'category'
    };

    // Add parent/user as integer if provided
    if (parentId != null && parentId!.isNotEmpty) {
      json['user'] =
          int.tryParse(parentId!) ??
          parentId; // Backend uses 'user' instead of 'parent'
    }

    return json;
  }
}
