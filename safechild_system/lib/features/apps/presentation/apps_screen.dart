// lib/features/apps/presentation/apps_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:safechild_system/services/installed_apps_service.dart';
import 'package:safechild_system/services/native_bridge.dart';

class AppsScreen extends StatefulWidget {
  static const routeName = '/app_usage';
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}


class _AppsScreenState extends State<AppsScreen> {
  final InstalledAppsService _service = InstalledAppsService();
  List<InstalledAppWrapper> _all = [];
  List<InstalledAppWrapper> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    try {
      final apps = await _service.getInstalledApps();
      _all = apps;
      _filtered = List.from(_all);
    } catch (e) {
      _all = [];
      _filtered = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    _query = q.trim().toLowerCase();
    if (_query.isEmpty) {
      setState(() => _filtered = List.from(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((a) {
        final name = (a.appName ?? '').toLowerCase();
        final pkg = a.packageName.toLowerCase();
        return name.contains(_query) || pkg.contains(_query);
      }).toList();
    });
  }

  Widget _buildIcon(InstalledAppWrapper a) {
    try {
      final Uint8List? b = a.iconBytes;
      if (b != null && b.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(b, width: 44, height: 44, fit: BoxFit.cover),
        );
      }
    } catch (_) {}
    return const CircleAvatar(radius: 22, child: Icon(Icons.apps_outlined));
  }

