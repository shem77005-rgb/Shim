import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_response.dart';

/// API Client - Handles all HTTP requests
class ApiClient {
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get common headers
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
      'Accept': ApiConstants.acceptJson,
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('🔵 [ApiClient] Adding Authorization header');
    } else if (includeAuth) {
      print('⚠️ [ApiClient] Auth required but no token available');
    }

    return headers;
  }

  /// GET Request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.fullBaseUrl}$endpoint',
      ).replace(queryParameters: queryParameters);

      print('🔵 [ApiClient] GET Request');
      print('🔵 [ApiClient] URL: $uri');
      print(
        '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
      );

      final response = await _httpClient
          .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
          .timeout(ApiConstants.connectionTimeout);

      print('✅ [ApiClient] استلام الاستجابة');
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      print(
        '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      return _handleResponse<T>(response);
    } catch (e, stackTrace) {
      print('❌ [ApiClient] خطأ في GET: $e');
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  /// POST Request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      print('🔵 [ApiClient] POST Request');
      print('🔵 [ApiClient] URL: $uri');
      print(
        '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
      );
      print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
      print('🔵 [ApiClient] إرسال الطلب...');

      final response = await _httpClient
          .post(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      print('✅ [ApiClient] استلام الاستجابة');
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      print(
        '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      return _handleResponse<T>(response);
    } catch (e, stackTrace) {
      print('❌ [ApiClient] خطأ في POST: $e');
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  /// PUT Request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      print('🔵 [ApiClient] PUT Request');
      print('🔵 [ApiClient] URL: $uri');
      print(
        '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
      );
      print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
      print('🔵 [ApiClient] إرسال الطلب...');

      final response = await _httpClient
          .put(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      print('✅ [ApiClient] استلام الاستجابة');
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      print(
        '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      return _handleResponse<T>(response);
    } catch (e, stackTrace) {
      print('❌ [ApiClient] خطأ في PUT: $e');
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      print('🔵 [ApiClient] DELETE Request');
      print('🔵 [ApiClient] URL: $uri');
      print(
        '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
      );

      final response = await _httpClient
          .delete(uri, headers: _getHeaders(includeAuth: requiresAuth))
          .timeout(ApiConstants.connectionTimeout);

      print('✅ [ApiClient] استلام الاستجابة');
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      print(
        '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      return _handleResponse<T>(response);
    } catch (e, stackTrace) {
      print('❌ [ApiClient] خطأ في DELETE: $e');
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  /// Handle HTTP Response
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final jsonData = jsonDecode(response.body);
        return ApiResponse.success(jsonData);
      } catch (e) {
        return ApiResponse.error('فشل في تحليل البيانات');
      }
    } else if (statusCode == 401) {
      return ApiResponse.error('انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى');
    } else if (statusCode == 403) {
      return ApiResponse.error('غير مصرح لك بالوصول');
    } else if (statusCode == 404) {
      return ApiResponse.error('البريد الألكتروني او كلمة السر غير صحيحة ');
    } else if (statusCode >= 500) {
      return ApiResponse.error('خطأ في الخادم. حاول مرة أخرى لاحقًا');
    } else {
      try {
        final jsonData = jsonDecode(response.body);
        // Check for different possible error message formats
        final message =
            jsonData['message'] ??
            jsonData['detail'] ??
            jsonData['error'] ??
            'حدث خطأ غير معروف';
        return ApiResponse.error(message);
      } catch (e) {
        // If we can't parse JSON, return the raw response body if it contains useful info
        if (response.body.contains('database is locked')) {
          return ApiResponse.error(
            'قاعدة البيانات مشغولة. حاول مرة أخرى لاحقًا.',
          );
        }
        return ApiResponse.error('حدث خطأ غير معروف');
      }
    }
  }

  /// Handle Errors
  String _handleError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت أو رابط API غير صحيح. تحقق من الإعدادات.';
    } else if (errorString.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى';
    } else if (errorString.contains('HandshakeException') ||
        errorString.contains('CERTIFICATE')) {
      return 'خطأ في شهادة SSL. تحقق من رابط الخادم.';
    } else if (errorString.contains('FormatException')) {
      return 'صيغة البيانات المستلمة غير صحيحة';
    } else {
      // More detailed error reporting
      return 'حدث خطأ: $errorString';
    }
  }

  /// Dispose
  void dispose() {
    _httpClient.close();
  }
}
