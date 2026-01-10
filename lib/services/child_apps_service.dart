import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';

class ChildAppsService {
  final ApiClient _api;
  ChildAppsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const String _roleKey = 'user_role';
  static const String _accessTokenKey = 'auth_token';

  Future<List<Map<String, dynamic>>> fetchChildApps(int childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString(_roleKey) ?? '').trim().toLowerCase();
      final token = prefs.getString(_accessTokenKey);

      debugPrint('🟪 [ChildAppsService] role=$role childId=$childId');

      if (role != 'parent') {
        debugPrint('🟡 [ChildAppsService] blocked: not parent role');
        return [];
      }
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [ChildAppsService] Missing auth_token');
        return [];
      }

      _api.setAuthToken(token);

      final url = ApiConstants.childApps(childId);
      debugPrint('🟪 [ChildAppsService] GET $url');

      final res = await _api.get<dynamic>(url, requiresAuth: true);

      debugPrint('🟪 [ChildAppsService] status=${res.statusCode} success=${res.isSuccess}');
      debugPrint('🟪 [ChildAppsService] body=${res.data} err=${res.error}');

      if (!res.isSuccess || res.data == null) return [];

      final data = res.data;
      if (data is List) {
        return data.map((e) {
          final m = (e is Map) ? e : <dynamic, dynamic>{};
          return {
            "package": (m["package"] ?? "").toString(),
            "name": (m["name"] ?? "").toString(),
          };
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ [ChildAppsService] error: $e');
      return [];
    }
  }
}
