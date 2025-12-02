// // lib/services/installed_apps_service.dart
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:appcheck/appcheck.dart';

// class InstalledAppInfo {
//   final String packageName;
//   final String? appName;
//   final bool? isSystemApp;
//   final String? iconBase64;

//   InstalledAppInfo({
//     required this.packageName,
//     this.appName,
//     this.isSystemApp,
//     this.iconBase64,
//   });

//   Uint8List? get iconBytes {
//     if (iconBase64 == null || iconBase64!.isEmpty) return null;
//     try {
//       return base64Decode(iconBase64!);
//     } catch (_) {
//       return null;
//     }
//   }

//   @override
//   String toString() {
//     return 'InstalledAppInfo(package:$packageName,name:$appName,system:$isSystemApp)';
//   }
// }

// class InstalledAppsService {
//   final AppCheck _appCheck = AppCheck();

//   InstalledAppsService();

//   Future<List<InstalledAppInfo>> getInstalledApps() async {
//     try {
//       final raw = await _appCheck.getInstalledApps();

//        print('DEBUG raw type: ${raw.runtimeType}\nraw: $raw');

//       final List<InstalledAppInfo> out = [];
//       if (raw == null) return out;

//       Iterable items;
//       if (raw is Iterable) {
//         items = raw;
//       } else {
//         items = [raw];
//       }

//       bool? parseBool(dynamic v) {
//         if (v == null) return null;
//         if (v is bool) return v;
//         if (v is int) return v != 0;
//         if (v is String) {
//           final s = v.toLowerCase().trim();
//           if (s == 'true' || s == '1') return true;
//           if (s == 'false' || s == '0') return false;
//         }
//         return null;
//       }

//       for (final dynamic r in items) {
//         try {
//           if (r == null) continue;

//           String pkg = '';
//           String? name;
//           bool? sys;
//           String? icon;

//           if (r is Map) {
//             // لو العنصر Map نأخذ الحقول المحتملة
//             final pkgRaw = r['packageName'] ?? r['package'] ?? r['pkg'] ?? r['package_name'];
//             pkg = pkgRaw?.toString() ?? '';

//             final nameRaw = r['appName'] ?? r['name'] ?? r['label'];
//             name = nameRaw?.toString();

//             sys = parseBool(r['isSystemApp'] ?? r['system'] ?? r['is_system']);

//             final iconRaw = r['icon'] ?? r['iconBase64'] ?? r['appIcon'];
//             icon = iconRaw != null ? iconRaw.toString() : null;
//           } else {
//             // العنصر قد يكون كائن AppInfo من appcheck (أو أي كائن) -> نستخدم وصول ديناميكي
//             try {
//               final dyn = r as dynamic;
//               final pkgRaw = dyn.packageName ?? dyn.package ?? dyn.pkg;
//               pkg = pkgRaw?.toString() ?? '';

//               final nameRaw = dyn.appName ?? dyn.name ?? dyn.label;
//               name = nameRaw?.toString();

//               sys = parseBool(dyn.isSystemApp ?? dyn.system ?? dyn.is_system);

//               final iconRaw = dyn.icon ?? dyn.iconBase64 ?? dyn.appIcon;
//               icon = iconRaw != null ? iconRaw.toString() : null;
//             } catch (_) {
//               // كحل احتياطي: استخدم تمثيل النصي كـ package
//               pkg = r.toString();
//             }
//           }

//           if (pkg.isEmpty) continue; // نتخطّى العناصر بدون packageName

//           out.add(InstalledAppInfo(
//             packageName: pkg,
//             appName: name,
//             isSystemApp: sys,
//             iconBase64: icon,
//           ));
//         } catch (_) {
//           // تجاهل عنصر واحد معطوب واستمر
//           continue;
//         }
//       }

//       // فرز النتائج أبجدياً حسب الاسم الظاهر أو اسم الحزمة
//       out.sort((a, b) => (a.appName ?? a.packageName).toLowerCase().compareTo((b.appName ?? b.packageName).toLowerCase()));

