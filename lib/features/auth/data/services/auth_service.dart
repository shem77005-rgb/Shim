import 'dart:convert' as json;
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

  ApiClient get apiClient => _apiClient;

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

  // ✅ NEW
  static const String _userRoleKey = 'user_role'; // parent | child
  static const String _parentIdKey = 'parent_id';
  static const String _childIdKey = 'child_id';

  /// Parent Login
  Future<ApiResponse<AuthResponse>> parentLogin({
    required String email,
    required String password,
  }) async {
    try {
      if (ApiTestMode.enabled) {
        final testResponse = await ApiTestMode.simulateParentLogin(
          email: email,
          password: password,
        );

        if (testResponse.isSuccess && testResponse.data != null) {
          final authResponse = AuthResponse.fromJson(testResponse.data!);
          await _saveAuthData(
            authResponse,
            userRole: 'parent',
            parentId: authResponse.user.id, // الأب نفسه
            childId: null,
          );
          return ApiResponse.success(authResponse);
        } else {
          return ApiResponse.error(testResponse.error ?? 'فشل تسجيل الدخول');
        }
      }

      final request = LoginRequest(email: email, password: password);

      final response = await _apiClient.post<dynamic>(
        ApiConstants.parentLogin,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _saveAuthData(
          authResponse,
          userRole: 'parent',
          parentId: authResponse.user.id,
          childId: null,
        );
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
      if (ApiTestMode.enabled) {
        final testResponse = await ApiTestMode.simulateParentSignup(
          email: email,
          password: password,
          name: name,
          phoneNumber: phoneNumber,
        );

        if (testResponse.isSuccess && testResponse.data != null) {
          final authResponse = AuthResponse.fromJson(testResponse.data!);
          await _saveAuthData(
            authResponse,
            userRole: 'parent',
            parentId: authResponse.user.id,
            childId: null,
          );
          return ApiResponse.success(authResponse);
        } else {
          return ApiResponse.error(testResponse.error ?? 'فشل إنشاء الحساب');
        }
      }

      final request = SignupRequest(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );

      final response = await _apiClient.post<dynamic>(
        ApiConstants.parentRegister,
        body: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);

        // ✅ logs from main branch
        // ignore: avoid_print
        print('✅ [AuthService] User ID: ${authResponse.user.id}');

        // ✅ keep NEW save method from block-app (role/ids)
        await _saveAuthData(
          authResponse,
          userRole: 'parent',
          parentId: authResponse.user.id,
          childId: null,
        );

        return ApiResponse.success(authResponse);
      } else {
        // ✅ logs + better errors from main branch
        // ignore: avoid_print
        print('❌ [AuthService] فشل: ${response.error}');

        String errorMessage = response.error ?? 'فشل إنشاء الحساب';

        if (errorMessage.contains('database is locked')) {
          errorMessage = 'قاعدة البيانات مشغولة حالياً. حاول مرة أخرى بعد بضع ثوانٍ.';
        } else if (errorMessage.contains('unique constraint') ||
            errorMessage.contains('already exists')) {
          errorMessage =
              'هذا البريد الإلكتروني مسجل مسبقاً. استخدم بريدًا آخر أو سجل دخولك مباشرة.';
        } else if (errorMessage.contains('server error') ||
            errorMessage.contains('خطأ في الخادم')) {
          errorMessage =
              'حدث خطأ في الخادم. تأكد من أن الخادم يعمل بشكل صحيح وحاول مرة أخرى.';
        }

        return ApiResponse.error(errorMessage);
      }
    } catch (e, stackTrace) {
      // ✅ keep stackTrace handling from main branch
      // ignore: avoid_print
      print('❌ [AuthService] خطأ في parentSignup: $e');
      // ignore: avoid_print
      print('❌ [AuthService] Error type: ${e.runtimeType}');
      // ignore: avoid_print
      print('❌ [AuthService] Stack trace: $stackTrace');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(
          'لا يمكن الاتصال بالخادم. تأكد من تشغيل الخادم وأن عنوان URL صحيح.',
        );
      } else if (e.toString().contains('TimeoutException')) {
        return ApiResponse.error(
          'انتهت مهلة الاتصال بالخادم. تحقق من اتصال الشبكة.',
        );
      }

      return ApiResponse.error('حدث خطأ أثناء إنشاء الحساب: ${e.toString()}');
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

        await _saveAuthData(
          authResponse,
          userRole: 'child',
          parentId: null,
          childId: authResponse.user.id.isNotEmpty ? authResponse.user.id : null,
        );

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
      final childService = ChildService(apiClient: _apiClient);
      final response = await childService.createChild(
        parentId: parentId,
        email: email,
        password: password,
        name: name,
        age: age,
      );

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        return ApiResponse.error(response.error ?? 'فشل تسجيل الطفل');
      }
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// ✅ Child Login with Data Fetching (الأفضل) - يرجّع Child + يخزن parent_id صح
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
        final childData = response.data as Map<String, dynamic>;

        final childId = childData['id']?.toString() ?? '';
        final parentId = childData['parent_id']?.toString() ?? '';

        final child = Child(
          id: childId,
          parentId: parentId,
          email: childData['email'] ?? '',
          name: childData['name'] ?? '',
          age: 0,
        );

        final authResponse = AuthResponse(
          token: childData['access'] ?? '',
          refreshToken: childData['refresh'] ?? '',
          user: UserData(
            id: childId,
            email: childData['email'] ?? '',
            name: childData['name'] ?? '',
            phoneNumber: '',
            userType: 'child',
          ),
        );

        await _saveAuthData(
          authResponse,
          userRole: 'child',
          parentId: parentId,
          childId: childId,
        );

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
    } catch (_) {
      // ignore
    } finally {
      await _clearAuthData();
      _apiClient.clearAuthToken();
    }
  }

  /// Refresh authentication token
  Future<ApiResponse<AuthResponse>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return ApiResponse.error('No refresh token available');
      }

      final response = await _apiClient.post<dynamic>(
        ApiConstants.refreshToken,
        body: {'refresh': refreshToken},
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);

        // ✅ لا تغيّر role/ids أثناء refresh
        await _saveAuthData(authResponse);

        return ApiResponse.success(authResponse);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to refresh token');
      }
    } catch (e) {
      return ApiResponse.error('Error refreshing token: ${e.toString()}');
    }
  }

  /// ✅ Save authentication data to local storage (معدّل)
  Future<void> _saveAuthData(
    AuthResponse authResponse, {
    String? userRole, // parent | child
    String? parentId, // parent user id
    String? childId, // child user id
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, authResponse.token);
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken);

    final userData = authResponse.user.toJson();
    await prefs.setString(_userDataKey, json.jsonEncode(userData));

    // ✅ role
    if (userRole != null && userRole.isNotEmpty) {
      await prefs.setString(_userRoleKey, userRole);
    }

    // ✅ parent_id
    if (parentId != null && parentId.isNotEmpty) {
      final pInt = int.tryParse(parentId.trim());
      if (pInt != null) {
        await prefs.setInt(_parentIdKey, pInt);
      } else {
        await prefs.setString(_parentIdKey, parentId);
      }
    } else {
      final currentRole = (userRole ?? prefs.getString(_userRoleKey) ?? '').trim();
      if (currentRole == 'parent' && authResponse.user.id.isNotEmpty) {
        final pInt = int.tryParse(authResponse.user.id.trim());
        if (pInt != null) {
          await prefs.setInt(_parentIdKey, pInt);
        } else {
          await prefs.setString(_parentIdKey, authResponse.user.id);
        }
      }
    }

    // ✅ child_id (الأهم)
    if (childId != null && childId.isNotEmpty) {
      final cInt = int.tryParse(childId.trim());
      if (cInt != null) {
        await prefs.setInt(_childIdKey, cInt);
      } else {
        await prefs.setString(_childIdKey, childId);
      }
    } else {
      final userType = authResponse.user.userType.toString();
      if (userType == 'child' && authResponse.user.id.isNotEmpty) {
        final cInt = int.tryParse(authResponse.user.id.trim());
        if (cInt != null) {
          await prefs.setInt(_childIdKey, cInt);
        } else {
          await prefs.setString(_childIdKey, authResponse.user.id);
        }
      }
    }

    // ✅ Update ApiClient tokens safely (keep old call for compatibility)
    // If your ApiClient supports refresh token storage too, prefer setTokens.
    try {
      _apiClient.setTokens(access: authResponse.token, refresh: authResponse.refreshToken);
    } catch (_) {
      _apiClient.setAuthToken(authResponse.token);
    }
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);

    await prefs.remove(_userRoleKey);
    await prefs.remove(_parentIdKey);
    await prefs.remove(_childIdKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getParentId() async {
    final prefs = await SharedPreferences.getInstance();
    final intId = prefs.getInt(_parentIdKey);
    if (intId != null) return intId.toString();
    return prefs.getString(_parentIdKey);
  }

  Future<String?> getChildId() async {
    final prefs = await SharedPreferences.getInstance();
    final intId = prefs.getInt(_childIdKey);
    if (intId != null) return intId.toString();
    return prefs.getString(_childIdKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserData?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      try {
        final userDataMap = json.jsonDecode(userDataString);
        return UserData.fromJson(userDataMap as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> init() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
    }
  }
}
