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
    
      // debugPrint('DEBUG raw type: ${raw.runtimeType} -> $raw');

      final List<InstalledAppWrapper> out = [];
      if (raw == null) return out;

      Iterable items;
      if (raw is Iterable) {
        items = raw;
      } else {
        items = [raw];
      }

      for (final dynamic r in items) {
        try {
          if (r == null) continue;
          
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
          out.add(InstalledAppWrapper(
            packageName: pkg,
            appName: name,
            isSystemApp: sys,
            iconBase64: icon,
          ));
        } catch (_) {
          continue;
        }
      }

      out.sort((a, b) => (a.appName ?? a.packageName).toLowerCase()
          .compareTo((b.appName ?? b.packageName).toLowerCase()));
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

