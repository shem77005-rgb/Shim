import 'package:flutter/material.dart';

class BlockSitesScreen extends StatefulWidget {
  const BlockSitesScreen({super.key});

  @override
  State<BlockSitesScreen> createState() => _BlockSitesScreenState();
}

class _BlockSitesScreenState extends State<BlockSitesScreen> {
  bool _enabled = false;

  // ألوان المشروع (عدّل إن أردت)
  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);

  @override
  Widget build(BuildContext context) {
    // الصفحة مصمَّمة للّغة العربية -> RTL
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              // --- الشريط العلوي: (avatar - logo - settings) ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    // صورة الحساب (على اليسار كما في الصورة)
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

                    // شعار في الوسط
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

              // --- صف العنوان مع سهم الرجوع (كما بالصورة: السهم على اليسار ثم العنوان) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                   
                    const SizedBox(width: 8),

                    // العنوان (موجود إلى يمين السهم)
                    const Text(
                      'حظر المواقع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF28323B),
                      ),
                    ),

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

              const SizedBox(height: 16),

              // --- البطاقة البيضاء مع المفتاح والوصف (مطابقة للتصميم) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // المفتاح (Switch) على يسار البطاقة كما في الصورة
                        Switch(
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                          activeColor: Colors.white,
                          activeTrackColor: navy,
                          inactiveTrackColor: Colors.black26,
                        ),

                        const SizedBox(width: 12),

                        // النصوص (عنوان + وصف) إلى اليمين من المفتاح
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'تفعيل الخدمة',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'منع الطفل من دخول مواقع غير مناسبة\nمن خلال تحليل المحتوى أو قوائم مخصّصة.',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: Colors.black54, fontSize: 13.5, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // فراغ مركزي مطابق للتصميم (الصفحة فارغة بخلاف البطاقة)
              const Expanded(child: SizedBox()),

              // مسافة سفلية بسيطة (ما في زر في الصورة)
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
