// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_accessibility_service/constants.dart';
// import 'package:usage_stats/usage_stats.dart';
// import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
// import 'usage_service.dart';
// import '../features/apps/presentation/block_screen.dart';

// class AppBlockerService {
//   static final AppBlockerService _instance = AppBlockerService._internal();
//   factory AppBlockerService() => _instance;
//   AppBlockerService._internal();

//   static Timer? _timer;
//   static bool _isBlocked = false;

//   /// تهيئة الخدمة
//   static void init({
//     required BuildContext context,
//     required String targetPackage,
//     required Duration used,
//     required Duration limit,
//     required String appName,
//   }) {
//     // إلغاء أي مؤقت سابق لتجنب التكرار
//     _timer?.cancel();
//     _isBlocked = false;

//     // مراقبة الوقت بشكل دوري
//     _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
//       // 1. هل التطبيق في الواجهة الآن؟
//       bool isFg = await _isAppForeground(targetPackage);
      
//       // حماية إضافية: تأكد أن التطبيق ليس تطبيقنا (Supervision App)
//       // (يفترض أن targetPackage هو التطبيق المراد حظره، ولكن لزيادة الأمان)
//       if (targetPackage == 'com.example.safechild_system') isFg = false; // لا تحظر تطبيق الرقابة أبداً

//       if (!isFg) return; 

//       // 2. هل تجاوز الوقت؟
//       Duration currentUsed = await _getAppUsage(targetPackage);
//       if (currentUsed >= limit && !_isBlocked) {
//         _timer?.cancel();
        
//         // محاولة إغلاق التطبيق فوراً (الذهاب للقائمة الرئيسية)
//         try {
//            bool permission = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
//            if (permission) {
//              await FlutterAccessibilityService.performGlobalAction(
//                 GlobalAction.globalActionHome
//              );
//            }
//         } catch (e) {
//           debugPrint("Accessibility Error: $e");
//         }

//         // عرض شاشة الحظر (ستظهر إذا كان المستخدم داخل تطبيقنا، أو كطبقة إذا كنا نستخدم Overlay مستقبلاً)
//         // لكن بما أننا أغلقنا التطبيق (globalHome)، فهذا الإجراء ثانوي
//          _blockApp(context, targetPackage, appName);
//       }
//     });
//   }

//   /// التحقق هل التطبيق المستهدف هو الذي يعمل حالياً في الواجهة
//   static Future<bool> _isAppForeground(String targetPkg) async {
//     try {
//       // 1. محاولة استخدام Accessibility Service للدقة العالية والاستجابة الفورية
//       bool isAccessEnabled = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
//       if (isAccessEnabled) {
//          // هذه الدالة تعتمد على التدفق، لذا سنستخدم UsageStats كبديل فوري
//          // ولكن في حالة توفر الخدمة، يفضل الاعتماد على المستمع (Listener) في init
//          // هنا سنبقي على UsageEvents كنسخة احتياطية
//       }

//       DateTime now = DateTime.now();
//       DateTime start = now.subtract(Duration(minutes: 5));

//       List<EventUsageInfo> events = await UsageStats.queryEvents(start, now);
      
//       for (var i = events.length - 1; i >= 0; i--) {
//         final event = events[i];
//         if (event.eventType == '1') { // MOVE_TO_FOREGROUND
//           return event.packageName == targetPkg;
//         }
//       }
      
//       return false;
//     } catch (e) {
//       debugPrint("Error checking foreground app: $e");
//       return false;
//     }
//   }

//   static Future<Duration> _getAppUsage(String packageName) async {
//     try {
//       final usageMap = await getTodayUsageMillis();
//       final ms = usageMap[packageName] ?? 0;
//       return Duration(milliseconds: ms);
//     } catch (e) {
//       debugPrint("Error fetching app usage: $e");
//       return Duration.zero;
//     }
//   }

//   /// عرض شاشة الحظر
//   static void _blockApp(BuildContext context, String targetPackage, String appName) {
//     _isBlocked = true;

//     // منع العودة أو إغلاق الشاشة بسهولة
//     Navigator.of(context).pushReplacement(MaterialPageRoute(
//       builder: (_) => WillPopScope(
//         onWillPop: () async => false,
//         child: BlockPage(appName: appName),
//       ),
//     ));
//   }

//   static void dispose() {
//     _timer?.cancel();
//   }
// }

