import 'package:flutter/material.dart';

class EmergencySettingScreen extends StatefulWidget {
  const EmergencySettingScreen({super.key});

  @override
  State<EmergencySettingScreen> createState() => _EmergencySettingScreenState();
}

class _EmergencySettingScreenState extends State<EmergencySettingScreen> {
  bool _enabled = false;
  static const Color navy = Color(0xFF0A2E66);

  @override
  Widget build(BuildContext context) {
    // نستخدم RTL لواجهة عربية؛ العنوان محاذى لليمين وزر الخروج على "نهاية السطر" (اليسار)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F8FB),
        body: SafeArea(
          child: Column(
            children: [
              // شريط علوي بسيط (شعار + أيقونة إعداد)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: navy, size: 22),
                        const SizedBox(width: 8),
                        const Text('Safe Child System',
                            style: TextStyle(fontWeight: FontWeight.w700, color: navy)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined), color: Colors.black54),
                  ],
                ),
              ),

              // ==== هنا: سطر العنوان مع زر الخروج في نهاية السطر ====
              // نضع Text مع Expanded ليأخذ المساحة، ثم زر الخروج في النهاية (يسار)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    // العنوان (محاذاة للنص لليمين)
                    Expanded(
                      child: Text(
                        'زر الطوارئ',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // زر الخروج في نهاية السطر (سيظهر على اليسار لأن الصفحة RTL)
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: Colors.black87,
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'رجوع',
                    ),
                  ],
                ),
              ),

              // البطاقة التي تحتوي على التفعيل والوصف
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // المفتاح (Switch) على اليسار بعد التوسعة (لأنه RTL)
                        Column(
                          children: [
                            Switch(
                              value: _enabled,
                              onChanged: (v) => setState(() => _enabled = v),
                              activeColor: Colors.white,
                              activeTrackColor: navy,
                              inactiveTrackColor: Colors.black12,
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // نص العنوان والوصف - محاذاة لليمين
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'تفعيل الخدمة',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'يسمح للطفل بإرسال نداء استغاثة سريع '
                                'للوالدين مع تحديد الموقع الحالي',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
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

              const SizedBox(height: 10),

              // ملاحظة حمراء كما بالصورة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: const Color(0xFFFFF4F4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: const Text(
                      'ملاحظة: استخدم هذا الزر في حالات الطوارئ فقط. '
                      'بالضغط على هذا الزر سيتم إشعار ولي الأمر فوريًا ولا يمكن التراجع بعد التنفيذ.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // حالة الخدمة في الأسفل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _enabled ? 'الخدمة مفعلة' : 'الخدمة معطلة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _enabled ? navy : Colors.black45,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
