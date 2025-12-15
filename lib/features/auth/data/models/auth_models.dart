/// Login Request Model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Signup/Register Request Model
class SignupRequest {
  final String email;
  final String password;
  final String phoneNumber;
  final String name;

  SignupRequest({
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'name': name,
    };
  }
}

/// Auth Response Model
class AuthResponse {
  final String token;
  final String refreshToken;
  final UserData user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] != null) {
      final token = json['token'] ?? json['access_token'] ?? '';
      final refreshToken = json['refresh_token'] ?? '';

      Map<String, dynamic> userData = {};
      if (json['user'] != null) {
        userData = json['user'] is Map<String, dynamic> ? json['user'] : {};
      }

      return AuthResponse(
        token: token,
        refreshToken: refreshToken,
        user: UserData.fromJson(userData),
      );
    } else if (json['access'] != null || json['refresh'] != null) {
      // Handle child login response
      final userType = json['role'] == 'child' ? 'child' : 'parent';

      return AuthResponse(
        token: json['access'] ?? '',
        refreshToken: json['refresh'] ?? '',
        user: UserData.fromJson({
          'id': json['id']?.toString() ?? '',
          'email': json['email'] ?? '',
          'name': json['name'] ?? '',
          'phone_number': '',
          'user_type': userType,
          'parent_id': json['parent_id']?.toString() ?? '',
        }),
      );
    } else {
      return AuthResponse(
        token: '',
        refreshToken: '',
        user: UserData.fromJson({
          'id': json['id']?.toString() ?? '',
          'email': json['email'] ?? '',
          'name': json['name'] ?? '',
          'phone_number': '',
          'user_type': 'parent',
        }),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }
}

/// User Data Model
class UserData {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String userType; // 'parent' or 'child'
  final String parentId; // For child users, this is their parent's ID
  final DateTime? createdAt;

  UserData({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.userType,
    this.parentId = '',
    this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      userType: json['user_type'] ?? json['type'] ?? 'parent',
      parentId: json['parent_id']?.toString() ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'user_type': userType,
      'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
