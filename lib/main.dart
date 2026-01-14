import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:safechild_system/account_type_screen.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';

import 'package:safechild_system/features/auth/data/services/auth_service.dart';
import 'package:safechild_system/services/firebase_messaging_service.dart';
import 'package:safechild_system/services/monitor_service.dart';

import 'package:safechild_system/core/di/service_locator.dart';
import 'package:safechild_system/services/permission_service.dart';
import 'package:safechild_system/services/child_location_service.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

Future<void> setupAdditionalServices() async {
  // أي خدمات إضافية يمكنك تهيئتها هنا
  debugPrint('🔹 Running setupAdditionalServices...');
  // مثال: await SomeOtherService().init();

  // Initialize location monitoring service if needed
  // ChildLocationService will be initialized when child logs in
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1️⃣ Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ [Main] Firebase initialized successfully');

    // 2️⃣ Initialize Firebase Messaging
    await FirebaseMessagingService().initialize();
    debugPrint('✅ [Main] Firebase Messaging initialized');

    // 3️⃣ Initialize authentication service
    final authService = AuthService();
    await authService.init();
    debugPrint('✅ [Main] AuthService initialized');

    // 4️⃣ Initialize monitor service (important for app blocking)
    await MonitorService().init(navigatorKey: appNavKey);
    debugPrint('✅ [Main] MonitorService initialized');

    // 5️⃣ Initialize service locator (DI)
    await setupServices();
    debugPrint('✅ [Main] Service locator initialized');

    // 6️⃣ Any additional services
    await setupAdditionalServices();
    debugPrint('✅ [Main] Additional services initialized');

    // 7️⃣ Location monitoring service will be initialized after child login
    debugPrint('📍 [Main] Location monitoring service ready for initialization');
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] Error during initialization: $e');
    debugPrint('❌ [Main] Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ main: Request location permissions when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final hasPermission = await PermissionService.isLocationPermissionGranted();
        if (!hasPermission) {
          await PermissionService.requestLocation();
        }
      } catch (e) {
        debugPrint('⚠️ [Main] Location permission request error: $e');
      }
    });

    return MaterialApp(
      navigatorKey: appNavKey, // مهم جدًا لفتح صفحات من أي مكان
      debugShowCheckedModeBanner: false,
      title: 'SafeChild',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const AccountTypeScreen(),
        '/policy_settings': (_) => const PolicySettingsScreen(),
        '/app_usage': (_) => const AppsScreen(),
      },
    );
  }
}
