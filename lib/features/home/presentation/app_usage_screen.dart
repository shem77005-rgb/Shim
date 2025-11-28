// // import 'dart:typed_data';
// // import 'package:device_apps/device_apps.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter/material.dart';

// // class AppUsageScreen extends StatefulWidget {
// //   const AppUsageScreen({super.key});

// //   @override
// //   State<AppUsageScreen> createState() => _AppUsageScreenState();
// // }

// // class _AppUsageScreenState extends State<AppUsageScreen> {
// //   static const Color navy = Color(0xFF0A2E66);
// //   static const Color bg = Color(0xFFF3F5F6);

// //   // التطبيقات المختارة في قائمة القيود (محلياً)
// //   final List<_AppItem> _apps = [];

// //   // نفتح نافذة اختيار التطبيقات المثبتة على الجهاز من هنا
// //   Future<List<Application>?> _loadInstalledApps() async {
// //     try {
// //       // includeAppIcons:true يجعل الجهاز يعيد أيقونة كل تطبيق (Uint8List)
// //       final list = await DeviceApps.getInstalledApplications(
// //         includeAppIcons: true,
// //         includeSystemApps: false,
// //         onlyAppsWithLaunchIntent: true,
// //       );
// //       // list قد تكون List<Application> أو List<ApplicationWithIcon>
// //       return list;
// //     } catch (e) {
// //       if (kDebugMode) print('خطأ في جلب التطبيقات: $e');
// //       return null;
// //     }
// //   }

// //   // عرض نافذة اختيار التطبيق مع بحث
// //   void _openInstalledAppsPicker() {
// //     if (!defaultTargetPlatform.toString().contains('android')) {
// //       // iOS: عرض رسالة عدم الدعم
// //       showDialog(
// //         context: context,
// //         builder: (_) => AlertDialog(
// //           title: const Text('غير مدعوم'),
// //           content: const Text('قائمة التطبيقات المثبتة متاحة فقط على Android.'),
// //           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
// //         ),
// //       );
// //       return;
// //     }

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.white,
// //       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
// //       builder: (ctx) {
// //         String query = '';
// //         return StatefulBuilder(
// //           builder: (ctx, setStateSheet) {
// //             return SizedBox(
// //               height: MediaQuery.of(ctx).size.height * 0.78,
// //               child: Padding(
// //                 padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
// //                 child: Column(
// //                   children: [
// //                     // handle
// //                     Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
// //                     // search
// //                     TextField(
// //                       decoration: InputDecoration(
// //                         hintText: 'ابحث عن تطبيق',
// //                         prefixIcon: const Icon(Icons.search),
// //                         filled: true,
// //                         fillColor: const Color(0xFFF6F7F8),
// //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
// //                       ),
// //                       onChanged: (v) => setStateSheet(() => query = v.trim().toLowerCase()),
// //                     ),
// //                     const SizedBox(height: 8),

// //                     // محتوى التطبيقات (FutureBuilder)
// //                     Expanded(
// //                       child: FutureBuilder<List<Application>?>(
// //                         future: _loadInstalledApps(),
// //                         builder: (context, snap) {
// //                           if (snap.connectionState == ConnectionState.waiting) {
// //                             return const Center(child: CircularProgressIndicator());
// //                           }
// //                           if (!snap.hasData || snap.data == null) {
// //                             return const Center(child: Text('تعذر جلب التطبيقات'));
// //                           }
// //                           final apps = snap.data!
// //                               .where((a) {
// //                                 final name = (a.appName ?? '').toLowerCase();
// //                                 if (query.isEmpty) return true;
// //                                 return name.contains(query);
// //                               })
// //                               .toList()
// //                             ..sort((a, b) => (a.appName ?? '').compareTo(b.appName ?? ''));

// //                           if (apps.isEmpty) {
// //                             return const Center(child: Text('لا توجد تطبيقات مطابقة'));
// //                           }

// //                           return ListView.separated(
// //                             itemCount: apps.length,
// //                             separatorBuilder: (_, __) => const Divider(height: 1),
// //                             itemBuilder: (ctx, idx) {
// //                               final a = apps[idx];
// //                               // إذا أُرجِع التطبيق مع أيقونة تكون الخاصية icon موجودة (Uint8List)
// //                               Uint8List? iconBytes;
// //                               if (a is ApplicationWithIcon) {
// //                                 iconBytes = a.icon;
// //                               }

// //                               return ListTile(
// //                                 leading: (iconBytes != null)
// //                                     ? ClipRRect(
// //                                         borderRadius: BorderRadius.circular(8),
// //                                         child: Image.memory(iconBytes, width: 44, height: 44, fit: BoxFit.cover),
// //                                       )
// //                                     : const Icon(Icons.apps, size: 34, color: Colors.black26),

