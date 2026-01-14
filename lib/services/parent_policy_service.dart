import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';

class ParentPolicyService {
  final ApiClient _api;
  ParentPolicyService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const String _roleKey = 'user_role';
  static const String _accessTokenKey = 'auth_token';

  Future<bool> savePolicyForChild({
    required int childId,
    required List<Map<String, dynamic>> rules, // [{package, limit_ms}]
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString(_roleKey) ?? '').trim().toLowerCase();
      final token = prefs.getString(_accessTokenKey);

      debugPrint('🟪 [ParentPolicy] role=$role childId=$childId rulesCount=${rules.length}');

      if (role != 'parent') {
        debugPrint('🟡 [ParentPolicy] blocked: not parent role');
        return false;
      }
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [ParentPolicy] Missing auth_token');
        return false;
      }

      _api.setAuthToken(token);

      final payload = {"rules": rules};

      final url = ApiConstants.childPolicyForParent(childId);
      debugPrint('🟪 [ParentPolicy] PUT $url');
      debugPrint('🟪 [ParentPolicy] payload=${jsonEncode(payload)}');

      final res = await _api.put<dynamic>(
        url,
        body: payload,
        requiresAuth: true,
      );

      debugPrint('🟪 [ParentPolicy] status=${res.statusCode} success=${res.isSuccess}');
      debugPrint('🟪 [ParentPolicy] body=${res.data} err=${res.error}');

      return res.isSuccess;
    } catch (e) {
      debugPrint('❌ [ParentPolicy] error: $e');
      return false;
    }
  }
}