//       return out;
//     } catch (e, st) {

//        print('InstalledAppsService error: $e');
//        print(st);
//       return [];
//     }
//   }

//   Future<bool> isInstalled(String packageName) async {
//     try {
//       return await _appCheck.isAppInstalled(packageName);
//     } catch (_) {
//       return false;
//     }
//   }

//   Future<void> launchApp(String packageName) async {
//     try {
//       await _appCheck.launchApp(packageName);
//     } catch (e) {
//       rethrow;
//     }
//   }
// }
// lib/services/installed_apps_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:appcheck/appcheck.dart';
import 'package:flutter/foundation.dart';

class InstalledAppWrapper {
  final String packageName;
  final String? appName;
  final bool? isSystemApp;
  final String? iconBase64;

  InstalledAppWrapper({
    required this.packageName,
    this.appName,
    this.isSystemApp,
    this.iconBase64,
  });

  Uint8List? get iconBytes {
    if (iconBase64 == null || iconBase64!.isEmpty) return null;
    try {
      return base64Decode(iconBase64!);
    } catch (_) {
      return null;
    }
  }
}

class InstalledAppsService {
  final AppCheck _appCheck = AppCheck();

  Future<List<InstalledAppWrapper>> getInstalledApps() async {
    try {
      final raw = await _appCheck.getInstalledApps();
      // DEBUG: اطبع مرة واحدة لتعرف شكل البيانات على جهازك
      // debugPrint('DEBUG raw type: ${raw.runtimeType} -> $raw');

      final List<InstalledAppWrapper> out = [];
      if (raw == null) return out;

      // raw غالبًا Iterable<AppInfo>
      Iterable items;
      if (raw is Iterable) {
        items = raw;
      } else {
        items = [raw];
      }

      for (final dynamic r in items) {
        try {
          if (r == null) continue;
          // r قد يكون AppInfo (من appcheck) أو Map
          String pkg = '';
          String? name;
          bool? sys;
          String? icon;

          if (r is Map) {
            pkg = (r['packageName'] ?? r['package'] ?? '').toString();
            name = (r['appName'] ?? r['name'])?.toString();
            final sysRaw = r['isSystemApp'] ?? r['system'];
            if (sysRaw is bool) sys = sysRaw;
            if (sysRaw is int) sys = sysRaw != 0;
            if (sysRaw is String) sys = sysRaw.toLowerCase() == 'true';
            icon = (r['icon'] ?? r['iconBase64'])?.toString();
          } else {
            // dynamic access to AppInfo-like object
            try {
              final dyn = r as dynamic;
              pkg = (dyn.packageName ?? dyn.package ?? '')?.toString() ?? '';
              name = (dyn.appName ?? dyn.name)?.toString();
              final sysRaw = dyn.isSystemApp ?? dyn.system;
              if (sysRaw is bool) sys = sysRaw;
              if (sysRaw is int) sys = sysRaw != 0;
              if (sysRaw is String) sys = sysRaw.toLowerCase() == 'true';
              icon = (dyn.icon ?? dyn.iconBase64)?.toString();
            } catch (_) {
              pkg = r.toString();
            }
          }

          if (pkg.isEmpty) continue;
          out.add(
            InstalledAppWrapper(
              packageName: pkg,
              appName: name,
              isSystemApp: sys,
              iconBase64: icon,
            ),
          );
        } catch (_) {
          continue;
        }
      }

      out.sort(
        (a, b) => (a.appName ?? a.packageName).toLowerCase().compareTo(
          (b.appName ?? b.packageName).toLowerCase(),
        ),
      );
      return out;
    } catch (e) {
      debugPrint('InstalledAppsService.getInstalledApps error: $e');
      return [];
    }
  }

  Future<bool> isInstalled(String package) async {
    try {
      return await _appCheck.isAppInstalled(package);
    } catch (_) {
      return false;
    }
  }

  Future<void> launchApp(String package) async {
    try {
      await _appCheck.launchApp(package);
    } catch (e) {
      rethrow;
    }
  }
}
