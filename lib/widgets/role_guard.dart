import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final Widget fallback; // يظهر للأب بدل شاشة الصلاحيات
  final String allowedRole; // 'child' افتراضياً

  const RoleGuard({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    this.allowedRole = 'child',
  });

  Future<String> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('user_role') ?? '').trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getRole(),
      builder: (context, snap) {
        final role = (snap.data ?? '').trim().toLowerCase();

        // أثناء التحميل: لا تعرض أزرار الطفل
        if (snap.connectionState != ConnectionState.done) {
          return fallback;
        }

        if (role == allowedRole) return child;
        return fallback;
      },
    );
  }
}
