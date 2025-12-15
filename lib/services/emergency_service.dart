import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../models/emergency_alert_model.dart';

/// Emergency Service - Handles emergency alert operations
class EmergencyService {
  final ApiClient _apiClient;

  EmergencyService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Send emergency alert
  Future<ApiResponse<dynamic>> sendEmergencyAlert({
    required String childId,
    required String parentId,
  }) async {
    try {
      // Validate inputs
      if (childId.isEmpty || parentId.isEmpty) {
        return ApiResponse.error('بيانات المستخدم غير مكتملة');
      }

      final request = EmergencyAlertRequest(
        childId: childId,
        parentId: parentId,
        active: true,
      );

      print(
        '🔵 [EmergencyService] Sending emergency alert for child: $childId, parent: $parentId',
      );
      final response = await _apiClient.post<dynamic>(
        ApiConstants.emergencyAlert,
        body: request.toJson(),
        requiresAuth: true,
      );
      print(
        '🔵 [EmergencyService] Emergency alert response status: ${response.isSuccess}',
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        'حدث خطأ أثناء إرسال تنبيه الطوارئ: ${e.toString()}',
      );
    }
  }
}
