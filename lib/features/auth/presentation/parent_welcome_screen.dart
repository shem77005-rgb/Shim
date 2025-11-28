import 'package:flutter/material.dart';
import 'parent_login_screen.dart';
import 'parent_signup_screen.dart';

class ParentWelcomeScreen extends StatelessWidget {
  const ParentWelcomeScreen({super.key});

  static const Color bg = Color(0xFFE6F4FA);
  static const Color navy = Color(0xFF0A2E66);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/images/logo.png', height: 70),
                const SizedBox(height: 8),
                const Text(
                  'SafeChild system',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                  ),
                ),
                const Spacer(),

                // تسجيل الدخول → login
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('تسجيل الدخول'),
                  ),
                ),
                const SizedBox(height: 10),

                // إنشاء حساب → signup
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: navy, width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentSignupScreen(),
                        ),
                      );
                    },
                    child: const Text('إنشاء حساب'),
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  'من خلال الاستمرار، فأنت توافق على سياسة الخصوصية وشروط الاستخدام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
