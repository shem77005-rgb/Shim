import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../models/emergency_alert_model.dart';
import '../models/emergency_alert.dart';

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
      final url = '${ApiConstants.emergencyAlertTrigger}$childId/';
      print('🔵 [EmergencyService] Emergency alert URL: $url');

      final response = await _apiClient.post<dynamic>(
        url,
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

  /// Get all emergency alerts
  Future<ApiResponse<List<EmergencyAlert>>> getAllEmergencyAlerts() async {
    try {
      print('🔵 [EmergencyService] Getting all emergency alerts');

      final response = await _apiClient.get<List<dynamic>>(
        ApiConstants.emergencyAlerts,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final alerts =
            (response.data as List)
                .map(
                  (item) =>
                      EmergencyAlert.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        print(
          '✅ [EmergencyService] Retrieved ${alerts.length} emergency alerts',
        );
        return ApiResponse.success(alerts);
      } else {
        return ApiResponse.error(
          response.error ?? 'Failed to get emergency alerts',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Error getting emergency alerts: ${e.toString()}',
      );
    }
  }

  /// Get emergency alerts for specific child
  Future<ApiResponse<List<EmergencyAlert>>> getEmergencyAlertsByChild({
    required String childId,
  }) async {
    try {
      print(
        '🔵 [EmergencyService] Getting emergency alerts for child: $childId',
      );

      final url = '${ApiConstants.emergencyAlerts}?child_id=$childId';
      final response = await _apiClient.get<List<dynamic>>(
        url,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final alerts =
            (response.data as List)
                .map(
                  (item) =>
                      EmergencyAlert.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        print(
          '✅ [EmergencyService] Retrieved ${alerts.length} emergency alerts for child $childId',
        );
        return ApiResponse.success(alerts);
      } else {
        return ApiResponse.error(
          response.error ?? 'Failed to get emergency alerts for child',
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Error getting emergency alerts for child: ${e.toString()}',
      );
    }
  }
}
