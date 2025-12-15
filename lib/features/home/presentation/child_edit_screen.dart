import 'package:flutter/material.dart';
import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
import '../../../features/auth/data/services/auth_service.dart';

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, required this.child});
  final Child child;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.child.name);
    _age = TextEditingController(text: widget.child.age.toString());
    _email = TextEditingController(text: widget.child.email);
    _password = TextEditingController(); // Empty by default
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F5F6);
    const navy = Color(0xFF0A2E66);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'تعديل البيانات',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'بيانات الطفل',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),

                _field(_name, 'الاسم'),
                _field(_age, 'العمر'),
                _field(
                  _email,
                  'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),
                // Password field with visibility toggle
                _fieldWithHelper(
                  _password,
                  'كلمة المرور',
                  'اترك الحقل فارغاً للحفاظ على كلمة المرور الحالية',
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      // Validate input fields
                      if (_name.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال اسم الطفل'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (_email.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال البريد الإلكتروني'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Password is optional - only validate if provided
                      if (_password.text.isNotEmpty &&
                          _password.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final age = int.tryParse(_age.text);
                      if (age == null || age <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال عمر صحيح'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      print('🔵 [ChildEditScreen] بدء حفظ التغييرات');
                      print(
                        '🔵 [ChildEditScreen] Child ID: ${widget.child.id}',
                      );
                      print('🔵 [ChildEditScreen] Name: ${_name.text.trim()}');
                      print(
                        '🔵 [ChildEditScreen] Email: ${_email.text.trim()}',
                      );
                      print('🔵 [ChildEditScreen] Age: $age');

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        final authService = AuthService();
                        final childService = ChildService(
                          apiClient: authService.apiClient,
                        );

                        print('🔵 [ChildEditScreen] إرسال الطلب إلى الخادم...');
                        final response = await childService.updateChild(
                          childId: widget.child.id,
                          parentId: widget.child.parentId,
                          password:
                              _password.text.isNotEmpty ? _password.text : null,
                          email: _email.text.trim(),
                          name: _name.text.trim(),
                          age: age,
                        );

                        // Hide loading indicator
                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        if (response.isSuccess && response.data != null) {
                          print('✅ [ChildEditScreen] تم حفظ البيانات بنجاح');

                          // Show success message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ البيانات بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Return updated child data from server
                            Navigator.pop(context, response.data);
                          }
                        } else {
                          print(
                            '❌ [ChildEditScreen] فشل في حفظ البيانات: ${response.error}',
                          );

                          // Show error message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response.error ?? 'فشل في حفظ البيانات',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e, stackTrace) {
                        // Hide loading indicator
                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        print('❌ [ChildEditScreen] خطأ في تحديث الطفل: $e');
                        print('❌ [ChildEditScreen] Stack trace: $stackTrace');

                        // Show error message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _fieldWithHelper(
    TextEditingController c,
    String label,
    String helperText, {
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
