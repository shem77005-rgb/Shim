import 'package:flutter/material.dart';
import 'package:safechild_system/features/emergency/presentation/emergency_screen.dart';
import '../../auth/data/services/auth_service.dart';
import '../../../models/child_model.dart';
import '../../../models/child_login_response.dart';
import '../../../services/child_location_service.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  final _authService = AuthService();

  static const Color bg = Color(0xFFE9F6FF); // أزرق فاتح
  static const Color navy = Color(0xFF08376B); // أزرق داكن
  static const Color border = Color(0xFF2C5A85);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Image.asset(
                  'assets/images/logo.png',
                  width: 70,
                  height: 70,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تسجيل دخول الطفل',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0A7ABD),
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _LabeledField(
                        label: 'البريد الإلكتروني',
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'أدخل البريد الإلكتروني';
                            }
                            final rx = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                            if (!rx.hasMatch(v.trim())) {
                              return 'صيغة البريد غير صحيحة';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'كلمة المرور',
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textDirection: TextDirection.ltr,
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'أدخل كلمة المرور'
                                      : null,
                          decoration: _inputDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: navy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      setState(() => _isLoading = true);

                                      try {
                                        // Use childLoginWithData to authenticate and fetch child data
                                        final response = await _authService
                                            .childLoginWithData(
                                              email: _email.text.trim(),
                                              password: _password.text,
                                            );

                                        if (!mounted) return;

                                        if (response.isSuccess &&
                                            response.data != null) {
                                          // Success - Initialize location monitoring service
                                          final child = response.data!;
                                          final token =
                                              await _authService.getToken();
                                          if (token != null) {
                                            // Parse the ID as integer since Child model has String ID
                                            int childId =
                                                int.tryParse(
                                                  child.id.toString(),
                                                ) ??
                                                0;

                                            ChildLocationService.initialize(
                                              token,
                                              childId,
                                            );

                                            // Start location monitoring
                                            try {
                                              await ChildLocationService.startLocationMonitoring();
                                              print(
                                                '✅ Location monitoring started for child $childId',
                                              );
                                            } catch (e) {
                                              print(
                                                '⚠️ Error starting location monitoring: $e',
                                              );
                                            }
                                          } else {
                                            print(
                                              '⚠️ Could not get access token for location monitoring',
                                            );
                                          }

                                          // Navigate to emergency screen with child data
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم تسجيل الدخول بنجاح',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EmergencyScreen(
                                                    child: response.data!,
                                                  ),
                                            ),
                                          );
                                        } else {
                                          // Error - Show error message
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                response.error ??
                                                    'فشل تسجيل الدخول',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'حدث خطأ: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  },

                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'دخول',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
