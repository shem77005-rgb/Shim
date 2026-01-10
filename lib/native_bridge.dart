// import 'package:flutter/services.dart';

// class NativeBridge {
//   static const _chan = MethodChannel('safechild/native');

//   static Future<void> requestUsageAccess() async {
//     await _chan.invokeMethod('requestUsageAccess');
//   }

//   static Future<void> openOverlaySettings() async {
//     await _chan.invokeMethod('openOverlaySettings');
//   }

//   static Future<void> openAccessibilitySettings() async {
//     await _chan.invokeMethod('openAccessibilitySettings');
//   }

//   static Future<void> startMonitoring() async {
//     await _chan.invokeMethod('startMonitoring');
//   }

//   static Future<void> stopMonitoring() async {
//     await _chan.invokeMethod('stopMonitoring');
//   }

//   static Future<void> setLimit(String packageName, int millis) async {
//     await _chan.invokeMethod('setLimit', {'package': packageName, 'millis': millis});
//   }

//   static Future<void> clearLimit(String packageName) async {
//     await _chan.invokeMethod('clearLimit', {'package': packageName});
//   }
// }


import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _chan = MethodChannel('safechild/native');

  // ---------- Settings screens ----------
  static Future<void> openUsageAccessSettings() async {
    await _chan.invokeMethod('openUsageAccessSettings');
  }

  // Alias للقديم
  static Future<void> requestUsageAccess() async {
    await openUsageAccessSettings();
  }

  static Future<void> openOverlaySettings() async {
    await _chan.invokeMethod('openOverlaySettings');
  }

  static Future<void> openAccessibilitySettings() async {
    await _chan.invokeMethod('openAccessibilitySettings');
  }

  // ---------- Monitoring ----------
  static Future<void> startMonitoring() async {
    await _chan.invokeMethod('startMonitoring');
  }

  static Future<void> stopMonitoring() async {
    await _chan.invokeMethod('stopMonitoring');
  }

  // ---------- Limits ----------
  static Future<void> setLimit(String packageName, int millis) async {
    await _chan.invokeMethod('setLimit', {
      'package': packageName,
      'ms': millis, // ✅ mainActivity يدعم ms أو millis
    });
  }

  static Future<void> clearLimit(String packageName) async {
    await _chan.invokeMethod('clearLimit', {'package': packageName});
  }

  static Future<void> clearAllLimits() async {
    await _chan.invokeMethod('clearAllLimits');
  }
}
