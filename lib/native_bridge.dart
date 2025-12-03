
import 'package:flutter/services.dart';

class NativeBridge {
  static const _chan = MethodChannel('safechild/native');

  static Future<void> requestUsageAccess() async {
    await _chan.invokeMethod('requestUsageAccess');
  }

  static Future<void> startMonitoring() async {
    await _chan.invokeMethod('startMonitoring');
  }

  static Future<void> stopMonitoring() async {
    await _chan.invokeMethod('stopMonitoring');
  }

  static Future<void> setLimit(String packageName, int millis) async {
    await _chan.invokeMethod('setLimit', {'package': packageName, 'millis': millis});
  }

  static Future<void> clearLimit(String packageName) async {
    await _chan.invokeMethod('clearLimit', {'package': packageName});
  }
}
