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
import 'package:safechild_system/account_type_screen.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
import 'package:safechild_system/services/monitor_service.dart';
import 'package:safechild_system/features/auth/data/services/auth_service.dart';

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
