// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_constants.dart';
// import 'api_response.dart';
//
// /// API Client - Handles all HTTP requests
// class ApiClient {
//   final http.Client _httpClient;
//   String? _authToken;
//
//   ApiClient({http.Client? httpClient})
//     : _httpClient = httpClient ?? http.Client();
//
//   /// Set authentication token
//   void setAuthToken(String token) {
//     _authToken = token;
//   }
//
//   /// Clear authentication token
//   void clearAuthToken() {
//     _authToken = null;
//   }
//
//   /// Get common headers
//   Map<String, String> _getHeaders({bool includeAuth = false}) {
//     final headers = <String, String>{
//       'Content-Type': ApiConstants.contentTypeJson,
//       'Accept': ApiConstants.acceptJson,
//     };
//
//     if (includeAuth && _authToken != null) {
//       headers['Authorization'] = 'Bearer $_authToken';
//       print('🔵 [ApiClient] Adding Authorization header');
//     } else if (includeAuth) {
//       print('⚠️ [ApiClient] Auth required but no token available');
//     }
//
//     return headers;
//   }
//
//   /// GET Request
//   Future<ApiResponse<T>> get<T>(
//     String endpoint, {
//     Map<String, dynamic>? queryParameters,
//     bool requiresAuth = false,
//   }) async {
//     try {
//       final uri = Uri.parse(
//         '${ApiConstants.fullBaseUrl}$endpoint',
//       ).replace(queryParameters: queryParameters);
//
//       print('🔵 [ApiClient] GET Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print(
//         '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
//       );
//
//       final response = await _httpClient
//           .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في GET: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// POST Request
//   Future<ApiResponse<T>> post<T>(
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = false,
//   }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] POST Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print(
//         '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
//       );
//       print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
//       print('🔵 [ApiClient] إرسال الطلب...');
//
//       final response = await _httpClient
//           .post(
//             uri,
//             headers: _getHeaders(includeAuth: requiresAuth),
//             body: body != null ? jsonEncode(body) : null,
//           )
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في POST: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// PUT Request
//   Future<ApiResponse<T>> put<T>(
//     String endpoint, {
//     Map<String, dynamic>? body,
//     bool requiresAuth = true,
//   }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] PUT Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print(
//         '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
//       );
//       print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
//       print('🔵 [ApiClient] إرسال الطلب...');
//
//       final response = await _httpClient
//           .put(
//             uri,
//             headers: _getHeaders(includeAuth: requiresAuth),
//             body: body != null ? jsonEncode(body) : null,
//           )
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في PUT: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// DELETE Request
//   Future<ApiResponse<T>> delete<T>(
//     String endpoint, {
//     bool requiresAuth = true,
//   }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] DELETE Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print(
//         '🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}',
//       );
//
//       final response = await _httpClient
//           .delete(uri, headers: _getHeaders(includeAuth: requiresAuth))
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في DELETE: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// Handle HTTP Response
//   ApiResponse<T> _handleResponse<T>(http.Response response) {
//     final statusCode = response.statusCode;
//
//     if (statusCode >= 200 && statusCode < 300) {
//       try {
//         final jsonData = jsonDecode(response.body);
//         return ApiResponse.success(jsonData);
//       } catch (e) {
//         return ApiResponse.error('فشل في تحليل البيانات');
//       }
//     } else if (statusCode == 401) {
//       return ApiResponse.error('انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى');
//     } else if (statusCode == 403) {
//       return ApiResponse.error('غير مصرح لك بالوصول');
//     } else if (statusCode == 404) {
//       return ApiResponse.error('البريد الألكتروني او كلمة السر غير صحيحة ');
//     } else if (statusCode >= 500) {
//       // Log the actual server error for debugging
//       print('❌ [ApiClient] Server Error 500 - Response Body: ${response.body}');
//       try {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData is Map<String, dynamic>) {
//           final message =
//               jsonData['detail'] ?? jsonData['error'] ?? jsonData['message'];
//           if (message != null) {
//             return ApiResponse.error('خطأ في الخادم: $message');
//           }
//         }
//       } catch (e) {
//         print('❌ [ApiClient] Failed to parse 500 error: $e');
//       }
//       return ApiResponse.error('خطأ في الخادم. حاول مرة أخرى لاحقًا');
//     } else {
//       try {
//         final jsonData = jsonDecode(response.body);
//
//         // Check for field-specific validation errors (Django REST Framework format)
//         if (jsonData is Map<String, dynamic>) {
//           // Collect all field errors
//           final List<String> errorMessages = [];
//           jsonData.forEach((key, value) {
//             if (value is List && value.isNotEmpty) {
//               errorMessages.add('$key: ${value.first}');
//             } else if (value is String) {
//               errorMessages.add('$key: $value');
//             }
//           });
//
//           if (errorMessages.isNotEmpty) {
//             return ApiResponse.error(errorMessages.join(', '));
//           }
//         }
//
//         // Check for different possible error message formats
//         final message =
//             jsonData['message'] ??
//             jsonData['detail'] ??
//             jsonData['error'] ??
//             'حدث خطأ غير معروف';
//         return ApiResponse.error(message);
//       } catch (e) {
//         // If we can't parse JSON, return the raw response body if it contains useful info
//         if (response.body.contains('database is locked')) {
//           return ApiResponse.error(
//             'قاعدة البيانات مشغولة. حاول مرة أخرى لاحقًا.',
//           );
//         }
//         return ApiResponse.error('حدث خطأ غير معروف');
//       }
//     }
//   }
//
//   /// Handle Errors
//   String _handleError(dynamic error) {
//     final errorString = error.toString();
//
//     if (errorString.contains('SocketException') ||
//         errorString.contains('Failed host lookup')) {
//       return 'لا يوجد اتصال بالإنترنت أو رابط API غير صحيح. تحقق من الإعدادات.';
//     } else if (errorString.contains('TimeoutException')) {
//       return 'انتهت مهلة الاتصال. حاول مرة أخرى';
//     } else if (errorString.contains('HandshakeException') ||
//         errorString.contains('CERTIFICATE')) {
//       return 'خطأ في شهادة SSL. تحقق من رابط الخادم.';
//     } else if (errorString.contains('FormatException')) {
//       return 'صيغة البيانات المستلمة غير صحيحة';
//     } else {
//       // More detailed error reporting
//       return 'حدث خطأ: $errorString';
//     }
//   }
//
//   /// Dispose
//   void dispose() {
//     _httpClient.close();
//   }
// }

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'api_constants.dart';
// import 'api_response.dart';
//
// /// API Client - Handles all HTTP requests
// class ApiClient {
//   final http.Client _httpClient;
//   String? _authToken;
//
//   ApiClient({http.Client? httpClient})
//       : _httpClient = httpClient ?? http.Client();
//
//   /// Set authentication token
//   void setAuthToken(String token) {
//     _authToken = token;
//   }
//
//   /// Clear authentication token
//   void clearAuthToken() {
//     _authToken = null;
//   }
//
//   /// Get common headers
//   Map<String, String> _getHeaders({bool includeAuth = false}) {
//     final headers = <String, String>{
//       'Content-Type': ApiConstants.contentTypeJson,
//       'Accept': ApiConstants.acceptJson,
//     };
//
//     if (includeAuth && _authToken != null) {
//       headers['Authorization'] = 'Bearer $_authToken';
//       print('🔵 [ApiClient] Adding Authorization header');
//     } else if (includeAuth) {
//       print('⚠️ [ApiClient] Auth required but no token available');
//     }
//
//     return headers;
//   }
//
//   /// GET Request
//   Future<ApiResponse<T>> get<T>(
//       String endpoint, {
//         Map<String, dynamic>? queryParameters,
//         bool requiresAuth = false,
//       }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint')
//           .replace(queryParameters: queryParameters);
//
//       print('🔵 [ApiClient] GET Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
//
//       final response = await _httpClient
//           .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في GET: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// POST Request
//   Future<ApiResponse<T>> post<T>(
//       String endpoint, {
//         Map<String, dynamic>? body,
//         bool requiresAuth = false,
//       }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] POST Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
//       print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
//       print('🔵 [ApiClient] إرسال الطلب...');
//
//       final response = await _httpClient
//           .post(
//         uri,
//         headers: _getHeaders(includeAuth: requiresAuth),
//         body: body != null ? jsonEncode(body) : null,
//       )
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في POST: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// PUT Request
//   Future<ApiResponse<T>> put<T>(
//       String endpoint, {
//         Map<String, dynamic>? body,
//         bool requiresAuth = true,
//       }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] PUT Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
//       print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
//       print('🔵 [ApiClient] إرسال الطلب...');
//
//       final response = await _httpClient
//           .put(
//         uri,
//         headers: _getHeaders(includeAuth: requiresAuth),
//         body: body != null ? jsonEncode(body) : null,
//       )
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في PUT: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// DELETE Request
//   Future<ApiResponse<T>> delete<T>(
//       String endpoint, {
//         bool requiresAuth = true,
//       }) async {
//     try {
//       final uri = Uri.parse('${ApiConstants.fullBaseUrl}$endpoint');
//
//       print('🔵 [ApiClient] DELETE Request');
//       print('🔵 [ApiClient] URL: $uri');
//       print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
//
//       final response = await _httpClient
//           .delete(uri, headers: _getHeaders(includeAuth: requiresAuth))
//           .timeout(ApiConstants.connectionTimeout);
//
//       print('✅ [ApiClient] استلام الاستجابة');
//       print('✅ [ApiClient] Status Code: ${response.statusCode}');
//       print(
//         '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
//       );
//
//       return _handleResponse<T>(response);
//     } catch (e, stackTrace) {
//       print('❌ [ApiClient] خطأ في DELETE: $e');
//       print('❌ [ApiClient] Error type: ${e.runtimeType}');
//       print('❌ [ApiClient] Stack trace: $stackTrace');
//       return ApiResponse.error(_handleError(e));
//     }
//   }
//
//   /// Handle HTTP Response
//   ApiResponse<T> _handleResponse<T>(http.Response response) {
//     final statusCode = response.statusCode;
//
//     if (statusCode >= 200 && statusCode < 300) {
//       try {
//         final jsonData = jsonDecode(response.body);
//         return ApiResponse.success(jsonData as T, statusCode: statusCode);
//       } catch (e) {
//         return ApiResponse.error('فشل في تحليل البيانات', statusCode: statusCode);
//       }
//     } else if (statusCode == 401) {
//       return ApiResponse.error(
//         'انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى',
//         statusCode: statusCode,
//       );
//     } else if (statusCode == 403) {
//       return ApiResponse.error('غير مصرح لك بالوصول', statusCode: statusCode);
//     } else if (statusCode == 404) {
//       return ApiResponse.error(
//         'البريد الألكتروني او كلمة السر غير صحيحة ',
//         statusCode: statusCode,
//       );
//     } else if (statusCode >= 500) {
//       // Log the actual server error for debugging
//       print('❌ [ApiClient] Server Error 500 - Response Body: ${response.body}');
//       try {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData is Map<String, dynamic>) {
//           final message =
//               jsonData['detail'] ?? jsonData['error'] ?? jsonData['message'];
//           if (message != null) {
//             return ApiResponse.error('خطأ في الخادم: $message', statusCode: statusCode);
//           }
//         }
//       } catch (e) {
//         print('❌ [ApiClient] Failed to parse 500 error: $e');
//       }
//       return ApiResponse.error('خطأ في الخادم. حاول مرة أخرى لاحقًا', statusCode: statusCode);
//     } else {
//       try {
//         final jsonData = jsonDecode(response.body);
//
//         // Check for field-specific validation errors (Django REST Framework format)
//         if (jsonData is Map<String, dynamic>) {
//           // Collect all field errors
//           final List<String> errorMessages = [];
//           jsonData.forEach((key, value) {
//             if (value is List && value.isNotEmpty) {
//               errorMessages.add('$key: ${value.first}');
//             } else if (value is String) {
//               errorMessages.add('$key: $value');
//             }
//           });
//
//           if (errorMessages.isNotEmpty) {
//             return ApiResponse.error(errorMessages.join(', '), statusCode: statusCode);
//           }
//         }
//
//         // Check for different possible error message formats
//         final message =
//         (jsonData is Map<String, dynamic>)
//             ? (jsonData['message'] ?? jsonData['detail'] ?? jsonData['error'] ?? 'حدث خطأ غير معروف')
//             : 'حدث خطأ غير معروف';
//
//         return ApiResponse.error(message.toString(), statusCode: statusCode);
//       } catch (e) {
//         // If we can't parse JSON, return the raw response body if it contains useful info
//         if (response.body.contains('database is locked')) {
//           return ApiResponse.error(
//             'قاعدة البيانات مشغولة. حاول مرة أخرى لاحقًا.',
//             statusCode: statusCode,
//           );
//         }
//         return ApiResponse.error('حدث خطأ غير معروف', statusCode: statusCode);
//       }
//     }
//   }
//
//   /// Handle Errors
//   String _handleError(dynamic error) {
//     final errorString = error.toString();
//
//     if (errorString.contains('SocketException') ||
//         errorString.contains('Failed host lookup')) {
//       return 'لا يوجد اتصال بالإنترنت أو رابط API غير صحيح. تحقق من الإعدادات.';
//     } else if (errorString.contains('TimeoutException')) {
//       return 'انتهت مهلة الاتصال. حاول مرة أخرى';
//     } else if (errorString.contains('HandshakeException') ||
//         errorString.contains('CERTIFICATE')) {
//       return 'خطأ في شهادة SSL. تحقق من رابط الخادم.';
//     } else if (errorString.contains('FormatException')) {
//       return 'صيغة البيانات المستلمة غير صحيحة';
//     } else {
//       // More detailed error reporting
//       return 'حدث خطأ: $errorString';
//     }
//   }
//
//   /// Dispose
//   void dispose() {
//     _httpClient.close();
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_constants.dart';
import 'api_response.dart';

