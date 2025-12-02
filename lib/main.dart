// import 'package:flutter/material.dart';
// import 'package:safechild_system/features/apps/presentation/apps_screen.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SafeChild — Apps Search',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: false,
//       ),
//       // الصفحة الرئيسية المؤقتة تعرض شاشة البحث للتجربة
//       home: const AppsSearchScreen(),
//       routes: {
//         AppsSearchScreen.routeName: (_) => const AppsSearchScreen(),
//         // أضف هنا بقية المسارات إذا رغبت لاحقاً
//       },
//     );
//   }
// }
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:safechild_system/account_type_screen.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeChild',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const AccountTypeScreen(),
        '/policy_settings': (_) => const PolicySettingsScreen(),
        AppUsageScreen.routeName: (_) => const AppUsageScreen(),
      },
    );
  }
}
