// lib/widgets/access_buttons.dart
import 'package:flutter/material.dart';
import 'package:safechild_system/native_bridge.dart';
import 'package:safechild_system/widgets/role_guard.dart';



class AccessButtons extends StatelessWidget {
  const AccessButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: 'child',
      fallback: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_clock),
            label: const Text('فتح إعداد صلاحية استخدام التطبيقات'),
            onPressed: () async {
              await NativeBridge.openUsageAccessSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('افتح صفحة "Usage Access" ومنح الإذن لتطبيقك')),
              );
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.accessibility_new),
            label: const Text('فتح إعدادات الوصول (Accessibility)'),
            onPressed: () async {
              await NativeBridge.openAccessibilitySettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('افتح خدمة الوصول وقم بتفعيلها لتطبيقك')),
              );
            },
          ),
        ],
      ),
    );
  }
}
