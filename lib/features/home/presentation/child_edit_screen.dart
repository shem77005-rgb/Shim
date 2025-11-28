import 'package:flutter/material.dart';
import 'home_screen.dart';

class ChildEditScreen extends StatefulWidget {
  const ChildEditScreen({super.key, required this.child});
  final ChildModel child;

  @override
  State<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends State<ChildEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _gender;
  late final TextEditingController _email;
  late final TextEditingController _pass;

  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _name   = TextEditingController(text: widget.child.name);
    _age    = TextEditingController(text: widget.child.age);
    _gender = TextEditingController(text: widget.child.gender);
    _email  = TextEditingController(text: widget.child.email);
    _pass   = TextEditingController(text: widget.child.password);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _gender.dispose();
    _email.dispose();
    _pass.dispose();
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
                    const Text('تعديل البيانات',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text('بيانات الطفل',
                      style: TextStyle(color: navy, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),

                _field(_name, 'الاسم'),
                _field(_age, 'العمر'),
                _field(_gender, 'الجنس'),
                _field(_email, 'البريد الإلكتروني', keyboardType: TextInputType.emailAddress),
                _field(_pass, 'كلمة المرور',
                    obscure: _obscure,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final updated = widget.child.copyWith(
                        name: _name.text.trim(),
                        age: _age.text.trim(),
                        gender: _gender.text.trim(),
                        email: _email.text.trim(),
                        password: _pass.text,
                      );
                      Navigator.pop(context, updated);
                    },
                    child: const Text('حفظ'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? keyboardType, Widget? suffix}) {
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
