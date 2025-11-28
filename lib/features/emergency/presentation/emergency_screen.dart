import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  static const Color bg     = Color(0xFFE9F6FF);
  static const Color navy   = Color(0xFF08376B);
  static const Color danger = Color(0xFFE53935);

  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد إرسال الطوارئ'),
          content: const Text('هل تريد بالتأكيد إرسال إشعار طارئ إلى ولي الأمر؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إرسال')),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      // هنا تضع استدعاء API أو منطق الإرسال الفعلي لاحقاً
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال إشعار الطوارئ ✅')),
      );
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
            child: Column(
              children: [
                const SizedBox(height: 8),
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
                      )
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
                const Spacer(),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
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