/// API Client - Handles all HTTP requests
class ApiClient {
  final http.Client _httpClient;

  String? _accessToken;
  String? _refreshToken;

  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // ================================================================
  // Token Management
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

  /// Old name: setAuthToken(token)
  /// We map it to access token.
  void setAuthToken(String token) {
    setAccessToken(token);
  }

  /// Old name: clearAuthToken()
  /// We clear both access+refresh to avoid stale session.
  void clearAuthToken() {
    clearTokens();
  }

  // ================================================================
  // Headers
  // ================================================================

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': ApiConstants.contentTypeJson,
      'Accept': ApiConstants.acceptJson,
    };

    if (includeAuth) {
      if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
        print('🔵 [ApiClient] Adding Authorization header');
      } else {
        print('⚠️ [ApiClient] Auth required but no access token available');
      }
    }

    return headers;
  }

  // ================================================================
  // Core Request Executor (with auto refresh on 401)
  // ================================================================

  Future<ApiResponse<T>> _execute<T>(
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
        uri = uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, '$v')));
      }

      print('🔵 [ApiClient] $method Request');
      print('🔵 [ApiClient] URL: $uri');
      print('🔵 [ApiClient] Headers: ${_getHeaders(includeAuth: requiresAuth)}');
      print('🔵 [ApiClient] Body: ${body != null ? jsonEncode(body) : "null"}');
      print('🔵 [ApiClient] Sending request...');

      http.Response response;

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

      print('✅ [ApiClient] Response received');
      print('✅ [ApiClient] Status Code: ${response.statusCode}');
      print(
        '✅ [ApiClient] Response Body: ${response.body.substring(0, response.body.length > 400 ? 400 : response.body.length)}...',
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
          print('🟡 [ApiClient] 401 token invalid -> trying refresh token...');
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
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
      print('❌ [ApiClient] Request error: $e');
      print('❌ [ApiClient] Error type: ${e.runtimeType}');
      print('❌ [ApiClient] Stack trace: $stackTrace');
      return ApiResponse.error(_handleError(e));
    }
  }

  // ================================================================
  // Refresh Token
  // ================================================================

  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null || _refreshToken!.trim().isEmpty) {
        print('⚠️ [ApiClient] No refresh token available.');
        return false;
      }

      final uri = Uri.parse('${ApiConstants.fullBaseUrl}${ApiConstants.refreshToken}');
      print('🟣 [ApiClient] POST Refresh Token');
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

      print('🟣 [ApiClient] Refresh status=${response.statusCode}');
      print('🟣 [ApiClient] Refresh body=${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['access'] != null) {
          final newAccess = data['access'].toString();
          if (newAccess.trim().isNotEmpty) {
            _accessToken = newAccess;
            print('✅ [ApiClient] Access token refreshed.');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('❌ [ApiClient] Refresh failed: $e');
      return false;
    }
  }

  // ================================================================
  // Public Methods
  // ================================================================

  /// GET Request
  Future<ApiResponse<T>> get<T>(
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

  /// POST Request
  Future<ApiResponse<T>> post<T>(
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

  /// PUT Request
  Future<ApiResponse<T>> put<T>(
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

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
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
  // Response Handler
  // ================================================================

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final jsonData = jsonDecode(response.body);
        return ApiResponse.success(jsonData as T, statusCode: statusCode);
      } catch (e) {
        return ApiResponse.error('فشل في تحليل البيانات', statusCode: statusCode);
      }
    } else if (statusCode == 401) {
      return ApiResponse.error(
        'انتهت جلسة العمل. يرجى تسجيل الدخول مرة أخرى',
        statusCode: statusCode,
      );
    } else if (statusCode == 403) {
      return ApiResponse.error('غير مصرح لك بالوصول', statusCode: statusCode);
    } else if (statusCode == 404) {
      return ApiResponse.error(
        'المورد غير موجود (404)',
        statusCode: statusCode,
      );
    } else if (statusCode >= 500) {
      print('❌ [ApiClient] Server Error 500 - Response Body: ${response.body}');
      try {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map<String, dynamic>) {
          final message = jsonData['detail'] ?? jsonData['error'] ?? jsonData['message'];
          if (message != null) {
            return ApiResponse.error('خطأ في الخادم: $message', statusCode: statusCode);
          }
        }
      } catch (e) {
        print('❌ [ApiClient] Failed to parse 500 error: $e');
      }
      return ApiResponse.error('خطأ في الخادم. حاول مرة أخرى لاحقًا', statusCode: statusCode);
    } else {
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
            return ApiResponse.error(errorMessages.join(', '), statusCode: statusCode);
          }
        }

        final message =
        (jsonData is Map<String, dynamic>) ? (jsonData['message'] ?? jsonData['detail'] ?? jsonData['error'] ?? 'حدث خطأ غير معروف') : 'حدث خطأ غير معروف';

        return ApiResponse.error(message.toString(), statusCode: statusCode);
      } catch (e) {
        if (response.body.contains('database is locked')) {
          return ApiResponse.error(
            'قاعدة البيانات مشغولة. حاول مرة أخرى لاحقًا.',
            statusCode: statusCode,
          );
        }
        return ApiResponse.error('حدث خطأ غير معروف', statusCode: statusCode);
      }
    }
  }

  // ================================================================
  // Error Handler
  // ================================================================

  String _handleError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException') || errorString.contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت أو رابط API غير صحيح. تحقق من الإعدادات.';
    } else if (errorString.contains('TimeoutException')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى';
    } else if (errorString.contains('HandshakeException') || errorString.contains('CERTIFICATE')) {
      return 'خطأ في شهادة SSL. تحقق من رابط الخادم.';
    } else if (errorString.contains('FormatException')) {
      return 'صيغة البيانات المستلمة غير صحيحة';
    } else {
      return 'حدث خطأ: $errorString';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

