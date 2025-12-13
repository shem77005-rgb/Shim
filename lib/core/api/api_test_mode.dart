import 'api_response.dart';

/// Test Mode for API - Use this when you don't have a real backend
class ApiTestMode {
  // Enable/Disable test mode
  static const bool enabled = false; // ✅ معطّل - للاتصال بخادم Django الحقيقي

  /// Simulate Parent Signup
  static Future<ApiResponse<Map<String, dynamic>>> simulateParentSignup({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    // تأخير بسيط لمحاكاة الشبكة
    await Future.delayed(const Duration(seconds: 2));

    // محاكاة استجابة ناجحة
    final response = {
      'token': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token':
          'test_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'name': name,
        'phone_number': phoneNumber,
        'user_type': 'parent',
        'created_at': DateTime.now().toIso8601String(),
      },
    };

    return ApiResponse.success(response);
  }

  /// Simulate Parent Login
  static Future<ApiResponse<Map<String, dynamic>>> simulateParentLogin({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // تحقق بسيط
    if (password.length < 8) {
      return ApiResponse.error('كلمة المرور غير صحيحة');
    }

    final response = {
      'token': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token':
          'test_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '12345',
        'email': email,
        'name': 'مستخدم تجريبي',
        'phone_number': '777777777',
        'user_type': 'parent',
        'created_at': DateTime.now().toIso8601String(),
      },
    };

    return ApiResponse.success(response);
  }

  /// Simulate Child Login
  static Future<ApiResponse<Map<String, dynamic>>> simulateChildLogin({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final response = {
      'token': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token':
          'test_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '54321',
        'email': email,
        'name': 'طفل تجريبي',
        'phone_number': '555555555',
        'user_type': 'child',
        'created_at': DateTime.now().toIso8601String(),
      },
    };

    return ApiResponse.success(response);
  }
}
