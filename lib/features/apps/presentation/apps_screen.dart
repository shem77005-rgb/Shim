
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:appcheck/appcheck.dart';
import 'package:safechild_system/services/monitor_service.dart';

import '../presentation/app_usage_detail_screen.dart';
import '../../../native_bridge.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({Key? key}) : super(key: key);
  static const routeName = '/app_usage';

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final AppCheck _appCheck = AppCheck();
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await _appCheck.getInstalledApps();
      _apps = (raw ?? []).toList();
      _apps.sort(
        (a, b) => (a.appName ?? a.packageName ?? '').toLowerCase().compareTo(
          (b.appName ?? b.packageName ?? '').toLowerCase(),
        ),
      );
      _filtered = List.from(_apps);
    } catch (e) {
      debugPrint('Error loading apps: $e');
      _apps = [];
      _filtered = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  void _search(String q) {
    _query = q.trim().toLowerCase();
    if (_query.isEmpty) {
      setState(() => _filtered = List.from(_apps));
      return;
    }
    setState(() {
      _filtered =
          _apps.where((a) {
            final name = (a.appName ?? '').toLowerCase();
            final pkg = (a.packageName ?? '').toLowerCase();
            return name.contains(_query) || pkg.contains(_query);
          }).toList();
    });
  }

  Uint8List? _iconBytesFromApp(AppInfo a) {
    try {
      final dynamic iconField = a.icon;
      if (iconField == null) return null;
      final s = iconField.toString();
      if (s.isEmpty) return null;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setLimitDialog(AppInfo app) async {
    int hours = 0;
    int minutes = 10;

    final res = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx2, st) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Text(
                    app.appName ?? app.packageName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ساعات'),
                            DropdownButton<int>(
                              value: hours,
                              isExpanded: true,
                              items:
                                  List.generate(25, (i) => i)
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text('$v'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => st(() => hours = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('دقائق'),
                            DropdownButton<int>(
                              value: minutes,
                              isExpanded: true,
                              items:
                                  [0, 5, 10, 15, 30, 45]
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text('$v'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => st(() => minutes = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, Duration.zero),
                          child: const Text('حذف'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              () => Navigator.pop(
                                ctx,
                                Duration(hours: hours, minutes: minutes),
                              ),
                          child: const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;

    if (res == null) return;

    // final package = app.packageName ?? '';
    // if (res.inMilliseconds == 0) {
    //   // حذف الحد
    //   try {
    //     await NativeBridge.clearLimit(package);
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(const SnackBar(content: Text('تم حذف الحد')));
    //   } catch (e) {
    //     debugPrint('clearLimit error: $e');
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(const SnackBar(content: Text('فشل حذف الحد')));
    //   }
    // } else {
    //   try {
    //     await NativeBridge.setLimit(package, res.inMilliseconds);
    //     await NativeBridge.startMonitoring();
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(const SnackBar(content: Text('تم تعيين الحد')));
    //   } catch (e) {
    //     debugPrint('setLimit error: $e');
    //     ScaffoldMessenger.of(
    //       context,
    //     ).showSnackBar(const SnackBar(content: Text('فشل تعيين الحد')));
    //   }

    //   final iconBytes = _iconBytesFromApp(app);
    //   final dur = res;
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder:
    //           (_) => AppUsageDetailScreen(
    //             packageName: package,
    //             title: app.appName ?? package,
    //             iconBytes: iconBytes,
    //             limit: dur,
    //           ),
    //     ),
    //   );
    // }
    final package = app.packageName ?? '';

if (res.inMilliseconds == 0) {
  try {
    await NativeBridge.clearLimit(package);

        MonitorService().removeLimit(package);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الحد')),
    );

  } catch (e) {
    debugPrint('clearLimit error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فشل حذف الحد')),
    );
  }
} 

else {
  try {
    await NativeBridge.setLimit(package, res.inMilliseconds);

   
    MonitorService().setAppLimit(package, res);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعيين الحد')),
    );

  } catch (e) {
    debugPrint('setLimit error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فشل تعيين الحد')),
    );
  }

  final iconBytes = _iconBytesFromApp(app);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AppUsageDetailScreen(
        packageName: package,
        title: app.appName ?? package,
        iconBytes: iconBytes,
        limit: res,
      ),
    ),
  );
}

  }

  Future<void> _openUsageSettings() async {
    await NativeBridge.requestUsageAccess();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة التطبيقات'),
          actions: [
            TextButton(
              onPressed: _openUsageSettings,
              child: const Text(
                'صلاحية الاستخدام',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                onChanged: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ابحث باسم التطبيق أو اسم الحزمة',
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child:
                      _filtered.isEmpty
                          ? Center(
                            child: Text(
                              _apps.isEmpty
                                  ? 'لم تُكتشف تطبيقات'
                                  : 'لا نتائج عن \"$_query\"',
                            ),
                          )
                          : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final a = _filtered[i];
                              final iconBytes = _iconBytesFromApp(a);
                              return ListTile(
                                leading:
                                    iconBytes != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            iconBytes,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : const CircleAvatar(
                                          child: Icon(Icons.apps),
                                        ),
                                title: Text(a.appName ?? a.packageName ?? ''),
                                subtitle: Text(a.packageName ?? ''),
                                trailing: const Icon(Icons.timer),
                                onTap: () => _setLimitDialog(a),
                              );
                            },
                          ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on MonitorService {
  void removeLimit(String package) {}
}
