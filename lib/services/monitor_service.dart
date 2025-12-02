// lib/services/monitor_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:safechild_system/services/usage_service.dart' as UsageService;


/// خدمة مراقبة (in-memory limits only)
class MonitorService {
  MonitorService._private();
  static final MonitorService _instance = MonitorService._private();
  factory MonitorService() => _instance;

  GlobalKey<NavigatorState>? navigatorKey;

  /// in-memory limits: package -> limitMillis
  final Map<String, int> _limitsMillis = {};

  StreamSubscription<AccessibilityEvent>? _sub;
  bool _running = false;

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    this.navigatorKey = navigatorKey;
    // لا نقوم بأي تحميل لحفظ محلي — المطلوب لاحقاً ربط API
  }

  /// ضبط حد مؤقت في الذاكرة (لا يُخزّن)
  void setLimit(String packageName, Duration dur) {
    if (dur.inMilliseconds <= 0) {
      _limitsMillis.remove(packageName);
    } else {
      _limitsMillis[packageName] = dur.inMilliseconds;
    }
  }

  Duration? getLimit(String packageName) {
    final v = _limitsMillis[packageName];
    return v == null ? null : Duration(milliseconds: v);
  }

  /// بداية المراقبة (يستمع لأحداث Accessibility)
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _sub = FlutterAccessibilityService.accessStream.listen((event) async {
      try {
        final pkg = event.packageName ?? '';
        if (pkg.isEmpty) return;
        final limit = _limitsMillis[pkg];
        if (limit == null) return;
        final usage = await UsageService.getTodayUsageMillis();
        final used = usage[pkg] ?? 0;
        if (used >= limit) {
          _showBlock(pkg);
        }
      } catch (e) {
        debugPrint('MonitorService: error in listener $e');
      }
    }, onError: (e) {
      debugPrint('MonitorService accessStream error: $e');
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
  }

  void _showBlock(String packageName) {
    final key = navigatorKey;
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;

    // لا نفتح أكثر من شاشة حظر واحدة
    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlockScreen(packageName: packageName),
    );
    Navigator.of(ctx).push(route);
  }
}

/// شاشة حظر بسيطة (تظهر كـ full-screen dialog)
class BlockScreen extends StatelessWidget {
  final String packageName;
  const BlockScreen({required this.packageName, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // لا نسمح بالرجوع بواسطة زر back
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 72, color: Colors.white),
                const SizedBox(height: 16),
                Text('تم استهلاك المدة المسموحة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$packageName محجوب مؤقتًا اليوم', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
