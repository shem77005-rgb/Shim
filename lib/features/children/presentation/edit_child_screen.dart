import 'package:flutter/material.dart';
import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
import '../../../core/api/api_response.dart';

class EditChildScreen extends StatefulWidget {
  final Child child;

  const EditChildScreen({Key? key, required this.child}) : super(key: key);

  @override
  _EditChildScreenState createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _emailController = TextEditingController(text: widget.child.email);
    _ageController = TextEditingController(text: widget.child.age.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final childService = ChildService();
      final response = await childService.updateChild(
        childId: widget.child.id,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? widget.child.age,
      );

      if (response.isSuccess && response.data != null) {
        // Successfully updated child
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث معلومات الطفل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with updated child
        Navigator.pop(context, response.data);
      } else {
        setState(() {
          _errorMessage = response.error ?? 'فشل في تحديث معلومات الطفل';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F5F6);
    const Color navy = Color(0xFF0A2E66);
    const Color darkTxt = Color(0xFF28323B);

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
                    'معلومات الطفل',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),

                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        _nameController,
                        'الاسم',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),

                      _field(
                        _emailController,
                        'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),

                      _field(
                        _ageController,
                        'العمر',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال العمر';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age <= 0 || age > 100) {
                            return 'يرجى إدخال عمر صحيح';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

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
                          onPressed: _isLoading ? null : _updateChild,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text('حفظ التحديثات'),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
      ),
    );
  }
}
