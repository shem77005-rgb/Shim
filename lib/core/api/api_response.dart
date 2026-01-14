// /// Generic API Response wrapper
// class ApiResponse<T> {
//   final T? data;
//   final String? error;
//   final bool isSuccess;
//
//   ApiResponse._({this.data, this.error, required this.isSuccess});
//
//   /// Success response
//   factory ApiResponse.success(T data) {
//     return ApiResponse._(data: data, isSuccess: true);
//   }
//
//   /// Error response
//   factory ApiResponse.error(String errorMessage) {
//     return ApiResponse._(error: errorMessage, isSuccess: false);
//   }
//
//   /// Check if response has error
//   bool get hasError => !isSuccess;
// }

/// Generic API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  /// ✅ NEW: HTTP status code for debugging/logging
  final int? statusCode;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
    this.statusCode,
  });

  /// Success response
  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
      statusCode: statusCode,
    );
  }

  /// Error response
  factory ApiResponse.error(String errorMessage, {int? statusCode}) {
    return ApiResponse._(
      error: errorMessage,
      isSuccess: false,
      statusCode: statusCode,
    );
  }

  /// Check if response has error
  bool get hasError => !isSuccess;
}
