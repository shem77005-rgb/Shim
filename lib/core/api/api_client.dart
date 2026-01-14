import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_constants.dart';
import 'api_response.dart';

/// API Client
/// مسؤول فقط عن إرسال واستقبال طلبات HTTP
/// ❌ لا يعرف AuthService
/// ❌ لا ينشئ أي Service آخر
class ApiClient {
  final http.Client _httpClient;

  String? _accessToken;
  String? _refreshToken;

  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // ================================================================
  // Token Management (Merged: block-app + main backward compatibility)
  // ================================================================

  /// ✅ New preferred: set both access + refresh
  void setTokens({required String access, String? refresh}) {
    _accessToken = access;
    if (refresh != null && refresh.trim().isNotEmpty) {
      _refreshToken = refresh;
    }
  }

  /// ✅ Sometimes you only have access
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// ✅ Clear tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Backward compatibility (old code uses setAuthToken/clearAuthToken)
  /// ----------------------------------------------------------------

  /// Old name: setAuthToken(token) -> mapped to access token
  void setAuthToken(String token) {
    setAccessToken(token);
  }

  /// Old name: clearAuthToken() -> clears both access+refresh
  void clearAuthToken() {
    clearTokens();
  }

  // ================================================================
  // Headers (Merged)
  // ================================================================

