import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../models/child_model.dart';
import '../features/auth/data/services/auth_service.dart';

/// Child Service - Handles all child-related operations
class ChildService {
  final ApiClient _apiClient;

  // Singleton pattern
  static ChildService? _instance;
  factory ChildService({ApiClient? apiClient}) {
    _instance ??= ChildService._internal(apiClient ?? AuthService().apiClient);
    return _instance!;
  }

  ChildService._internal(this._apiClient);

  /// Validate if parent exists in the database
  Future<ApiResponse<bool>> validateParentExists({
    required String parentId,
  }) async {
    try {
      print('🔵 [ChildService] التحقق من وجود الحساب الأب');
      print('🔵 [ChildService] Parent ID: $parentId');

      // Get all parents from the API to check if parentId exists
      // This is a simplified approach - in a real app, you would have a specific endpoint
      // to check if a parent exists
      final response = await _apiClient.get<List<dynamic>>(
        '/api/parents/', // You might need to adjust this endpoint
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // Check if parentId exists in the list of parents
        final parents = response.data as List;
        final parentExists = parents.any(
          (parent) =>
              (parent is Map<String, dynamic> &&
                  parent['id']?.toString() == parentId) ||
              (parent is Map &&
                  parent.containsKey('id') &&
                  parent['id']?.toString() == parentId),
        );

        print('✅ [ChildService] نتيجة التحقق: $parentExists');
        return ApiResponse.success(parentExists);
      } else {
        print('❌ [ChildService] فشل التحقق: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'فشل التحقق من وجود الحساب الأب',
        );
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في validateParentExists: $e');
      return ApiResponse.error(
        'حدث خطأ أثناء التحقق من الحساب الأب: ${e.toString()}',
      );
    }
  }

  /// Create a new child
  Future<ApiResponse<Child>> createChild({
    required String parentId,
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    try {
      print('🔵 [ChildService] بدء عملية إنشاء طفل');
      print('🔵 [ChildService] Parent ID: $parentId, Child Name: $name');

      // The parent should already be authenticated to make this request
      // If the request succeeds, it means the parent is valid
      // We'll rely on the backend to validate the parent-child relationship

      final request = ChildCreateRequest(
        parentId: parentId,
        email: email,
        password: password,
        name: name,
        age: age,
      );

      print('🔵 [ChildService] Request JSON: ${request.toJson()}');
      print('🔵 [ChildService] URL: ${ApiConstants.fullBaseUrl}/api/children/');
      print('🔵 [ChildService] محاولة الاتصال بالخادم...');

      final startTime = DateTime.now();

      print(
        '🔵 [ChildService] Sending request with parent ID: ${request.parentId}',
      );

      final response = await _apiClient.post<dynamic>(
        '/api/children/',
        body: request.toJson(),
        requiresAuth: true,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print(
        '🔵 [ChildService] استلام الاستجابة بعد: ${duration.inSeconds}.${duration.inMilliseconds % 1000}s',
      );
      print('🔵 [ChildService] Response success: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        print('✅ [ChildService] تحليل بيانات الطفل...');
        final child = Child.fromJson(response.data);
        print('✅ [ChildService] Child ID: ${child.id}');
        return ApiResponse.success(child);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل إنشاء الطفل');
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في createChild: $e');
      print('❌ [ChildService] Error type: ${e.runtimeType}');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Get all children for a parent
  Future<ApiResponse<List<Child>>> getParentChildren({
    required String parentId,
  }) async {
    try {
      print('🔵 [ChildService] الحصول على قائمة الأطفال');
      print('🔵 [ChildService] Parent ID: $parentId');
      print('🔵 [ChildService] Request URL: /api/children/?parent=$parentId');

      final response = await _apiClient.get<List<dynamic>>(
        '/api/children/?parent=$parentId',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [ChildService] تحليل قائمة الأطفال...');
        final children =
            (response.data as List)
                .map((item) => Child.fromJson(item as Map<String, dynamic>))
                .toList();
        print('✅ [ChildService] عدد الأطفال: ${children.length}');
        return ApiResponse.success(children);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'فشل الحصول على قائمة الأطفال',
        );
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في getParentChildren: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Get all children (without parent filter)
  Future<ApiResponse<List<Child>>> getAllChildren() async {
    try {
      print('🔵 [ChildService] الحصول على جميع الأطفال');

      final response = await _apiClient.get<List<dynamic>>(
        '/api/children/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [ChildService] تحليل قائمة الأطفال...');
        final children =
            (response.data as List)
                .map((item) => Child.fromJson(item as Map<String, dynamic>))
                .toList();
        print('✅ [ChildService] عدد الأطفال: ${children.length}');
        return ApiResponse.success(children);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'فشل الحصول على قائمة الأطفال',
        );
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في getAllChildren: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Get a specific child by ID
  Future<ApiResponse<Child>> getChild({required String childId}) async {
    try {
      print('🔵 [ChildService] الحصول على بيانات طفل');
      print('🔵 [ChildService] Child ID: $childId');

      final response = await _apiClient.get<dynamic>(
        '/api/children/$childId/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [ChildService] تحليل بيانات الطفل...');
        final child = Child.fromJson(response.data);
        return ApiResponse.success(child);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'فشل الحصول على بيانات الطفل',
        );
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في getChild: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Update child information
  Future<ApiResponse<Child>> updateChild({
    required String childId,
    String? email,
    String? name,
    int? age,
  }) async {
    try {
      print('🔵 [ChildService] تحديث بيانات طفل');
      print('🔵 [ChildService] Child ID: $childId');

      final Map<String, dynamic> updateData = {};
      if (email != null) updateData['email'] = email;
      if (name != null) updateData['name'] = name;
      if (age != null) updateData['age'] = age;

      print('🔵 [ChildService] بيانات التحديث: $updateData');

      final response = await _apiClient.put<dynamic>(
        '/api/children/$childId/',
        body: updateData,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ [ChildService] تحليل بيانات الطفل المحدثة...');
        final child = Child.fromJson(response.data);
        return ApiResponse.success(child);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل تحديث بيانات الطفل');
      }
    } catch (e, stackTrace) {
      print('❌ [ChildService] خطأ في updateChild: $e');
      print('❌ [ChildService] Stack trace: $stackTrace');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  /// Delete a child
  Future<ApiResponse<void>> deleteChild({required String childId}) async {
    try {
      print('🔵 [ChildService] حذف طفل');
      print('🔵 [ChildService] Child ID: $childId');

      final response = await _apiClient.delete<void>(
        '/api/children/$childId/',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ [ChildService] تم حذف الطفل بنجاح');
        return ApiResponse.success(null);
      } else {
        print('❌ [ChildService] فشل: ${response.error}');
        return ApiResponse.error(response.error ?? 'فشل حذف الطفل');
      }
    } catch (e) {
      print('❌ [ChildService] خطأ في deleteChild: $e');
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }
}
