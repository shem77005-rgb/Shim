import 'package:flutter/material.dart';
import 'package:safechild_system/features/auth/presentation/child_login_screen.dart';
import 'package:safechild_system/features/onboarding/presentation/parent_onboarding_screen.dart';


class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  static const Color bg   = Color(0xFFE9F6FF);
  static const Color navy = Color(0xFF08376B);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // لوجو (اختياري)
                Image.asset(
                  'assets/images/logo.png',
                  width: 72,
                  height: 72,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اختر نوع حسابك',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: _TypeCard(
                        title: 'طفل',
                        asset: 'assets/images/child.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChildLoginScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TypeCard(
                        title: 'وليّ أمر',
                        asset: 'assets/images/parent.png',
                        onTap: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const  ParentOnboardingScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.title, required this.asset, required this.onTap});
  final String title;
  final String asset;
  final VoidCallback onTap;

  static const Color border = Color(0xFF2C5A85);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(asset, width: 44, height: 44, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: border),
            ),
            const SizedBox(height: 10),
            const Text.rich(
              TextSpan(
                text: '',
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
