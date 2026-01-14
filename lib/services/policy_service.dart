import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../services/firebase_messaging_service.dart';

class PolicyService {
  final ApiClient _api;
  PolicyService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<bool> fetchAndApplyChildPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString('user_role') ?? '').trim().toLowerCase();
      final childId = prefs.getInt('child_id') ?? int.tryParse((prefs.getString('child_id') ?? '').trim());

      debugPrint('🟦 [PolicyService] role=$role child_id=$childId');

      if (role != 'child') {
        debugPrint('🟡 [PolicyService] fetch skipped (role=$role)');
        return false;
      }

      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [PolicyService] Missing auth_token');
        return false;
      }

      _api.setAuthToken(token);

      debugPrint('🟦 [PolicyService] GET ${ApiConstants.childPolicy}');
      final res = await _api.get<dynamic>(ApiConstants.childPolicy, requiresAuth: true);

      debugPrint('🟦 [PolicyService] status=${res.statusCode} success=${res.isSuccess}');
      if (!res.isSuccess || res.data == null) {
        debugPrint('❌ [PolicyService] Failed: ${res.error}');
        return false;
      }

      final data = (res.data is Map<String, dynamic>)
          ? (res.data as Map<String, dynamic>)
          : <String, dynamic>{'rules': res.data};

      debugPrint('🟦 [PolicyService] payload=${jsonEncode(data)}');

      final rules = data['rules'];
      if (rules is List && rules.isEmpty) {
        debugPrint('🟡 [PolicyService] Empty rules -> nothing to apply');
        await prefs.setString('last_policy_payload', jsonEncode(data));
        return true;
      }

      final applied = await FirebaseMessagingService().applyPolicyPayload(data);
      debugPrint('🟦 [PolicyService] applyPolicyPayload result=$applied');

      await prefs.setString('last_policy_payload', jsonEncode(data));
      debugPrint('✅ [PolicyService] Done');

      return true;
    } catch (e) {
      debugPrint('❌ [PolicyService] error: $e');
      return false;
    }
  }
}
