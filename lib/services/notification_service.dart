import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../models/notification_model.dart';
import '../features/auth/data/services/auth_service.dart';

/// Notification Service - Handles notification operations
class NotificationService {
  final ApiClient _apiClient;

  // Singleton pattern
  static NotificationService? _instance;
  factory NotificationService({ApiClient? apiClient}) {
    _instance ??= NotificationService._internal(
      apiClient ?? AuthService().apiClient,
    );
    return _instance!;
  }

  NotificationService._internal(this._apiClient);

  /// Get notifications for a specific parent
  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    String? parentId,
  }) async {
    try {
      print('🔵 [NotificationService] جلب الإشعارات');
      if (parentId != null) {
        print('🔵 [NotificationService] Parent ID: $parentId');
      }

      // Build URL with parent filter if provided
      String url = ApiConstants.notifications;
      if (parentId != null && parentId.isNotEmpty) {
        url = '${ApiConstants.notifications}?parent=$parentId';
      }

      final response = await _apiClient.get<List<dynamic>>(
        url,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [NotificationService] تحليل قائمة الإشعارات...');
        final notifications =
            (response.data as List)
                .map(
                  (item) =>
                      NotificationModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        // Sort by timestamp descending (newest first)
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        print('✅ [NotificationService] عدد الإشعارات: ${notifications.length}');
        return ApiResponse.success(notifications);
      } else {
        print('❌ [NotificationService] فشل: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'فشل الحصول على قائمة الإشعارات',
        );
      }
    } catch (e) {
      print('❌ [NotificationService] خطأ في getNotifications: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Send a notification (POST)
  Future<ApiResponse<NotificationModel>> sendNotification({
    required String title,
    required String description,
    String category = 'system',
    String? parentId,
  }) async {
    try {
      print('🔵 [NotificationService] إرسال إشعار');
      print('🔵 [NotificationService] Title: $title');
      print('🔵 [NotificationService] Description: $description');
      print('🔵 [NotificationService] Category: $category');
      print('🔵 [NotificationService] Parent ID: $parentId');

      final request = NotificationCreateRequest(
        title: title,
        description: description,
        category: category,
        parentId: parentId,
      );

      print('🔵 [NotificationService] Request JSON: ${request.toJson()}');
      print('🔵 [NotificationService] URL: ${ApiConstants.notifications}');

      final response = await _apiClient.post<dynamic>(
        ApiConstants.notifications,
        body: request.toJson(),
        requiresAuth: true,
      );

      print('🔵 [NotificationService] Response success: ${response.isSuccess}');
      if (!response.isSuccess) {
        print('🔵 [NotificationService] Response error: ${response.error}');
      }

      if (response.isSuccess && response.data != null) {
        print('✅ [NotificationService] تم إرسال الإشعار بنجاح');
        final notification = NotificationModel.fromJson(response.data);
        return ApiResponse.success(notification);
      } else {
        print('❌ [NotificationService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل إرسال الإشعار');
      }
    } catch (e) {
      print('❌ [NotificationService] خطأ في sendNotification: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Send emergency notification with child name to specific parent
  Future<ApiResponse<NotificationModel>> sendEmergencyNotification({
    required String childName,
    required String parentId,
  }) async {
    final title = 'تنبيه طوارئ';
    final description = 'الطفل $childName قام بالضغط على زر الطوارئ';

    return sendNotification(
      title: title,
      description: description,
      category:
          'system', // Use 'system' as Django doesn't have 'emergency' category
      parentId: parentId,
    );
  }
}
