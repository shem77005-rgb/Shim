/// Child Login Response Model
class ChildLoginResponse {
  final String id;
  final String name;
  final String email;
  final String parentId;
  final String role;
  final String accessToken;
  final String refreshToken;
  final String message;

  ChildLoginResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.parentId,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.message,
  });

  /// Create ChildLoginResponse from JSON
  factory ChildLoginResponse.fromJson(Map<String, dynamic> json) {
    return ChildLoginResponse(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      parentId: json['parent_id']?.toString() ?? '',
      role: json['role'] ?? '',
      accessToken: json['access'] ?? '',
      refreshToken: json['refresh'] ?? '',
      message: json['message'] ?? '',
    );
  }

  /// Convert ChildLoginResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'parent_id': parentId,
      'role': role,
      'access': accessToken,
      'refresh': refreshToken,
      'message': message,
    };
  }
}
