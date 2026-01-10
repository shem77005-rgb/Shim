import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appcheck/appcheck.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';

class ChildAppsInventoryService {
  final ApiClient _api;
  ChildAppsInventoryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const String _roleKey = 'user_role';
  static const String _childIdKey = 'child_id';
  static const String _accessTokenKey = 'auth_token';

  final AppCheck _appCheck = AppCheck();

  Future<bool> syncInstalledAppsToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString(_roleKey) ?? '').trim().toLowerCase();

      debugPrint('🟦 [ChildAppsInventory] role=$role');
      if (role != 'child') {
        debugPrint('🟡 [ChildAppsInventory] Skip: not child device');
        return false;
      }

      final token = prefs.getString(_accessTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [ChildAppsInventory] Missing auth_token');
        return false;
      }

      final childId = prefs.getInt(_childIdKey) ??
          int.tryParse((prefs.getString(_childIdKey) ?? '').trim());

      if (childId == null) {
        debugPrint('⚠️ [ChildAppsInventory] Missing/invalid child_id');
        return false;
      }

      _api.setAuthToken(token);

      debugPrint('🟦 [ChildAppsInventory] Reading installed apps from AppCheck...');
      final raw = await _appCheck.getInstalledApps();

      final apps = (raw ?? []).map((a) {
        return {
          "package": (a.packageName ?? "").toString(),
          "name": (a.appName ?? a.packageName ?? "").toString(),
        };
      }).where((e) => (e["package"] ?? "").toString().isNotEmpty).toList();

      debugPrint('🟦 [ChildAppsInventory] appsCount=${apps.length}');
      if (apps.isEmpty) {
        debugPrint('⚠️ [ChildAppsInventory] No apps detected');
        return false;
      }

      final payload = {"apps": apps};

      final url = ApiConstants.childAppsInventory(childId);
      debugPrint('🟦 [ChildAppsInventory] POST $url');
      debugPrint('🟦 [ChildAppsInventory] sample first=${apps.take(2).toList()}');

      final res = await _api.post<dynamic>(
        url,
        body: payload,
        requiresAuth: true,
      );

      debugPrint('🟦 [ChildAppsInventory] status=${res.statusCode} success=${res.isSuccess}');
      debugPrint('🟦 [ChildAppsInventory] body=${res.data} err=${res.error}');

      return res.isSuccess;
    } catch (e) {
      debugPrint('❌ [ChildAppsInventory] error: $e');
      return false;
    }
  }
}
