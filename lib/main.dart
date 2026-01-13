import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safechild_system/account_type_screen.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
import 'package:safechild_system/services/monitor_service.dart';
import 'package:safechild_system/features/auth/data/services/auth_service.dart';
import 'package:safechild_system/services/firebase_messaging_service.dart';
import 'package:safechild_system/core/di/service_locator.dart';
import 'package:safechild_system/services/permission_service.dart';
import 'package:safechild_system/services/child_location_service.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

Future<void> setupAdditionalServices() async {
  // أي خدمات إضافية يمكنك تهيئتها هنا
  print('🔹 Running setupAdditionalServices...');
  // مثال: await SomeOtherService().init();
  
  // Initialize location monitoring service if needed
  // ChildLocationService will be initialized when child logs in
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1️⃣ Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // 2️⃣ Initialize Firebase Messaging
    await FirebaseMessagingService().initialize();
    print('✅ Firebase Messaging initialized');

    // 3️⃣ Initialize authentication
    final authService = AuthService();
    await authService.init();
    print('✅ AuthService initialized');

    // 4️⃣ Initialize monitor service
    await MonitorService().init(navigatorKey: appNavKey);
    print('✅ MonitorService initialized');

    // 5️⃣ Initialize service locator
    await setupServices();
    print('✅ Service locator initialized');

    // 6️⃣ Any additional services
    await setupAdditionalServices();
    print('✅ Additional services initialized');

    // 7️⃣ Initialize location monitoring service after login
    // ChildLocationService will be initialized when child logs in with token and childId
    print('📍 Location monitoring service ready for initialization');
  } catch (e) {
    print('❌ Error during initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Request location permissions when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool hasPermission =
          await PermissionService.isLocationPermissionGranted();
      if (!hasPermission) {
        await PermissionService.requestLocation();
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
