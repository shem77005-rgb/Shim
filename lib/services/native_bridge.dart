// import 'package:flutter/services.dart';

// class NativeBridge {
//   static const _ch = MethodChannel('safechild/native');

//   static Future<void> openUsageAccessSettings() async {
//     try {
//       await _ch.invokeMethod('openUsageAccessSettings');
//     } catch (e) {}
//   }

//   static Future<void> openAccessibilitySettings() async {
//     try {
//       await _ch.invokeMethod('openAccessibilitySettings');
//     } catch (e) {}
//   }

//   static Future<void> setLimit(String packageName, Duration dur) async {
//     try {
//       await _ch.invokeMethod('setLimit', {'package': packageName, 'ms': dur.inMilliseconds});
//     } catch (e) {}
//   }

//   static Future<void> clearLimit(String packageName) async {
//     try {
//       await _ch.invokeMethod('clearLimit', {'package': packageName});
//     } catch (e) {}
//   }

//   static Future<void> clearAllLimits() async {
//     try {
//       await _ch.invokeMethod('clearAllLimits');
//     } catch (e) {}
//   }

//   static Future<Duration?> getLimit(String packageName) async {
//     try {
//       final res = await _ch.invokeMethod('getLimit', {'package': packageName});
//       if (res == null) return null;
//       return Duration(milliseconds: (res as int));
//     } catch (e) {
//       return null;
//     }
//   }
// }
