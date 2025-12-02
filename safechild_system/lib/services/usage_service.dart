import 'package:usage_stats/usage_stats.dart';

/// يجلب UsageInfo من بداية اليوم حتى الآن: يعيد خريطة packageName -> millis (int)
Future<Map<String, int>> getTodayUsageMillis() async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final List<UsageInfo> stats = await UsageStats.queryUsageStats(start, now);

  final Map<String, int> out = {};

  for (final s in stats) {
    final pkg = s.packageName ?? '';
    if (pkg.isEmpty) continue;

    // قراءة القيمة الخام وتحويلها بطريقة آمنة إلى int (milliseconds)
    final raw = s.totalTimeInForeground ?? 0;
    int used;
    if (raw is int) {
      used = raw;
    } else if (raw is double) {
      used = raw.toInt();
    } else {
      // آخر الحالات (String أو dynamic) - نحاول التحويل من النص وإلا نستخدم 0
      used = int.tryParse(raw.toString()) ?? 0;
    }

    // نجمع الاستخدام في الخريطة
    out[pkg] = (out[pkg] ?? 0) + used;
  }

  return out;
}
