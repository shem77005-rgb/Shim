
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:safechild_system/features/apps/presentation/block_screen.dart';
import 'package:usage_stats/usage_stats.dart';


class MonitorService {
  static final MonitorService _instance = MonitorService._internal();
  factory MonitorService() => _instance;
  MonitorService._internal();

  GlobalKey<NavigatorState>? _navKey;

  /// خريطة حدود كل تطبيق
  final Map<String, Duration> appLimits = {};   // package -> limit

  /// خريطة الوقت المستخدم اليوم لكل تطبيق
  final Map<String, Duration> usedToday = {};   // package -> used

  bool isBlocking = false;

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navKey = navigatorKey;

    // التأكد من صلاحية الوصول Accessibility
    bool perm = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!perm) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }

    // الاستماع للتطبيقات المفتوحة الآن
    FlutterAccessibilityService.accessStream.listen((event) async {
      final pkg = event.packageName;

      if (pkg == null) return;
      if (!appLimits.containsKey(pkg)) return;

      // احسب الوقت المستخدم
      Duration used = await getTodayUsage(pkg);

      // احصل على الحد
      Duration limit = appLimits[pkg] ?? Duration.zero;

      // إذا تجاوز المستخدم الحد → أظهر الحظر
      if (used >= limit && !isBlocking) {
        isBlocking = true;

        _navKey!.currentState!.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => BlockPage(appName: pkg),
          ),
        ).then((_) => isBlocking = false);
      }
    });
  }

  /// حساب الوقت المستخدم اليوم لتطبيق
  Future<Duration> getTodayUsage(String pkg) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final stats = await UsageStats.queryUsageStats(start, now);

    int totalMs = 0;

    for (final u in stats) {
      if (u.packageName == pkg) {
        final raw = u.totalTimeInForeground;
        int ms = 0;

        if (raw is int) ms = raw as int;
        else if (raw is String) ms = int.tryParse(raw) ?? 0;

        totalMs += ms;
      }
    }

    return Duration(milliseconds: totalMs);
  }

  /// تحديث أو إضافة حدّ يومي لتطبيق
  void setAppLimit(String pkg, Duration limit) {
    appLimits[pkg] = limit;
  }
}

