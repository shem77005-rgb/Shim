import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/api/api_test_mode.dart';
import '../models/auth_models.dart';
import '../../../../../models/child_model.dart';
import '../../../../services/child_service.dart';

/// Authentication Service - Handles all authentication operations
class AuthService {
  final ApiClient _apiClient;

  // Expose the ApiClient for other services to use
  ApiClient get apiClient => _apiClient;

  // Singleton pattern
  static AuthService? _instance;
  factory AuthService({ApiClient? apiClient}) {
    _instance ??= AuthService._internal(apiClient ?? ApiClient());
    return _instance!;
  }

  AuthService._internal(this._apiClient);

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Parent Login
  Future<ApiResponse<AuthResponse>> parentLogin({
    required String email,
    required String password,
  }) async {
    try {
      // وضع الاختبار
      if (ApiTestMode.enabled) {
        final testResponse = await ApiTestMode.simulateParentLogin(
          email: email,
          password: password,
        );

        if (testResponse.isSuccess && testResponse.data != null) {
          final authResponse = AuthResponse.fromJson(testResponse.data!);
          await _saveAuthData(authResponse);
          return ApiResponse.success(authResponse);
        } else {
          return ApiResponse.error(testResponse.error ?? 'فشل تسجيل الدخول');
        }
      }

      // الوضع العادي
      final request = LoginRequest(email: email, password: password);

      final response = await _apiClient.post<dynamic>(
        ApiConstants.parentLogin,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _saveAuthData(authResponse);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Parent Signup/Register
  Future<ApiResponse<AuthResponse>> parentSignup({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      print('🔵 [AuthService] بدء عملية التسجيل');
      print('🔵 [AuthService] Email: $email, Name: $name');
      print('🔵 [AuthService] API Test Mode: ${ApiTestMode.enabled}');

      // وضع الاختبار - للتجربة بدون خادم حقيقي
      if (ApiTestMode.enabled) {
        print('⚠️  [AuthService] وضع الاختبار مفعّل - استخدام بيانات وهمية');
        final testResponse = await ApiTestMode.simulateParentSignup(
          email: email,
          password: password,
          name: name,
          phoneNumber: phoneNumber,
        );

        if (testResponse.isSuccess && testResponse.data != null) {
          final authResponse = AuthResponse.fromJson(testResponse.data!);
          await _saveAuthData(authResponse);
          return ApiResponse.success(authResponse);
        } else {
          return ApiResponse.error(testResponse.error ?? 'فشل إنشاء الحساب');
        }
      }

      // الوضع العادي - استدعاء API الحقيقي
      print('🔵 [AuthService] إنشاء request object...');
      final request = SignupRequest(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );

      print('🔵 [AuthService] Request JSON: ${request.toJson()}');
      print(
        '🔵 [AuthService] URL: ${ApiConstants.fullBaseUrl}${ApiConstants.parentRegister}',
      );
      print('🔵 [AuthService] محاولة الاتصال بالخادم...');

      final startTime = DateTime.now();

      final response = await _apiClient.post<dynamic>(
        ApiConstants.parentRegister,
        body: request.toJson(),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print(
        '🔵 [AuthService] استلام الاستجابة بعد: ${duration.inSeconds}.${duration.inMilliseconds % 1000}s',
      );
      print('🔵 [AuthService] Response success: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        print('✅ [AuthService] تحليل البيانات...');
        final authResponse = AuthResponse.fromJson(response.data);
        print('✅ [AuthService] User ID: ${authResponse.user.id}');
        await _saveAuthData(authResponse);
        return ApiResponse.success(authResponse);
      } else {
        print('❌ [AuthService] فشل: ${response.error}');
        // Provide more specific error messages for common issues
        String errorMessage = response.error ?? 'فشل إنشاء الحساب';

        // Handle specific error cases
        if (errorMessage.contains('database is locked')) {
          errorMessage =
              'قاعدة البيانات مشغولة حالياً. حاول مرة أخرى بعد بضع ثوانٍ.';
        } else if (errorMessage.contains('unique constraint') ||
            errorMessage.contains('already exists')) {
          errorMessage =
              'هذا البريد الإلكتروني مسجل مسبقاً. استخدم بريدًا آخر أو سجل دخولك مباشرة.';
        }

        return ApiResponse.error(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ [AuthService] خطأ في parentSignup: $e');
      print('❌ [AuthService] Error type: ${e.runtimeType}');
      print('❌ [AuthService] Stack trace: $stackTrace');

      // Provide more specific error messages based on exception type
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(
          'لا يمكن الاتصال بالخادم. تأكد من تشغيل الخادم وأن عنوان URL صحيح.',
        );
      } else if (e.toString().contains('TimeoutException')) {
        return ApiResponse.error(
          'انتهت مهلة الاتصال بالخادم. تحقق من اتصال الشبكة.',
        );
      } else {
        return ApiResponse.error('حدث خطأ أثناء إنشاء الحساب: ${e.toString()}');
      }
    }
  }

  /// Child Login
  Future<ApiResponse<AuthResponse>> childLogin({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _apiClient.post<dynamic>(
        ApiConstants.childLogin,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _saveAuthData(authResponse);
        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Child Registration
  Future<ApiResponse<Child>> childRegister({
    required String parentId,
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      print('🔵 [AuthService] بدء عملية تسجيل طفل');
      print('🔵 [AuthService] Parent ID: $parentId, Child Name: $name');

      // Create child using ChildService
      final childService = ChildService(apiClient: _apiClient);
      final response = await childService.createChild(
        parentId: parentId,
        email: email,
        password: password,
        name: name,
        age: age,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [AuthService] تم تسجيل الطفل بنجاح');
        return ApiResponse.success(response.data!);
      } else {
        print('❌ [AuthService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل تسجيل الطفل');
      }
    } catch (e) {
      print('❌ [AuthService] خطأ في childRegister: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Child Login with Data Fetching
  /// Authenticates child and fetches child profile data
  Future<ApiResponse<Child>> childLoginWithData({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _apiClient.post<dynamic>(
        ApiConstants.childLogin,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        // Parse the child login response
        final childData = response.data as Map<String, dynamic>;

        // Create a child object from the response data
        final child = Child(
          id: childData['id']?.toString() ?? '',
          parentId: childData['parent_id']?.toString() ?? '',
          email: childData['email'] ?? '',
          name: childData['name'] ?? '',
          age: 0, // Age is not provided in the login response
        );

        // Save auth data for the child
        final authResponse = AuthResponse(
          token: childData['access'] ?? '',
          refreshToken: childData['refresh'] ?? '',
          user: UserData(
            id: childData['id']?.toString() ?? '',
            email: childData['email'] ?? '',
            name: childData['name'] ?? '',
            phoneNumber: '',
            userType: 'child',
          ),
        );

        await _saveAuthData(authResponse);

        return ApiResponse.success(child);
      } else {
        return ApiResponse.error(response.error ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout, requiresAuth: true);
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearAuthData();
      _apiClient.clearAuthToken();
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.token);
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken);

    // Save user data as JSON string
    final userData = authResponse.user.toJson();
    await prefs.setString(_userDataKey, json.encode(userData));

    // Also save parent ID separately for easier access
    // For child users, we save the parent ID from their data
    // For parent users, we save their own ID
    if (authResponse.user.userType == 'child' &&
        authResponse.user.parentId.isNotEmpty) {
      await prefs.setString('parent_id', authResponse.user.parentId);
    } else {
      await prefs.setString('parent_id', authResponse.user.id);
    }

    // Set token in API client
    _apiClient.setAuthToken(authResponse.token);
  }

  /// Clear authentication data from local storage
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove('parent_id'); // Also remove parent_id
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user data
  Future<UserData?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      try {
        // Parse JSON string and create UserData object
        // This assumes the userDataString is a valid JSON representation
        // We need to parse it properly
        final userDataMap = json.decode(userDataString);
        return UserData.fromJson(userDataMap as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing user data: $e');
        print('Stored user data string: $userDataString');
        return null;
      }
    }
    return null;
  }

  /// Initialize authentication (call on app start)
  Future<void> init() async {
    final token = await getToken();
    print(
      '🔵 [AuthService] Initializing with token: ${token != null ? 'Token present' : 'No token'}',
    );
    if (token != null) {
      _apiClient.setAuthToken(token);
      print('🔵 [AuthService] Token set in API client');
    } else {
      print('🔵 [AuthService] No token found, user will need to login');
    }
  }
}
