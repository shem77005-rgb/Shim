import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../features/auth/data/services/auth_service.dart';

/// Writing Check Result Model
class WritingCheckResult {
  final String status;
  final String text;
  final bool isAllowed;
  final bool isToxic;
  final double confidence;

  WritingCheckResult({
    required this.status,
    required this.text,
    required this.isAllowed,
    required this.isToxic,
    required this.confidence,
  });

  factory WritingCheckResult.fromJson(Map<String, dynamic> json) {
    return WritingCheckResult(
      status: json['status'] ?? '',
      text: json['text'] ?? '',
      isAllowed: json['is_allowed'] ?? true,
      isToxic: json['is_toxic'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  /// Check if the text should be blocked
  bool get shouldBlock => isToxic || !isAllowed;

  /// Get confidence as percentage
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Writing Check Service - Analyzes text using AI
class WritingCheckService {
  final ApiClient _apiClient;

  // Singleton pattern
  static WritingCheckService? _instance;
  factory WritingCheckService({ApiClient? apiClient}) {
    _instance ??= WritingCheckService._internal(
      apiClient ?? AuthService().apiClient,
    );
    return _instance!;
  }

  WritingCheckService._internal(this._apiClient);

  /// Check if text is appropriate
  Future<ApiResponse<WritingCheckResult>> checkText(String text) async {
    try {
      print('🔵 [WritingCheckService] فحص النص: $text');
      print('🔵 [WritingCheckService] URL: ${ApiConstants.writingCheck}');

      final response = await _apiClient.post<dynamic>(
        ApiConstants.writingCheck,
        body: {'text': text},
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [WritingCheckService] Raw API Response: ${response.data}');
        final result = WritingCheckResult.fromJson(response.data);
        print('✅ [WritingCheckService] Parsed Result:');
        print('   - status: ${result.status}');
        print('   - text: ${result.text}');
        print('   - is_allowed: ${result.isAllowed}');
        print('   - is_toxic: ${result.isToxic}');
        print('   - confidence: ${result.confidence}');
        print('   - shouldBlock: ${result.shouldBlock}');
        return ApiResponse.success(result);
      } else {
        print('❌ [WritingCheckService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل في فحص النص');
      }
    } catch (e) {
      print('❌ [WritingCheckService] خطأ: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Check multiple texts
  Future<List<WritingCheckResult>> checkMultipleTexts(
    List<String> texts,
  ) async {
    final results = <WritingCheckResult>[];
    for (final text in texts) {
      final response = await checkText(text);
      if (response.isSuccess && response.data != null) {
        results.add(response.data!);
      }
    }
    return results;
  }
}
