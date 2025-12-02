import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../home/presentation/home_screen.dart';
import 'parent_signup_screen.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    if (!ok) return 'صيغة البريد غير صحيحة';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
    final hasLen  = v.length >= 8;
    final hasUp   = RegExp(r'[A-Z]').hasMatch(v);
    final hasLow  = RegExp(r'[a-z]').hasMatch(v);
    final hasNum  = RegExp(r'[0-9]').hasMatch(v);
    final hasSpec = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v);
    if (!(hasLen && hasUp && hasLow && hasNum && hasSpec)) {
      return 'كلمة المرور ضعيفة: 8+ وتتضمن كبير/صغير/رقم/رمز.';
    }
    return null;
  }

  void _submit() {
  final ok = _formKey.currentState?.validate() ?? false;
  if (!ok) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (_) => false,
  );
}


  @override
  Widget build(BuildContext context) {
    const bg   = Color(0xFFE6F4FA);
    const navy = Color(0xFF0A2E66);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Image.asset('assets/images/logo.png', height: 60),
                  const SizedBox(height: 8),
                  const Text('تسجيل دخول وليّ الأمر',
                      style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),

                  // البريد
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'name@example.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),

                  // كلمة المرور
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: _validatePassword,
                  ),

                  const SizedBox(height: 20),

                  // زر دخول
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // رابط إنشاء حساب
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                      children: [
                        const TextSpan(text: 'ليس لديك حساب؟ '),
                        TextSpan(
                          text: 'أنشئ حسابًا جديدًا',
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ParentSignupScreen()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
