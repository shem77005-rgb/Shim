import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'parent_login_screen.dart';

class ParentSignupScreen extends StatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  State<ParentSignupScreen> createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends State<ParentSignupScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  final _confirm  = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    if (!ok) return 'صيغة البريد غير صحيحة';
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
    final strong = v.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(v) &&
        RegExp(r'[a-z]').hasMatch(v) &&
        RegExp(r'[0-9]').hasMatch(v) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v);
    if (!strong) return 'اجعلها قوية (8+ كبير/صغير/رقم/رمز).';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'أعد إدخال كلمة المرور';
    if (v != _pass.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // TODO: استدعاء API لإنشاء الحساب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الحساب بنجاح (تجريبي)')),
    );
    // رجوع لشاشة الدخول:
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ParentLoginScreen()),
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
                  const SizedBox(height: 8),
                  Image.asset('assets/images/logo.png', height: 60),
                  const SizedBox(height: 8),
                  const Text(
                    'إنشاء حساب وليّ الأمر',
                    style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),

                  // البريد الإلكتروني
                  TextFormField(
                    controller: _email,
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
                    controller: _pass,
                    obscureText: _obscure1,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                        icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: _validatePass,
                  ),
                  const SizedBox(height: 12),

                  // إعادة كلمة المرور
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    decoration: InputDecoration(
                      labelText: 'إعادة كلمة المرور',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                        icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: _validateConfirm,
                  ),

                  const SizedBox(height: 22),

                  // زر إنشاء حساب
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
                      onPressed: _submit,
                      child: const Text('إنشاء حساب'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // زر Google (تصميم فقط)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: navy, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الدخول عبر Google (تصميم)')),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white,
                            child: Text('G', style: TextStyle(color: Colors.black)),
                          ),
                          SizedBox(width: 8),
                          Text('الدخول عبر Google'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // لديك حساب؟ تسجيل الدخول
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                      children: [
                        const TextSpan(text: 'لديك حساب؟ '),
                        TextSpan(
                          text: 'تسجيل الدخول',
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const ParentLoginScreen()),
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
