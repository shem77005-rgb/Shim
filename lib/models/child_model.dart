/// Child Model - Represents a child user in the system
class Child {
  final String id;
  final String parentId;
  final String email;
  final String name;
  final int age;

  Child({
    required this.id,
    required this.parentId,
    required this.email,
    required this.name,
    required this.age,
  });

  /// Create Child from JSON
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id']?.toString() ?? '',
      parentId:
          json['parent_id']?.toString() ?? json['parent']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
    );
  }

  /// Convert Child to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent': parentId, // Use 'parent' for consistency with API expectations
      'email': email,
      'name': name,
      'age': age,
    };
  }
}

/// Child Creation Request Model
class ChildCreateRequest {
  final String parentId;
  final String email;
  final String password;
  final String name;
  final int age;

  ChildCreateRequest({
    required this.parentId,
    required this.email,
    required this.password,
    required this.name,
    required this.age,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'parent':
          parentId, // Changed from 'parent_id' to 'parent' to match API requirements
      'email': email,
      'password': password,
      'name': name,
      'age': age,
    };
  }
}