  Future<void> _openSetLimitSheet(InstalledAppWrapper app) async {
    int hour = 0;
    int minute = 10;
    final picked = await showModalBottomSheet<Duration?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: StatefulBuilder(builder: (ctx2, setSt) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
                Text(app.appName ?? app.packageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('ساعات'),
                        DropdownButton<int>(
                          value: hour.clamp(0, 24),
                          isExpanded: true,
                          items: List.generate(25, (i) => i).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                          onChanged: (v) => setSt(() => hour = v ?? 0),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('دقائق'),
                        DropdownButton<int>(
                          value: minute,
                          isExpanded: true,
                          items: [0, 5, 10, 15, 30, 45].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                          onChanged: (v) => setSt(() => minute = v ?? 0),
                        ),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('حذف/إلغاء')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(onPressed: () => Navigator.pop(ctx, Duration(hours: hour, minutes: minute)), child: const Text('حفظ')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        );
      },
    );

    if (!mounted) return;
    if (picked == null) {
      // حذف الحد عبر NativeBridge
      await NativeBridge.clearLimit(app.packageName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الحد (مؤقت)')));
    } else {
      await NativeBridge.setLimit(app.packageName, picked);
      final h = picked.inHours;
      final m = picked.inMinutes.remainder(60);
      final labelParts = <String>[];
      if (h > 0) labelParts.add('$h س');
      if (m > 0) labelParts.add('$m د');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعيين الحد: ${labelParts.join(' ')}')));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة التطبيقات')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              TextField(onChanged: _onSearch, decoration: InputDecoration(hintText: 'ابحث باسم التطبيق أو اسم الحزمة', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true)),
              const SizedBox(height: 10),
              if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
              else Expanded(
                child: _filtered.isEmpty
                    ? Center(child: Text(_all.isEmpty ? 'لم تُكتشف تطبيقات' : 'لا توجد نتائج عن "${_query}"'))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final app = _filtered[i];
                          return ListTile(
                            leading: _buildIcon(app),
                            title: Text(app.appName ?? app.packageName),
                            subtitle: FutureBuilder<Duration?>(
                              future: NativeBridge.getLimit(app.packageName),
                              builder: (ctx, snap) {
                                final d = snap.data;
                                if (d == null || d.inMilliseconds == 0) return const Text('لم يُحدد حد');
                                final h = d.inHours;
                                final m = d.inMinutes.remainder(60);
                                final parts = <String>[];
                                if (h > 0) parts.add('$hس');
                                if (m > 0) parts.add('$mد');
                                return Text('الحد: ${parts.join(' ')} / يوم', style: const TextStyle(fontSize: 12));
                              },
                            ),
                            trailing: const Icon(Icons.timer),
                            onTap: () => _openSetLimitSheet(app),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}


// // lib/features/usage/app_usage_screen.dart
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:safechild_system/services/installed_apps_service.dart';
// import 'package:safechild_system/services/monitor_service.dart';

// class AppUsageScreen extends StatefulWidget {
//   static const routeName = '/app_usage';
//   const AppUsageScreen({Key? key}) : super(key: key);

//   @override
//   State<AppUsageScreen> createState() => _AppUsageScreenState();
// }

// class _AppUsageScreenState extends State<AppUsageScreen> {
//   final InstalledAppsService _service = InstalledAppsService();
//   final MonitorService _monitor = MonitorService();
//   List<InstalledAppWrapper> _all = [];
//   List<InstalledAppWrapper> _filtered = [];
//   bool _loading = true;
//   String _query = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadApps();
//   }

//   Future<void> _loadApps() async {
//     setState(() => _loading = true);
//     try {
//       final apps = await _service.getInstalledApps();
//       _all = apps;
//       _filtered = List.from(_all);
//       debugPrint('Apps loaded: ${_all.length}');
//     } catch (e) {
//       debugPrint('Error loading apps: $e');
//       _all = [];
//       _filtered = [];
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   void _onSearch(String q) {
//     _query = q.trim().toLowerCase();
//     if (_query.isEmpty) {
//       setState(() => _filtered = List.from(_all));
//       return;
//     }
//     setState(() {
//       _filtered = _all.where((a) {
//         final name = (a.appName ?? '').toLowerCase();
//         final pkg = a.packageName.toLowerCase();
//         return name.contains(_query) || pkg.contains(_query);
//       }).toList();
//     });
//   }

//   Widget _buildIcon(InstalledAppWrapper a) {
//     try {
//       final Uint8List? b = a.iconBytes;
//       if (b != null && b.isNotEmpty) {
//         return ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.memory(b, width: 44, height: 44, fit: BoxFit.cover),
//         );
//       }
//     } catch (_) {}
//     return const CircleAvatar(radius: 22, child: Icon(Icons.apps_outlined));
//   }

//   /// زر الخروج: يعيد المستخدم إلى شاشة إدارة السياسات
//   void _exitToPolicySettings() {
//     Navigator.pushNamedAndRemoveUntil(context, '/policy_settings', (route) => false);
//   }

//   /// عند الضغط على تطبيق: افتح BottomSheet لتعيين الحد (ساعة/دقيقة)
//   Future<void> _openSetLimitSheet(InstalledAppWrapper app) async {
//     // قيم مبدئية إن وُجد حد سابق في الذاكرة
//     final cur = _monitor.getLimit(app.packageName);
//     int hour = cur?.inHours ?? 0;
//     int minute = cur?.inMinutes.remainder(60) ?? 10;

//     final result = await showModalBottomSheet<Duration>(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//           child: StatefulBuilder(builder: (ctx2, setSt) {
//             return Container(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(app.appName ?? app.packageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                           const Text('ساعات'),
//                           DropdownButton<int>(
//                             value: hour.clamp(0, 24),
//                             isExpanded: true,
//                             items: List.generate(25, (i) => i)
//                                 .map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
//                             onChanged: (v) => setSt(() => hour = v ?? 0),
//                           ),
//                         ]),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                           const Text('دقائق'),
//                           DropdownButton<int>(
//                             value: minute,
//                             isExpanded: true,
//                             items: [0, 5, 10, 15, 30, 45]
//                                 .map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
//                             onChanged: (v) => setSt(() => minute = v ?? 0),
//                           ),
//                         ]),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.pop(ctx, Duration.zero),
//                           child: const Text('حذف/إلغاء'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () => Navigator.pop(ctx, Duration(hours: hour, minutes: minute)),
//                           child: const Text('حفظ'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                 ],
//               ),
//             );
//           }),
//         );
//       },
//     );

//     if (result != null) {
//       // نحفظ الحد مؤقتًا بالذاكرة عبر MonitorService (لا حفظ محلي)
//       _monitor.setLimit(app.packageName, result);
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين حد مؤقت (في الذاكرة)')));
//       setState(() {}); // تحديث الsubtitle لعرض الحد الجديد
//     }
//   }

//   String _limitText(String packageName) {
//     final d = _monitor.getLimit(packageName);
//     if (d == null || d.inMilliseconds == 0) return 'لم يُحدد حد';
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60);
//     final parts = <String>[];
//     if (h > 0) parts.add('${h}س');
//     if (m > 0) parts.add('${m}د');
//     return 'الحد: ${parts.join(' ')} / يوم';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('قائمة التطبيقات'),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new),
//             onPressed: _exitToPolicySettings,
//             tooltip: 'العودة لإدارة السياسات',
//           ),
//           actions: [
//             TextButton(
//               onPressed: _exitToPolicySettings,
//               child: const Text('خروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               children: [
//                 TextField(
//                   onChanged: _onSearch,
//                   decoration: InputDecoration(
//                     hintText: 'ابحث باسم التطبيق أو اسم الحزمة',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                     isDense: true,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 if (_loading)
//                   const Expanded(child: Center(child: CircularProgressIndicator()))
//                 else
//                   Expanded(
//                     child: _filtered.isEmpty
//                         ? Center(child: Text(_all.isEmpty ? 'لم تُكتشف تطبيقات' : 'لا توجد نتائج عن \"$_query\"'))
//                         : ListView.separated(
//                             itemCount: _filtered.length,
//                             separatorBuilder: (_, __) => const Divider(height: 1),
//                             itemBuilder: (context, i) {
//                               final app = _filtered[i];
//                               return ListTile(
//                                 leading: _buildIcon(app),
//                                 title: Text(app.appName ?? app.packageName),
//                                 subtitle: Text(_limitText(app.packageName), style: const TextStyle(fontSize: 12)),
//                                 trailing: const Icon(Icons.timer),
//                                 onTap: () => _openSetLimitSheet(app),
//                               );
//                             },
//                           ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }






