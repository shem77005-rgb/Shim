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
      String url = ApiConstants.notificationsByUser;
      if (parentId != null && parentId.isNotEmpty) {
        url = '${ApiConstants.notificationsByUser}?user=$parentId';
      }

      final response = await _apiClient.get<List<dynamic>>(
        url,
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [NotificationService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [NotificationService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.get<List<dynamic>>(
            url,
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            print('✅ [NotificationService] تحليل قائمة الإشعارات...');
            final notifications =
                (retryResponse.data as List)
                    .map(
                      (item) => NotificationModel.fromJson(
                        item as Map<String, dynamic>,
                      ),
                    )
                    .toList();

            // Sort by timestamp descending (newest first)
            notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            print(
              '✅ [NotificationService] عدد الإشعارات: ${notifications.length}',
            );
            return ApiResponse.success(notifications);
          } else {
            print(
              '❌ [NotificationService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'فشل الحصول على قائمة الإشعارات',
            );
          }
        } else {
          print(
            '❌ [NotificationService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

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
    required String childId, // Required child ID for the new API
  }) async {
    try {
      print('🔵 [NotificationService] إرسال إشعار');
      print('🔵 [NotificationService] Title: $title');
      print('🔵 [NotificationService] Description: $description');
      print('🔵 [NotificationService] Category: $category');
      print('🔵 [NotificationService] Parent ID: $parentId');
      print('🔵 [NotificationService] Child ID: $childId');

      // Prepare request body according to new API specification
      final requestBody = {
        'child_id': int.tryParse(childId) ?? childId,
        'title': title,
        'description': description,
        'category': category,
      };

      print('🔵 [NotificationService] Request JSON: $requestBody');
      print('🔵 [NotificationService] URL: ${ApiConstants.notificationsSend}');

      final response = await _apiClient.post<dynamic>(
        ApiConstants.notificationsSend,
        body: requestBody,
        requiresAuth: true,
      );

      print('🔵 [NotificationService] Response success: ${response.isSuccess}');
      if (!response.isSuccess) {
        print('🔵 [NotificationService] Response error: ${response.error}');
      }

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [NotificationService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [NotificationService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.post<dynamic>(
            ApiConstants.notificationsSend,
            body: requestBody,
            requiresAuth: true,
          );

          print(
            '🔵 [NotificationService] Retry response success: ${retryResponse.isSuccess}',
          );
          if (!retryResponse.isSuccess) {
            print(
              '🔵 [NotificationService] Retry response error: ${retryResponse.error}',
            );
          }

          if (retryResponse.isSuccess && retryResponse.data != null) {
            print('✅ [NotificationService] تم إرسال الإشعار بنجاح');
            final notification = NotificationModel.fromJson(retryResponse.data);
            return ApiResponse.success(notification);
          } else {
            print(
              '❌ [NotificationService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'فشل إرسال الإشعار',
            );
          }
        } else {
          print(
            '❌ [NotificationService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
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
    required String childId,
  }) async {
    final title = 'تنبيه طوارئ';
    final description = 'الطفل $childName قام بالضغط على زر الطوارئ';

    return sendNotification(
      title: title,
      description: description,
      category:
          'system', // Use 'system' as Django doesn't have 'emergency' category
      parentId: parentId,
      childId: childId,
    );
  }

  /// Delete all notifications for a specific parent
  Future<ApiResponse<void>> deleteNotificationsByParent({
    required String parentId,
  }) async {
    try {
      print('🔵 [NotificationService] حذف الإشعارات للوالد: $parentId');

      final url = '${ApiConstants.deleteNotificationsByParent}$parentId/';
      print('🔵 [NotificationService] URL: $url');

      final response = await _apiClient.delete<void>(url, requiresAuth: true);

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [NotificationService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [NotificationService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.delete<void>(
            url,
            requiresAuth: true,
          );

          if (retryResponse.isSuccess) {
            print('✅ [NotificationService] تم حذف الإشعارات بنجاح');
            return ApiResponse.success(null);
          } else {
            print(
              '❌ [NotificationService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'فشل حذف الإشعارات',
            );
          }
        } else {
          print(
            '❌ [NotificationService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess) {
        print('✅ [NotificationService] تم حذف الإشعارات بنجاح');
        return ApiResponse.success(null);
      } else {
        print('❌ [NotificationService] فشل الحذف: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل حذف الإشعارات');
      }
    } catch (e) {
      print('❌ [NotificationService] خطأ في deleteNotificationsByParent: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Delete a specific notification by ID
  Future<ApiResponse<void>> deleteNotificationById({
    required int notificationId,
  }) async {
    try {
      print('🔵 [NotificationService] حذف الإشعار بالرقم: $notificationId');

      final url = '${ApiConstants.deleteNotificationById}$notificationId/';
      print('🔵 [NotificationService] URL: $url');

      // For DELETE requests, sometimes the response body is empty
      // We'll handle this case specially
      final response = await _apiClient.delete<dynamic>(
        url,
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [NotificationService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [NotificationService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.delete<dynamic>(
            url,
            requiresAuth: true,
          );

          if (retryResponse.isSuccess) {
            print('✅ [NotificationService] تم حذف الإشعار بنجاح');
            return ApiResponse.success(null);
          } else {
            print(
              '❌ [NotificationService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(retryResponse.error ?? 'فشل حذف الإشعار');
          }
        } else {
          print(
            '❌ [NotificationService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess) {
        print('✅ [NotificationService] تم حذف الإشعار بنجاح');
        return ApiResponse.success(null);
      } else {
        print('❌ [NotificationService] فشل الحذف: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل حذف الإشعار');
      }
    } catch (e) {
      print('❌ [NotificationService] خطأ في deleteNotificationById: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }
}
