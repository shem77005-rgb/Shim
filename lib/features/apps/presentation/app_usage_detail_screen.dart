
import '../../../services/app_blocker_service.dart';

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';


class AppUsageDetailScreen extends StatefulWidget {
  final String packageName;
  final String title;
  final Uint8List? iconBytes;
  final Duration limit;

  const AppUsageDetailScreen({
    super.key,
    required this.packageName,
    required this.title,
    this.iconBytes,
    required this.limit,
  });

  @override
  State<AppUsageDetailScreen> createState() => _AppUsageDetailScreenState();
}

class _AppUsageDetailScreenState extends State<AppUsageDetailScreen> {
  bool _loading = true;
  Duration _used = Duration.zero;
  Duration _remaining = Duration.zero;
  double _progress = 0.0;

  List<int> _hourMs = List.filled(24, 0);

  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      final granted = await UsageStats.checkUsagePermission() ?? false;
      _hasPermission = granted;

      if (!granted) {
        setState(() => _loading = false);
        return;
      }

      await _loadUsage();
    } catch (e) {
      setState(() {
        _error = "حدث خطأ أثناء جلب بيانات الاستخدام";
        _loading = false;
      });
    }
  }

  Future<void> _openUsageSettings() async {
    await UsageStats.grantUsagePermission();
    await Future.delayed(const Duration(milliseconds: 500));
    _initAndLoad();
  }

  int _parseForeground(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  Future<void> _loadUsage() async {
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final all = await UsageStats.queryUsageStats(startOfDay, now);

      int totalMs = 0;

      for (final u in all) {
        if ((u.packageName ?? "") == widget.packageName) {
          totalMs += _parseForeground(u.totalTimeInForeground);
        }
      }

      _used = Duration(milliseconds: totalMs);

      // 🔥🔥🔥 هنا نضع كود الحظر
      AppBlockerService.init(
        context: context,
        targetPackage: widget.packageName,
        used: _used,
        limit: widget.limit,
        appName: widget.title,
      );

      // ----------------------------- حساب بالساعة ----------------------------
      List<int> hourly = List.filled(24, 0);

      for (int h = 0; h < 24; h++) {
        final s = startOfDay.add(Duration(hours: h));
        final e = s.add(const Duration(hours: 1));

        if (s.isAfter(now)) break;

        final endRange = e.isAfter(now) ? now : e;

        try {
          final chunk = await UsageStats.queryUsageStats(s, endRange);

          int sum = 0;

          for (final u in chunk) {
            if ((u.packageName ?? "") == widget.packageName) {
              sum += _parseForeground(u.totalTimeInForeground);
            }
          }

          hourly[h] = sum;
        } catch (_) {
          hourly[h] = 0;
        }
      }

      _hourMs = hourly;

      // ----------------------------- المتبقي والنسبة ----------------------------
      final limitMs = widget.limit.inMilliseconds;
      final usedMs = _used.inMilliseconds;

      if (limitMs > 0) {
        final rem = (limitMs - usedMs).clamp(0, limitMs);
        _remaining = Duration(milliseconds: rem);
        _progress = (usedMs / limitMs).clamp(0.0, 1.0);
      } else {
        _remaining = Duration.zero;
        _progress = 0.0;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = "فشل تحميل بيانات الاستخدام";
        _loading = false;
      });
    }
  }

  String _fmt(Duration d) {
    int h = d.inHours;
    int m = d.inMinutes % 60;
    int s = d.inSeconds % 60;

    if (h > 0) return "$h ساعة $m دقيقة";
    if (m > 0) return "$m دقيقة $s ثانية";
    return "$s ثانية";
  }

  Widget _buildHourlyBars() {
    final int maxInt = _hourMs.fold<int>(0, (prev, e) => e > prev ? e : prev);

    final double maxValue = maxInt.toDouble();
    final int nowHour = DateTime.now().hour;

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (i) {
          double v = _hourMs[i].toDouble();

          double factor = (maxValue <= 0) ? 0.0 : v / maxValue;

          if (!factor.isFinite) factor = 0.0;
          factor = factor.clamp(0.0, 1.0);

          final barHeight = 70.0 * factor;

          final isPast = i <= nowHour;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: barHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPast ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("$i", style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("استخدام ${widget.title} اليوم")),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_hasPermission
                ? _buildNoPermission()
                : _error != null
                    ? Center(child: Text(_error!))
                    : _buildContent(),
      ),
    );
  }

  Widget _buildNoPermission() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("يجب منح صلاحية سجل الاستخدام"),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _openUsageSettings,
            child: const Text("فتح الإعدادات"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              widget.iconBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        widget.iconBytes!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const CircleAvatar(radius: 28, child: Icon(Icons.apps)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "الحد اليومي: ${_fmt(widget.limit)}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "استخدمت: ${_fmt(_used)}",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            color: _progress >= 1 ? Colors.red : Colors.blue,
          ),

          const SizedBox(height: 8),

          Text(
            "المتبقي: ${_fmt(_remaining)}",
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 20),

          const Text(
            "الاستخدام بالساعة:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildHourlyBars(),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _loadUsage,
            icon: const Icon(Icons.refresh),
            label: const Text("تحديث"),
          ),
        ],
      ),
    );
  }
}



