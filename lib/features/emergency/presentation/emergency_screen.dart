import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/child_model.dart';
import '../../../services/emergency_service.dart';
import '../../auth/data/services/auth_service.dart';
import '../../children/presentation/child_login_screen.dart';

class EmergencyScreen extends StatefulWidget {
  final Child? child;

  const EmergencyScreen({super.key, this.child});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  static const Color bg = Color(0xFFE9F6FF);
  static const Color navy = Color(0xFF08376B);
  static const Color danger = Color(0xFFE53935);

  late final AnimationController _pulse;
  late final Animation<double> _scale;

  late final EmergencyService _emergencyService;
  // Use the singleton instance of AuthService
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Initialize the emergency service with the authenticated API client
    _emergencyService = EmergencyService(apiClient: _authService.apiClient);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد إرسال الطوارئ'),
              content: const Text(
                'هل تريد بالتأكيد إرسال إشعار طارئ إلى ولي الأمر؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('إرسال'),
                ),
              ],
            ),
          ),
    );

    if (ok == true && mounted) {
      try {
        // Get the current user (child)
        final currentUser = await _authService.getCurrentUser();

        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'خطأ: لم يتم تحميل معلومات المستخدم. الرجاء تسجيل الدخول مرة أخرى.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Navigate back to login screen
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Get parent ID - either from the child object or from auth service
        String parentId = '';
        if (widget.child != null && widget.child!.parentId.isNotEmpty) {
          parentId = widget.child!.parentId;
        } else {
          // Fallback to getting parent ID from auth service
          final prefs = await SharedPreferences.getInstance();
          parentId = prefs.getString('parent_id') ?? '';
        }

        // Validate we have both child and parent IDs
        if (currentUser.id.isEmpty || parentId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('خطأ: معلومات المستخدم غير مكتملة'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Send emergency alert
        final response = await _emergencyService.sendEmergencyAlert(
          childId: currentUser.id,
          parentId: parentId,
        );

        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال إشعار الطوارئ ✅'),
              backgroundColor: Colors.green,
            ),
          );

          // Log the emergency alert
          debugPrint(
            'Emergency alert sent for child: ${currentUser.name} (ID: ${currentUser.id}) to parent ID: $parentId',
          );
        } else if (mounted) {
          // Handle specific authentication errors
          String errorMessage = response.error ?? 'فشل في إرسال إشعار الطوارئ';

          // Check if it's an authentication error
          if (errorMessage.contains(
                'Authentication credentials were not provided',
              ) ||
              errorMessage.contains('انتهت جلسة العمل')) {
            errorMessage = 'انتهت جلسة العمل. الرجاء تسجيل الدخول مرة أخرى.';

            // Navigate back to login screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
                  (route) => false,
                );
              }
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        debugPrint('Error sending emergency alert: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: .5,
          centerTitle: true,
          title: const Text(
            'زر الطوارئ',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Display child information if available
                  if (widget.child != null) ...[
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معلومات الطفل:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('الاسم: ${widget.child!.name}'),
                            Text('البريد الإلكتروني: ${widget.child!.email}'),
                            Text('العمر: ${widget.child!.age} سنة'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // نبض دائري مع صورة الطوارئ في المنتصف (استبدال الأيقونة بالصورة)
                  Image.asset('assets/images/emergency.png'),

                  const SizedBox(height: 12),
                  const Text(
                    'استخدم هذا الزر في الحالات الطارئة فقط',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // بطاقة تنبيه
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه :',
                          style: TextStyle(
                            color: danger,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'بالضغط على هذا الزر سيتم إشعار ولي الأمر فورًا مع الموقع الحالي، ولا يمكن التراجع بعد التنفيذ.',
                          style: TextStyle(fontSize: 14.5, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // زر إرسال الطوارئ
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: danger,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _confirmAndSend,
                      child: const Text(
                        'إرسال طوارئ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('_scale', _scale));
  }
}
