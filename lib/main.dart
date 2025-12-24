// import 'package:flutter/material.dart';
// import 'package:safechild_system/account_type_screen.dart';
// import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
// import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
// import 'package:safechild_system/services/monitor_service.dart';

// final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await MonitorService().init(navigatorKey: appNavKey);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: appNavKey,
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       routes: {
//         '/': (_) => const AccountTypeScreen(),
//         '/policy_settings': (_) => const PolicySettingsScreen(),
//         '/app_usage': (_) => const AppsScreen(),
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safechild_system/account_type_screen.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
import 'package:safechild_system/services/monitor_service.dart';
import 'package:safechild_system/features/auth/data/services/auth_service.dart';
import 'package:safechild_system/services/firebase_messaging_service.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ [Main] Firebase initialized successfully');

    // Initialize Firebase Messaging
    await FirebaseMessagingService().initialize();
    print('✅ [Main] Firebase Messaging initialized');
  } catch (e) {
    print('❌ [Main] Firebase initialization error: $e');
  }

  // Initialize authentication service
  final authService = AuthService();
  await authService.init();

  await MonitorService().init(navigatorKey: appNavKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavKey, // مهم جدًا لفتح صفحة الحظر من أي مكان
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
