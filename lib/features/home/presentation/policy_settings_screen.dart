import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:safechild_system/features/apps/presentation/apps_screen.dart';
import 'package:safechild_system/features/children/presentation/child_geographical_restrictions_screen.dart';
import 'package:safechild_system/features/home/presentation/writing_restrictions_screen.dart';
import 'package:safechild_system/features/report/presentation/report_screen.dart';

import 'emergency_setting_screen.dart';
import 'block_sites_screen.dart';
import 'geographical_zones_screen.dart';

// ✅ شاشة الأب الجديدة (block-app)
import 'parent_apps_policy_screen.dart';

// (main) widgets - kept for compatibility (even if not used directly here)
import 'package:safechild_system/widgets/access_buttons.dart';

// Services / Models
import '../../../services/child_service.dart';
import '../../../models/child_model.dart';
import '../../../features/auth/data/services/auth_service.dart';

class PolicySettingsScreen extends StatefulWidget {
  const PolicySettingsScreen({super.key});

  @override
  State<PolicySettingsScreen> createState() => _PolicySettingsScreenState();
}

class _PolicySettingsScreenState extends State<PolicySettingsScreen> {
  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);
  static const Color info = Color(0xFFE8F3FF);

  // ✅ block-app: children selector state
  List<Child> _children = [];
  bool _isLoadingChildren = true;
  String _parentId = '';
  int _selectedChild = 0;

  late AuthService _authService;
  late ChildService _childService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _childService = ChildService(apiClient: _authService.apiClient);

    // ✅ block-app: load parent + children (only if parent)
    _loadParentAndChildren();
  }

  Future<void> _loadParentAndChildren() async {
    try {
      debugPrint('🟦 [PolicySettings] Loading parent ID and children');
      final user = await _authService.getCurrentUser();

      if (user != null && user.userType == 'parent') {
        setState(() => _parentId = user.id);
        debugPrint('🟦 [PolicySettings] Parent ID: $_parentId');
        await _loadChildren();
      } else {
        debugPrint('⚠️ [PolicySettings] Current user is not a parent');
        setState(() => _isLoadingChildren = false);
      }
    } catch (e) {
      debugPrint('❌ [PolicySettings] Error loading parent/children: $e');
      setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _loadChildren() async {
    if (_parentId.isEmpty) {
      debugPrint('⚠️ [PolicySettings] Cannot load children: Parent ID is empty');
      setState(() => _isLoadingChildren = false);
      return;
    }

    try {
      debugPrint('🟦 [PolicySettings] Fetching children for parent: $_parentId');
      final response = await _childService.getParentChildren(parentId: _parentId);

      if (response.isSuccess && response.data != null) {
        final filteredChildren =
            response.data!.where((child) => child.parentId == _parentId).toList();

        setState(() {
          _children = filteredChildren;
          _isLoadingChildren = false;
          _selectedChild = 0;
        });

        debugPrint('✅ [PolicySettings] Loaded ${_children.length} children');
        for (final c in _children) {
          debugPrint('🟦 [PolicySettings] Child: ${c.name} id=${c.id} parent=${c.parentId}');
        }
      } else {
        debugPrint('❌ [PolicySettings] Failed to load children: ${response.error}');
        setState(() => _isLoadingChildren = false);
      }
    } catch (e) {
      debugPrint('❌ [PolicySettings] Error loading children: $e');
      setState(() => _isLoadingChildren = false);
    }
  }

  // ✅ merged items: keep both branch features, plus add missing ones as items
  final List<_Restriction> _items = [
    _Restriction(
      title: 'مدة استخدام التطبيقات',
      asset: 'assets/images/usage (1).png',
      desc: 'تحدد المدة اليومية المسموح بها للتطبيقات. يمكن تخصيصها لكل تطبيق.',
    ),
    _Restriction(
      title: 'القيود الجغرافية',
      asset: 'assets/images/geo.png',
      desc: 'إضافة وتعديل المناطق الجغرافية المسموح بها لطفلك.',
    ),
    _Restriction(
      title: 'قيود الكتابة',
      asset: 'assets/images/keyboard.png',
      desc: 'منع أو مراجعة نصوص حساسة باستخدام الذكاء الاصطناعي على مستوى النظام.',
    ),
    _Restriction(
      title: 'التقارير',
      asset: 'assets/images/infographic.png',
      desc: 'تقارير أسبوعية لنشاط الطفل والتنبيهات مع ملخص للأوقات والمحتوى.',
    ),

    // ✅ block-app features preserved as items
    _Restriction(
      title: 'الطوارئ',
      asset: 'assets/images/emergency.png',
      desc: 'إعدادات زر الطوارئ وإشعارات الاستغاثة للوالد.',
    ),
    _Restriction(
      title: 'حظر المواقع',
      asset: 'assets/images/block.png',
      desc: 'إدارة المواقع المحظورة وحماية التصفح.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasChild = !_isLoadingChildren && _children.isNotEmpty;
    final selectedChild = hasChild ? _children[_selectedChild] : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
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
            // ✅ block-app: child selector UI (only meaningful for parent)
            const Text(
              'اختر طفلاً',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            if (_isLoadingChildren)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_children.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لا توجد حسابات أطفال مضافة. أضف طفلًا أولاً من الصفحة الرئيسية.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_children.length, (i) {
                    final selected = _selectedChild == i;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(
                          _children[i].name,
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

            ..._items.map((item) {
              return _RestrictionTile(
                item: item,
                onOpen: () {
                  // ✅ block-app screens
                  if (item.title == 'الطوارئ') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencySettingScreen()),
                    );
                    return;
                  }

                  if (item.title == 'حظر المواقع') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BlockSitesScreen()),
                    );
                    return;
                  }

                  // ✅ apps usage: preserve BOTH behaviors
                  // 1) ParentAppsPolicyScreen (needs selected child)
                  // 2) AppsScreen (general screen from main)
                  if (item.title == 'مدة استخدام التطبيقات') {
                    // If we have a selected child -> open parent policy screen (block-app feature)
                    if (selectedChild != null) {
                      final childIdInt = int.tryParse(selectedChild.id) ?? 0;
                      if (childIdInt > 0) {
                        debugPrint('🟪 [PolicySettings] Open ParentAppsPolicyScreen childId=$childIdInt');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ParentAppsPolicyScreen(
                              childId: childIdInt,
                              childName: selectedChild.name,
                              apiClient: _authService.apiClient, // ✅ مهم
                            ),
                          ),
                        );
                        return;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('child_id غير صالح')),
                        );
                        // fall-through to AppsScreen as backup (keep main feature)
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('اختر طفل أولاً')),
                      );
                      // fall-through to AppsScreen as backup
                    }

                    // Backup/general screen (main feature)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppsScreen()),
                    );
                    return;
                  }

                  if (item.title == 'قيود الكتابة') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WritingRestrictionsScreen()),
                    );
                    return;
                  }

                  if (item.title.trim() == 'القيود الجغرافية') {
                    // Keep main feature: zones screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GeographicalZonesScreen()),
                    );
                    return;

                    // Also preserve child specific screen (imported) for future use:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildGeographicalRestrictionsScreen()));
                  }

                  if (item.title == 'التقارير') {
                    // ✅ safest compile: open the main report screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    );

                    // If you have ReportData + placeholderData in your project,
                    // you can switch to the old behavior:
                    // placeholderData.summary = generateSummary(placeholderData);
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(data: placeholderData)));
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فتح إعداد: ${item.title}')),
                  );
                },
              );
            }),
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
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                ),
              ),
              title: Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF28323B),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'تعليمات',
                    icon: Icon(
                      widget.item.showHelp ? Icons.info_rounded : Icons.info_outline_rounded,
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
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: widget.item.showHelp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
