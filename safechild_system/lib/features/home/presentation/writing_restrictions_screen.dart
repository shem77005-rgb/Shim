import 'package:flutter/material.dart';

class WritingRestrictionsScreen extends StatefulWidget {
  const WritingRestrictionsScreen({super.key});

  @override
  State<WritingRestrictionsScreen> createState() => _WritingRestrictionsScreenState();
}

class _WritingRestrictionsScreenState extends State<WritingRestrictionsScreen> {
  bool _enabled = false;

  // ألوان المشروع — عدّل إذا تريد
  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // ---------------- Top bar ----------------
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    // Avatar (يسار الشاشة في التصميم)
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade50,
                      child: Image.asset(
                        'assets/images/avatar.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 18),
                      ),
                    ),

                    const Spacer(),

                    // Logo + اسم التطبيق في الوسط
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Safe Child System',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A2E66)),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // زر الإعدادات
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ---------- صف العنوان و زر الرجوع ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    
                    const Text(
                      'قيود الكتابة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF28323B),
                      ),
                    ),
                    const Spacer(),
                      const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: const Icon(Icons.chevron_right, color: Colors.black87),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ---------- البطاقة البيضاء مع المفتاح والوصف ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // المفتاح (Switch) - موجود جهة اليسار في التصميم
                        Switch(
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                          activeColor: Colors.white,
                          activeTrackColor: navy,
                          inactiveTrackColor: Colors.black26,
                        ),

                        const SizedBox(width: 12),

                        // نص العنوان والوصف إلى اليمين من المفتاح
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'تفعيل الخدمة',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'يمنع الطفل كتابة أو استقبال كلمات أو عبارات غير لائقة\nعن طريق تحليل النصوص بالذكاء الاصطناعي.',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black54, fontSize: 13.5, height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              // حالة موجزة (اختياري)
                              Text(
                                _enabled ? 'الحماية مفعلّة' : 'الحماية معطّلة',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _enabled ? navy : Colors.black45,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ----- شرح إضافي صغير (اختياري) -----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ملاحظة: عند تفعيل الخدمة قد يتم إيقاف إرسال بعض الرسائل التي تحتوي كلمات حساسة أو عرضها للمراجعة.',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black45, fontSize: 12.5, height: 1.3),
                ),
              ),

              // مساحة فارغة كما في التصميم
              const Expanded(child: SizedBox()),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
