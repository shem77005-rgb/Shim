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
  String? _authToken;

  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// تعيين التوكن بعد تسجيل الدخول
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// مسح التوكن عند تسجيل الخروج
  void clearAuthToken() {
    _authToken = null;
  }

  /// Headers مشتركة
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
      'Accept': ApiConstants.acceptJson,
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET
  Future<ApiResponse<T?>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.fullBaseUrl}$endpoint',
      ).replace(queryParameters: queryParameters);

      final response = await _httpClient
          .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  /// POST
  Future<ApiResponse<T?>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      final response = await _httpClient
          .post(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  /// PUT
  Future<ApiResponse<T?>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      final response = await _httpClient
          .put(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  /// DELETE
  Future<ApiResponse<T?>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');

      final response = await _httpClient
          .delete(
            uri,
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  /// معالجة الاستجابة
  ApiResponse<T?> _handleResponse<T>(http.Response response) {
  final statusCode = response.statusCode;

  // حالة النجاح
  if (statusCode >= 200 && statusCode < 300) {
    if (response.body.isEmpty) {
      // عند body فارغ، نعيد null بشكل آمن
      return ApiResponse.success(null);
    }

    try {
      final jsonData = jsonDecode(response.body);
      return ApiResponse.success(jsonData as T);
    } catch (_) {
      return ApiResponse.error('فشل في تحليل البيانات');
    }
  }

  // أخطاء محددة
  if (statusCode == 401) {
    return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
  }

  if (statusCode == 403) {
    return ApiResponse.error('غير مصرح لك بالوصول');
  }

  if (statusCode == 404) {
    return ApiResponse.error('المورد غير موجود');
  }

  if (statusCode >= 500) {
    return ApiResponse.error('خطأ في الخادم، حاول لاحقًا');
  }

  // حالات أخطاء أخرى مع محاولة استخراج الرسالة من JSON
  try {
    final jsonData = jsonDecode(response.body);
    if (jsonData is Map<String, dynamic>) {
      final message = jsonData['detail'] ??
          jsonData['message'] ??
          jsonData['error'] ??
          'حدث خطأ غير معروف';
      return ApiResponse.error(message);
    }
  } catch (_) {
    // إذا لم نستطع تحليل JSON
  }

  return ApiResponse.error('حدث خطأ غير معروف');
}


  /// معالجة الأخطاء العامة
  String _handleError(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'لا يوجد اتصال بالإنترنت';
    }
    if (message.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال';
    }
    if (message.contains('HandshakeException')) {
      return 'خطأ في شهادة الأمان SSL';
    }

    return 'حدث خطأ: $message';
  }

  /// إغلاق الـ client
  void dispose() {
    _httpClient.close();
  }
}
