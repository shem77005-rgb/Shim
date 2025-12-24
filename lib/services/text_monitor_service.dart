import 'package:flutter/services.dart';

/// Text Monitor Service - Communicates with native Android accessibility service
/// for monitoring text input across the device
class TextMonitorService {
  static const MethodChannel _channel = MethodChannel(
    'com.shaimaa.safechild/text_monitor',
  );

  // Singleton
  static final TextMonitorService _instance = TextMonitorService._internal();
  factory TextMonitorService() => _instance;
  TextMonitorService._internal();

  /// Open Android Accessibility Settings
  Future<bool> openAccessibilitySettings() async {
    try {
      final result = await _channel.invokeMethod('openAccessibilitySettings');
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error opening settings: ${e.message}');
      return false;
    }
  }

  /// Check if Text Monitor Service is enabled in Accessibility Settings
  Future<bool> isTextMonitorEnabled() async {
    try {
      final result = await _channel.invokeMethod('isTextMonitorEnabled');
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error checking status: ${e.message}');
      return false;
    }
  }

  /// Enable or disable writing restrictions
  Future<bool> setWritingRestrictionsEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod(
        'setWritingRestrictionsEnabled',
        {'enabled': enabled},
      );
      print(
        '✅ [TextMonitorService] Writing restrictions ${enabled ? "enabled" : "disabled"}',
      );
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error setting restrictions: ${e.message}');
      return false;
    }
  }

  /// Check if writing restrictions are currently enabled
  Future<bool> isWritingRestrictionsEnabled() async {
    try {
      final result = await _channel.invokeMethod(
        'isWritingRestrictionsEnabled',
      );
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error checking restrictions: ${e.message}');
      return false;
    }
  }

  /// Save child information for the accessibility service to use
  Future<bool> saveChildInfo({
    required String parentId,
    required String childName,
    required String childId,
    required String token,
    String? refreshToken,
  }) async {
    try {
      final result = await _channel.invokeMethod('saveChildInfo', {
        'parentId': parentId,
        'childName': childName,
        'childId': childId,
        'token': token,
        'refreshToken': refreshToken ?? '',
      });
      print(
        '✅ [TextMonitorService] Child info saved: $childName (parent: $parentId)',
      );
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error saving child info: ${e.message}');
      return false;
    }
  }

  /// Get saved child information
  Future<Map<String, String>> getChildInfo() async {
    try {
      final result = await _channel.invokeMethod('getChildInfo');
      if (result is Map) {
        return Map<String, String>.from(result);
      }
      return {};
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error getting child info: ${e.message}');
      return {};
    }
  }

  /// Clear child information (when logging out)
  Future<bool> clearChildInfo() async {
    try {
      final result = await _channel.invokeMethod('clearChildInfo');
      print('✅ [TextMonitorService] Child info cleared');
      return result == true;
    } on PlatformException catch (e) {
      print('❌ [TextMonitorService] Error clearing child info: ${e.message}');
      return false;
    }
  }
}