  /// Headers مشتركة
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
      'Accept': ApiConstants.acceptJson,
    };

    if (includeAuth) {
      if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
        // Debug (keep from block-app)
        // ignore: avoid_print
        print('🔵 [ApiClient] Adding Authorization header');
      } else {
        // ignore: avoid_print
        print('⚠️ [ApiClient] Auth required but no access token available');
      }
    }

    return headers;
  }

  // ================================================================
  // Core Request Executor (Merged) + Auto refresh on 401
  // ================================================================

  Future<ApiResponse<T?>> _execute<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool retryOn401 = true,
  }) async {
    try {
      Uri uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParameters.map((k, v) => MapEntry(k, '$v')),
        );
      }

      // Debug (keep from block-app)
      // ignore: avoid_print
      print('🔵 [ApiClient] $method Request');
      // ignore: avoid_print
      print('🔵 [ApiClient] URL: $uri');
      // ignore: avoid_print
      print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
      // ignore: avoid_print
      print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
      // ignore: avoid_print
      print('🔵 [ApiClient] Sending request...');

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
              .timeout(ApiConstants.connectionTimeout);
          break;

        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: _getHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConstants.connectionTimeout);
          break;

        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: _getHeaders(includeAuth: requiresAuth),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(ApiConstants.connectionTimeout);
          break;

        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: _getHeaders(includeAuth: requiresAuth))
              .timeout(ApiConstants.connectionTimeout);
          break;

        default:
          return ApiResponse.error('Unsupported HTTP method: $method');
      }

      // Debug (keep from block-app)
      // ignore: avoid_print
      print('✅ [ApiClient] Response received');
      // ignore: avoid_print
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      // ignore: avoid_print
      print(
        '✅ [ApiClient] Response Body: ${response.body.isEmpty ? "(empty)" : response.body.substring(0, response.body.length > 400 ? 400 : response.body.length)}...',
      );

      // If 401 and token invalid -> try refresh once and retry request
      if (response.statusCode == 401 && requiresAuth && retryOn401) {
        final bodyStr = response.body;
        final bool looksLikeTokenInvalid =
            bodyStr.contains('token_not_valid') ||
                bodyStr.contains('Given token not valid') ||
                bodyStr.contains('Token is invalid') ||
                bodyStr.contains('expired');

        if (looksLikeTokenInvalid) {
          // ignore: avoid_print
          print('🟡 [ApiClient] 401 token invalid -> trying refresh token...');
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // ignore: avoid_print
            print('✅ [ApiClient] Refresh success -> retrying original request...');
            return _execute<T>(
              method,
              endpoint,
              queryParameters: queryParameters,
              body: body,
              requiresAuth: requiresAuth,
              retryOn401: false, // prevent infinite loops
            );
          } else {
            // ignore: avoid_print
            print('❌ [ApiClient] Refresh failed.');
            return ApiResponse.error(
              'انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى',
              statusCode: 401,
            );
          }
        }
      }

      return _handleResponse<T>(response);
    } catch (e, stackTrace) {
      // Debug (keep from block-app)
      // ignore: avoid_print
      print('❌ [ApiClient] Request error: $e');
      // ignore: avoid_print
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      // ignore: avoid_print
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  // ================================================================
  // Refresh Token (block-app kept)
  // ================================================================

  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null || _refreshToken!.trim().isEmpty) {
        // ignore: avoid_print
        print('⚠️ [ApiClient] No refresh token available.');
        return false;
      }

      final uri = Uri.parse(
        '${ApiConstants.fullBaseUrl}${ApiConstants.refreshToken}',
      );

      // ignore: avoid_print
      print('🟣 [ApiClient] POST Refresh Token');
      // ignore: avoid_print
      print('🟣 [ApiClient] URL: $uri');

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': ApiConstants.contentTypeJson,
              'Accept': ApiConstants.acceptJson,
            },
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(ApiConstants.connectionTimeout);

      // ignore: avoid_print
      print('🟣 [ApiClient] Refresh status=${response.statusCode}');
      // ignore: avoid_print
      print(
        '🟣 [ApiClient] Refresh body=${response.body.isEmpty ? "(empty)" : response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['access'] != null) {
          final newAccess = data['access'].toString();
          if (newAccess.trim().isNotEmpty) {
            _accessToken = newAccess;
            // ignore: avoid_print
            print('✅ [ApiClient] Access token refreshed.');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [ApiClient] Refresh failed: $e');
      return false;
    }
  }

  // ================================================================
  // Public Methods (Merged: keep signatures from both branches)
  // ================================================================

  /// GET
  Future<ApiResponse<T?>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) {
    return _execute<T>(
      'GET',
      endpoint,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  /// POST
  Future<ApiResponse<T?>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return _execute<T>(
      'POST',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  /// PUT
  Future<ApiResponse<T?>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _execute<T>(
      'PUT',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  /// DELETE
  Future<ApiResponse<T?>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return _execute<T>(
      'DELETE',
      endpoint,
      requiresAuth: requiresAuth,
    );
  }

  // ================================================================
  // Response Handler (Merged: strong + null-safe)
  // ================================================================

  ApiResponse<T?> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    // Success
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        // main branch behavior (safe null)
        return ApiResponse.success(null, statusCode: statusCode);
      }

      try {
        final jsonData = jsonDecode(response.body);
        return ApiResponse.success(jsonData as T, statusCode: statusCode);
      } catch (_) {
        return ApiResponse.error('فشل في تحليل البيانات', statusCode: statusCode);
      }
    }

    // Auth/session errors
    if (statusCode == 401) {
      return ApiResponse.error(
        'انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى',
        statusCode: statusCode,
      );
    }

    if (statusCode == 403) {
      return ApiResponse.error('غير مصرح لك بالوصول', statusCode: statusCode);
    }

    if (statusCode == 404) {
      return ApiResponse.error('المورد غير موجود (404)', statusCode: statusCode);
    }

    // Server errors with best-effort message extraction (block-app behavior)
    if (statusCode >= 500) {
      // ignore: avoid_print
      print('❌ [ApiClient] Server Error $statusCode - Body: ${response.body}');
      try {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic>) {
          final message =
              jsonData['detail'] ?? jsonData['error'] ?? jsonData['message'];
          if (message != null) {
            return ApiResponse.error(
              'خطأ في الخادم: $message',
              statusCode: statusCode,
            );
          }
        }
      } catch (_) {
        // ignore parsing error
      }
      return ApiResponse.error(
        'خطأ في الخادم. حاول مرة أخرى لاحقًا',
        statusCode: statusCode,
      );
    }

    // Other errors - try parse message (block-app richer handling)
    try {
      final jsonData = jsonDecode(response.body);

      if (jsonData is Map<String, dynamic>) {
        final List<String> errorMessages = [];
        jsonData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errorMessages.add('$key: ${value.first}');
          } else if (value is String) {
            errorMessages.add('$key: $value');
          }
        });

        if (errorMessages.isNotEmpty) {
          return ApiResponse.error(
            errorMessages.join(', '),
            statusCode: statusCode,
          );
        }

        final message = jsonData['message'] ??
            jsonData['detail'] ??
            jsonData['error'] ??
            'حدث خطأ غير معروف';

        return ApiResponse.error(message.toString(), statusCode: statusCode);
      }

      return ApiResponse.error('حدث خطأ غير معروف', statusCode: statusCode);
    } catch (_) {
      if (response.body.contains('database is locked')) {
        return ApiResponse.error(
          'قاعدة البيانات مشغولة. حاول مرة أخرى لاحقًا.',
          statusCode: statusCode,
        );
      }
      return ApiResponse.error('حدث خطأ غير معروف', statusCode: statusCode);
    }
  }

  // ================================================================
  // Error Handler (Merged)
  // ================================================================

  String _handleError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت أو رابط API غير صحيح. تحقق من الإعدادات.';
    }
    if (errorString.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى';
    }
    if (errorString.contains('HandshakeException') ||
        errorString.contains('CERTIFICATE')) {
      return 'خطأ في شهادة SSL. تحقق من رابط الخادم.';
    }
    if (errorString.contains('FormatException')) {
      return 'صيغة البيانات المستلمة غير صحيحة';
    }

    return 'حدث خطأ: $errorString';
  }

  /// إغلاق الـ client
  void dispose() {
    _httpClient.close();
  }
}
