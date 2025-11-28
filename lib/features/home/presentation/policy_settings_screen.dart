import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/home/presentation/writing_restrictions_screen.dart';

// استورد الشاشات التي نفتحها من هنا:
import 'emergency_setting_screen.dart';
import 'block_sites_screen.dart'; // <-- تأكد أن هذا الملف موجود في المسار/أعد اسم المسار إن لزم

class PolicySettingsScreen extends StatefulWidget {
  const PolicySettingsScreen({super.key});

  @override
  State<PolicySettingsScreen> createState() => _PolicySettingsScreenState();
}

class _PolicySettingsScreenState extends State<PolicySettingsScreen> {
  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);
  static const Color info = Color(0xFFE8F3FF);

  final List<String> _children = ['أحمد', 'لانا', 'يوسف'];
  int _selectedChild = 0;

  // البيانات: العنوان + المسار للصورة + الوصف
  final List<_Restriction> _items = [
    _Restriction(
      title: 'الطوارئ',
      asset: 'assets/images/crisis.png',
      desc: 'يسمح للطفل بإرسال إشعار طارئ سريع للوَلِي مع أحدث موقع آني.',
    ),
    _Restriction(
      title: 'مدة استخدام التطبيقات',
      asset: 'assets/images/usage (1).png',
      desc: 'تحدد المدة اليومية المسموح بها للتطبيقات. يمكن تخصيصها لكل تطبيق.',
    ),
    _Restriction(
      title: 'حظر المواقع',
      asset: 'assets/images/sign.png',
      desc: 'منع تصفُّح مواقع معيّنة عبر فلترة عناوين الويب وقوائم مخصّصة.',
    ),
    _Restriction(
      title: 'القيود الجغرافية',
      asset: 'assets/images/geo.png',
      desc: 'إنذار عند الخروج/الدخول من وإلى مناطق محددة (مدرسة، منزل، نشاط).',
    ),
    _Restriction(
      title: 'قيود الكتابة',
      asset: 'assets/images/keyboard.png',
      desc:
          'منع أو مراجعة نصوص حساسة باستخدام الذكاء الاصطناعي على مستوى النظام.',
    ),
    _Restriction(
      title: 'التقارير',
      asset: 'assets/images/infographic.png',
      desc: 'تقارير أسبوعية لنشاط الطفل والتنبيهات مع ملخص للأوقات والمحتوى.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,

        // سهم رجوع لليمين (ملائم للـ RTL)
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إدارة السياسات',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'اختر طفلاً',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_children.length, (i) {
                  final selected = _selectedChild == i;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        _children[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : navy,
                        ),
                      ),
                      selected: selected,
                      selectedColor: navy,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selected ? navy : Colors.black12),
                      onSelected: (_) => setState(() => _selectedChild = i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'القيود',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // عرض البنود
            ..._items.map(
              (item) => _RestrictionTile(
                item: item,
                onOpen: () {
                  // الآن: افتح شاشة مخصصة لكل بند حسب العنوان
                  if (item.title == 'الطوارئ') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencySettingScreen(),
                      ),
                    );
                    return;
                  }

                  if (item.title == 'حظر المواقع') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockSitesScreen(),
                      ),
                    );
                    return;
                  }

              
                  if (item.title == 'مدة استخدام التطبيقات') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppUsageScreen(),
                      ),
                    );
                    return;
                  }
                  
                 
                  if (item.title == 'قيود الكتابة') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WritingRestrictionsScreen(),
                      ),
                    );
                    return;
                  }
                  

                  // افتراضي: رسالة مؤقتة
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فتح إعداد: ${item.title}')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('info', info));
  }
}

// ====== نماذج وعناصر مساعدة ======

class _Restriction {
  final String title;
  final String asset;
  final String desc;
  bool showHelp;
  _Restriction({
    required this.title,
    required this.asset,
    required this.desc,
    this.showHelp = false,
  });
}

class _RestrictionTile extends StatefulWidget {
  const _RestrictionTile({required this.item, required this.onOpen});
  final _Restriction item;
  final VoidCallback onOpen;

  @override
  State<_RestrictionTile> createState() => _RestrictionTileState();
}

class _RestrictionTileState extends State<_RestrictionTile> {
  @override
  Widget build(BuildContext context) {
    const Color infoBg = Color(0xFFE8F3FF);
    const Color navy = Color(0xFF0A2E66);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: Column(
          children: [
            ListTile(
              // الصورة (بدل الأيقونة)
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: navy.withOpacity(.06),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  widget.item.asset,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  // لو الصورة ناقصة ما يخرب التصميم
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
              title: Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900, // خط واضح
                  color: Color(0xFF28323B),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر التعليمة (i)
                  IconButton(
                    tooltip: 'تعليمات',
                    icon: Icon(
                      widget.item.showHelp
                          ? Icons.info_rounded
                          : Icons.info_outline_rounded,
                      color: navy,
                    ),
                    onPressed: () => setState(() => widget.item.showHelp = !widget.item.showHelp),
                  ),
                  IconButton(
                    tooltip: 'فتح',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.onOpen,
                  ),
                ],
              ),
            ),

            // الوصف يظهر/يختفي
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  widget.item.showHelp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: navy.withOpacity(.15)),
                ),
                child: Text(
                  widget.item.desc,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2A34),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
