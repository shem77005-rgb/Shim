
// // import 'dart:typed_data';
// // import 'package:flutter/material.dart';
// // import 'package:safechild_system/services/installed_apps_service.dart';


// // class AppsSearchScreen extends StatefulWidget {
// //   static const routeName = '/apps_search';
// //   const AppsSearchScreen({Key? key}) : super(key: key);

// //   @override
// //   State<AppsSearchScreen> createState() => _AppsSearchScreenState();
// // }

// // class _AppsSearchScreenState extends State<AppsSearchScreen> {
// //   final InstalledAppsService _service = InstalledAppsService();
// //   List<InstalledAppInfo> _all = [];
// //   List<InstalledAppInfo> _filtered = [];
// //   bool _loading = true;
// //   String _query = '';

// //   @override
// //   void initState() {
// //     super.initState();
// //     _load();
// //   }

// //   Future<void> _load() async {
// //     setState(() => _loading = true);
// //     final apps = await _service.getInstalledApps();
// //     _all = apps.where((a) => (a.isSystemApp ?? false) == false).toList();
// //     _filtered = List.from(_all);
// //     setState(() => _loading = false);
// //   }

// //   void _onSearch(String q) {
// //     _query = q.trim();
// //     if (_query.isEmpty) {
// //       setState(() => _filtered = List.from(_all));
// //       return;
// //     }
// //     final low = _query.toLowerCase();
// //     setState(() {
// //       _filtered = _all.where((a) {
// //         final name = (a.appName ?? '').toLowerCase();
// //         final pkg = a.packageName.toLowerCase();
// //         return name.contains(low) || pkg.contains(low);
// //       }).toList();
// //     });
// //   }

// //   Widget _iconWidget(InstalledAppInfo app) {
// //     final Uint8List? bytes = app.iconBytes;
// //     if (bytes != null && bytes.isNotEmpty) {
// //       return ClipRRect(
// //         borderRadius: BorderRadius.circular(8),
// //         child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
// //       );
// //     }
// //     return const CircleAvatar(radius: 22, child: Icon(Icons.apps_outlined));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Directionality(
// //       textDirection: TextDirection.rtl,
// //       child: Scaffold(
// //         appBar: AppBar(title: const Text('بحث التطبيقات')),
// //         body: SafeArea(
// //           child: Padding(
// //             padding: const EdgeInsets.all(12.0),
// //             child: Column(
// //               children: [
// //                 TextField(
// //                   onChanged: _onSearch,
// //                   decoration: InputDecoration(
// //                     hintText: 'ابحث باسم التطبيق أو اسم الحزمة',
// //                     prefixIcon: const Icon(Icons.search),
// //                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
// //                     isDense: true,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
// //                 if (!_loading)
// //                   Expanded(
// //                     child: _filtered.isEmpty
// //                         ? Center(child: Text(_query.isEmpty ? 'لا توجد تطبيقات' : 'لا توجد نتائج عن "$_query"'))
// //                         : ListView.separated(
// //                             itemCount: _filtered.length,
// //                             separatorBuilder: (_, __) => const Divider(height: 1),
// //                             itemBuilder: (_, i) {
// //                               final app = _filtered[i];
// //                               return ListTile(
// //                                 leading: _iconWidget(app),
// //                                 title: Text(app.appName ?? app.packageName),
// //                                 subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
// //                                 onTap: () async {
                                  
// //                                    await _service.launchApp(app.packageName);
// //                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('نقرت على ${app.appName ?? app.packageName}')));
// //                                 },
// //                               );
// //                             },
// //                           ),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// // lib/features/apps/apps_search_screen.dart
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:safechild_system/services/installed_apps_service.dart';

// class AppsSearchScreen extends StatefulWidget {
//   static const routeName = '/apps_search';
//   const AppsSearchScreen({Key? key}) : super(key: key);

//   @override
//   State<AppsSearchScreen> createState() => _AppsSearchScreenState();
// }

// class _AppsSearchScreenState extends State<AppsSearchScreen> {
//   final InstalledAppsService _service = InstalledAppsService();
//   List<InstalledAppWrapper> _all = [];
//   List<InstalledAppWrapper> _filtered = [];
//   bool _loading = true;
//   String _query = '';

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final apps = await _service.getInstalledApps();
//       // مؤقتًا نعرض كل التطبيقات (بما في ذلك النظامية)
//       _all = apps;
//       _filtered = List.from(_all);
//       debugPrint('Loaded apps count: ${_all.length}');
//     } on MissingPluginException catch (e) {
//       debugPrint('MissingPluginException: $e — تأكد من عمل full restart بعد إضافة الحزمة');
//       _all = [];
//       _filtered = [];
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
//       final Uint8List? bytes = a.iconBytes;
//       if (bytes != null && bytes.isNotEmpty) {
//         return ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
//         );
//       }
//     } catch (_) {}
//     return const CircleAvatar(radius: 22, child: Icon(Icons.apps_outlined));
//   }

//   Future<void> _launch(InstalledAppWrapper a) async {
//     try {
//       await _service.launchApp(a.packageName);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تشغيل ${a.appName ?? a.packageName}')));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذّر تشغيل التطبيق: ${a.appName ?? a.packageName}')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(title: const Text('بحث التطبيقات')),
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
//                         ? Center(child: Text(_all.isEmpty ? 'لم تُكتشف تطبيقات' : 'لا توجد نتائج عن "$_query"'))
//                         : ListView.separated(
//                             itemCount: _filtered.length,
//                             separatorBuilder: (_, __) => const Divider(height: 1),
//                             itemBuilder: (context, i) {
//                               final app = _filtered[i];
//                               return ListTile(
//                                 leading: _buildIcon(app),
//                                 title: Text(app.appName ?? app.packageName),
//                                 subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
//                                 trailing: IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => _launch(app)),
//                                 onTap: () => _launch(app),
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
// lib/features/usage/app_usage_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:safechild_system/services/installed_apps_service.dart';


class AppUsageScreen extends StatefulWidget {
  static const routeName = '/app_usage';
  const AppUsageScreen({Key? key}) : super(key: key);

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
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
      // مؤقتًا نعرض كل التطبيقات (بما في ذلك النظامية) — عدّل الفلترة حسب حاجتك
      _all = apps;
      _filtered = List.from(_all);
      debugPrint('Apps loaded: ${_all.length}');
    } catch (e) {
      debugPrint('Error loading apps: $e');
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

  /// زر الخروج: يعيد المستخدم إلى شاشة إدارة السياسات
  void _exitToPolicySettings() {
    // نزيل كل الشاشات السابقة ونضع شاشة إدارة السياسات في القمة
    Navigator.pushNamedAndRemoveUntil(context, '/policy_settings', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة التطبيقات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _exitToPolicySettings,
            tooltip: 'العودة لإدارة السياسات',
          ),
          actions: [
            TextButton(
              onPressed: _exitToPolicySettings,
              child: const Text('خروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم التطبيق أو اسم الحزمة',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(child: Text(_all.isEmpty ? 'لم تُكتشف تطبيقات' : 'لا توجد نتائج عن \"$_query\"'))
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final app = _filtered[i];
                              return ListTile(
                                leading: _buildIcon(app),
                                title: Text(app.appName ?? app.packageName),
                                subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
                                onTap: () {
                                  // نعرض رسالة مؤقتة عند الضغط — لاحقًا يمكنك فتح شاشة إعداد الحد
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('نقرت على ${app.appName ?? app.packageName}')),
                                  );
                                },
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