// //                                 title: Text(a.appName ?? 'Unknown', textAlign: TextAlign.right),
// //                                 subtitle: Text(a.packageName ?? '', style: const TextStyle(fontSize: 12)),
// //                                 onTap: () {
// //                                   // عند الاختيار نضيف التطبيق إلى قائمتنا (لو لم يكن مسبقاً)
// //                                   final already = _apps.any((x) => x.package == a.packageName);
// //                                   if (!already) {
// //                                     setState(() {
// //                                       _apps.add(_AppItem(
// //                                         name: a.appName ?? 'غير معروف',
// //                                         package: a.packageName ?? '',
// //                                         icon: iconBytes,
// //                                       ));
// //                                     });
// //                                     Navigator.pop(ctx);
// //                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أضيف: ${a.appName}')));
// //                                   } else {
// //                                     Navigator.pop(ctx);
// //                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('التطبيق مُضاف بالفعل')));
// //                                   }
// //                                 },
// //                               );
// //                             },
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   // حذف تطبيق من القائمة
// //   void _removeApp(_AppItem app) {
// //     setState(() => _apps.remove(app));
// //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Directionality(
// //       textDirection: TextDirection.rtl,
// //       child: Scaffold(
// //         backgroundColor: bg,
// //         appBar: AppBar(
// //           backgroundColor: Colors.white,
// //           elevation: 0.6,
// //           leading: IconButton(
// //             icon: const Icon(Icons.chevron_left, color: Colors.black87),
// //             onPressed: () => Navigator.pop(context),
// //           ),
// //           title: const Text('مدة استخدام التطبيقات', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
// //         ),
// //         body: Padding(
// //           padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
// //           child: Column(
// //             children: [
// //               // شريط البحث / اختيار التطبيق -> عند النقر يفتح قائمة التطبيقات المثبتة
// //               Row(
// //                 children: [
// //                   // زر إضافة يظل كما هو
// //                   ElevatedButton.icon(
// //                     onPressed: _openInstalledAppsPicker,
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: const Color(0xFF27AE60),
// //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// //                     ),
// //                     icon: const Icon(Icons.add, size: 18),
// //                     label: const Text('إضافة'),
// //                   ),
// //                   const SizedBox(width: 12),

// //                   // هذا الحقل عند النقر يفتح نافذة اختيار التطبيقات المثبتة أيضاً
// //                   Expanded(
// //                     child: GestureDetector(
// //                       onTap: _openInstalledAppsPicker,
// //                       child: Container(
// //                         height: 44,
// //                         padding: const EdgeInsets.symmetric(horizontal: 12),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.circular(8),
// //                           border: Border.all(color: Colors.black12),
// //                         ),
// //                         alignment: Alignment.centerRight,
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: const [
// //                             Text('اكتب اسم التطبيق أو إضغط لاختياره', style: TextStyle(color: Colors.black54)),
// //                             Icon(Icons.arrow_drop_down),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),

// //               const SizedBox(height: 12),

// //               // قائمة التطبيقات المضافة (فارغة في البداية)
// //               Expanded(
// //                 child: _apps.isEmpty
// //                     ? const Center(child: Text('لا توجد تطبيقات مضافة بعد. اضغط إضافة لاختيار تطبيق.'))
// //                     : ListView.separated(
// //                         itemCount: _apps.length,
// //                         separatorBuilder: (_, __) => const SizedBox(height: 8),
// //                         itemBuilder: (ctx, idx) {
// //                           final app = _apps[idx];
// //                           return Row(
// //                             children: [
// //                               // زر حذف على الجهة اليسار (كما طلبت: عكس الاتجاه)
// //                               ElevatedButton(
// //                                 onPressed: () => _removeApp(app),
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: const Color(0xFFE74C3C),
// //                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //                                 ),
// //                                 child: const Text('حذف', style: TextStyle(color: Colors.white)),
// //                               ),
// //                               const SizedBox(width: 12),

// //                               // خانة اسم التطبيق
// //                               Expanded(
// //                                 child: Container(
// //                                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
// //                                   decoration: BoxDecoration(
// //                                     color: const Color(0xFFF9FAFB),
// //                                     borderRadius: BorderRadius.circular(10),
// //                                   ),
// //                                   child: Text(app.name, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
// //                                 ),
// //                               ),

// //                               const SizedBox(width: 12),

// //                               // أيقونة التطبيق على اليمين
// //                               Container(
// //                                 width: 46,
// //                                 height: 46,
// //                                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.shade100),
// //                                 child: ClipRRect(
// //                                   borderRadius: BorderRadius.circular(8),
// //                                   child: app.iconBytes != null
// //                                       ? Image.memory(app.iconBytes!, fit: BoxFit.cover)
// //                                       : const Icon(Icons.apps, color: Colors.black26),
// //                                 ),
// //                               ),
// //                             ],
// //                           );
// //                         },
// //                       ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class _AppItem {
// //   final String name;
// //   final String package;
// //   final Uint8List? iconBytes;
// //   _AppItem({required this.name, required this.package, this.iconBytes, Uint8List? icon});
// // }
// import 'package:flutter/material.dart';
// import 'package:safechild_system/features/apps/presentation/apps_screen.dart';


// class UsageLimitsScreen extends StatelessWidget {
//   static const routeName = '/policy/usage_limits';
//   const UsageLimitsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), title: const Text('مدة استخدام التطبيقات')),
//         body: const Center(child: Text('اضغط زر إدارة التطبيقات أدناه')),
//         bottomNavigationBar: Padding(
//           padding: const EdgeInsets.all(12),
//           child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppsScreen.routeName), child: const Text('إدارة التطبيقات')),
//         ),
//       ),
//     );
//   }
// }
