import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
import 'child_edit_screen.dart';

import 'package:safechild_system/features/notifications/presentation/notifications_screen.dart';

// Import the new Child model and service
import '../../../models/child_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/child_service.dart';
import '../../../services/notification_service.dart';
import '../../../core/api/api_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/data/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);
  static const Color darkTxt = Color(0xFF28323B);

  // القائمة تبدأ فارغة
  final List<Child> _children = [];
  late ChildService _childService;
  String _parentId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔵 [HomeScreen] initState called');
    final authService = AuthService();
    _childService = ChildService(apiClient: authService.apiClient);
    print('🔵 [HomeScreen] About to call _initializeData');
    _initializeData();
    print('🔵 [HomeScreen] _initializeData called');
  }

  Future<void> _initializeData() async {
    print('🔵 [HomeScreen] Starting _initializeData');
    await _loadParentId();
    // Small delay to ensure state is updated
    await Future.delayed(Duration(milliseconds: 100));
    print(
      '🔵 [HomeScreen] _loadParentId completed with parent ID: $_parentId, calling _loadChildren',
    );
    await _loadChildren();
    print('🔵 [HomeScreen] _initializeData completed');
  }

  Future<void> _loadParentId() async {
    print('🔵 [HomeScreen] _loadParentId called');
    // Get parent ID from authenticated user
    final authService = AuthService();
    final user = await authService.getCurrentUser();
    print('🔵 [HomeScreen] getCurrentUser returned: $user');
    if (user != null) {
      print(
        '🔵 [HomeScreen] Loaded user data - ID: ${user.id}, Type: ${user.userType}',
      );
      print(
        '🔵 [HomeScreen] User details - Email: ${user.email}, Name: ${user.name}',
      );

      // Make sure this is a parent user
      if (user.userType != 'parent') {
        print(
          '⚠️ [HomeScreen] Warning: Current user is not a parent: ${user.userType}',
        );
        // Don't set parent ID for non-parent users
        print('🔵 [HomeScreen] Setting _parentId to empty string');
        setState(() {
          _parentId = '';
        });
        print(
          '🔵 [HomeScreen] Set parent ID to empty string for non-parent user, value is now: $_parentId',
        );
        return;
      }

      // For parent users, use their own ID as the parent ID
      print('🔵 [HomeScreen] About to set parent ID to user ID: ${user.id}');
      setState(() {
        _parentId = user.id;
      });
      print('🔵 [HomeScreen] Set parent ID to user ID: $_parentId');
      print('🔵 [HomeScreen] Parent ID after setState: $_parentId');
    } else {
      // If we can't get the current user, try to get parent ID from SharedPreferences as fallback
      print(
        '❌ [HomeScreen] Could not load user data. Trying SharedPreferences fallback...',
      );
      final prefs = await SharedPreferences.getInstance();
      final storedParentId = prefs.getString('parent_id') ?? '';
      print(
        '🔵 [HomeScreen] Stored parent ID from SharedPreferences: $storedParentId',
      );

      if (storedParentId.isNotEmpty) {
        print(
          '🔵 [HomeScreen] Loaded parent ID from SharedPreferences: $storedParentId',
        );
        setState(() {
          _parentId = storedParentId;
        });
        print(
          '🔵 [HomeScreen] Parent ID after setState (fallback): $_parentId',
        );
      } else {
        print(
          '❌ [HomeScreen] Could not load parent ID from SharedPreferences.',
        );
        // Don't set a default parent ID as this causes data integrity issues
        print('🔵 [HomeScreen] Setting _parentId to empty string (fallback)');
        setState(() {
          _parentId = '';
        });
        print(
          '🔵 [HomeScreen] _parentId set to empty string (fallback), value is now: $_parentId',
        );

        // Show error to user
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
      }
    }
    print('🔵 [HomeScreen] Final parent ID: $_parentId');
  }

  Future<void> _loadChildren() async {
    print('🔵 [HomeScreen] _loadChildren called with parent ID: $_parentId');
    if (_parentId.isEmpty) {
      print('⚠️ [HomeScreen] Cannot load children: Parent ID is empty');
      return;
    }
    print('🔵 [HomeScreen] Loading children for parent ID: $_parentId');

    setState(() {
      _isLoading = true;
    });
    print('🔵 [HomeScreen] _isLoading set to true');

    try {
      print(
        '🔵 [HomeScreen] Calling getParentChildren with parent ID: $_parentId',
      );
      final response = await _childService.getParentChildren(
        parentId: _parentId,
      );
      if (response.isSuccess && response.data != null) {
        print('🔵 [HomeScreen] Received ${response.data!.length} children');

        // Debug: Print raw response data
        print('🔵 [HomeScreen] Raw response data: ${response.data}');

        // Client-side filtering to ensure only children with matching parent ID are shown
        // This is a safety measure in case the backend doesn't filter properly
        final filteredChildren =
            response.data!.where((child) {
              final matches = child.parentId == _parentId;
              if (!matches) {
                print(
                  '⚠️ [HomeScreen] Filtering out child: ${child.name} (Parent ID: ${child.parentId} != $_parentId)',
                );
              }
              return matches;
            }).toList();

        print(
          '🔵 [HomeScreen] After filtering: ${filteredChildren.length} children match parent ID: $_parentId',
        );

        print(
          '🔵 [HomeScreen] Setting children list with ${filteredChildren.length} items',
        );
        setState(() {
          _children.clear();
          _children.addAll(filteredChildren);
        });
        print(
          '🔵 [HomeScreen] Children list updated, now has ${_children.length} items',
        );

        // Debug: Print each child to verify they belong to this parent
        print('🔵 [HomeScreen] Checking children for parent ID: $_parentId');
        for (var child in _children) {
          print(
            '🔵 [HomeScreen] Child in list - ID: ${child.id}, Name: ${child.name}, Parent ID: ${child.parentId}, Matches: ${child.parentId == _parentId}',
          );
        }
      } else {
        // Check if context is still mounted before showing snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل في تحميل قائمة الأطفال'),
            ),
          );
        }
      }
    } catch (e) {
      // Check if context is still mounted before showing snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    } finally {
      print('🔵 [HomeScreen] Setting _isLoading to false');
      setState(() {
        _isLoading = false;
      });
      print('🔵 [HomeScreen] _isLoading set to false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const _TopBar(),
              const SizedBox(height: 10),
              const _SearchField(),

              // بطاقات إحصائية مختصرة
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // الآن: البطاقة - عند الضغط تفتح صفحة "تنبيهات جديدة" مستقلة (NewAlertsScreen)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewAlertsScreen(),
                            ),
                          );
                        },
                        child: const _InfoStatCard(
                          title: 'تنبيهات جديدة',
                          subtitle: 'عرض إشعارات ',
                          icon: Icons.notifications_active_rounded,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // عنوان القسم + زر إضافة طفل
                    Row(
                      children: [
                        const Text(
                          'حسابات الأبناء',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: darkTxt,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _openAddChildSheet,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة طفل'),
                          style: TextButton.styleFrom(
                            foregroundColor: Color.fromRGBO(255, 255, 255, 1),
                            backgroundColor: const Color(0xFF27AE60),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Show loading indicator
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    // لو القائمة فارغة نعرض بطاقة فارغة
                    else if (_children.isEmpty)
                      const _EmptyCard(
                        title: 'لا توجد حسابات أبناء بعد',
                        subtitle: 'اضغط على زر "إضافة طفل" لإضافة أول حساب',
                      )
                    else
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _children.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = _children[i];
                            return ListTile(
                              leading: const Icon(Icons.child_care_outlined),
                              title: Text(c.name),
                              subtitle: Text('${c.age} years old'),
                              trailing: TextButton(
                                onPressed: () async {
                                  final updated = await Navigator.push<Child>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChildEditScreen(child: c),
                                    ),
                                  );
                                  if (updated != null) {
                                    setState(() => _children[i] = updated);
                                    // Check if context is still mounted before showing snackbar
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم حفظ التعديلات'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('تعديل'),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),
                    const _SectionTitle(text: 'إدارة المحتوى'),
                    const _ContentModerationCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  // نموذج إضافة طفل (BottomSheet)
  void _openAddChildSheet() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool _obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const Text(
                        'إضافة طفل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _field(
                        nameCtrl,
                        'اسم الطفل',
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'أدخل الاسم'
                                    : null,
                      ),
                      _field(
                        ageCtrl,
                        'العمر',
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'أدخل العمر';
                          }
                          final age = int.tryParse(v.trim());
                          if (age == null || age <= 0) {
                            return 'أدخل عمر صحيح';
                          }
                          return null;
                        },
                      ),

                      _field(
                        emailCtrl,
                        'البريد الإلكتروني',
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'أدخل البريد';
                          final ok = RegExp(
                            r'^[^@]+@[^@]+\.[^@]+$',
                          ).hasMatch(v.trim());
                          return ok ? null : 'صيغة بريد غير صحيحة';
                        },
                      ),

                      // Password field
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'أدخل كلمة المرور';
                            }
                            if (v.length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false))
                              return;

                            try {
                              print(
                                '🔵 [HomeScreen] Creating child with parent ID: $_parentId',
                              );

                              // Log form data
                              print('🔵 [HomeScreen] Child form data:');
                              print('   Email: ${emailCtrl.text.trim()}');
                              print('   Name: ${nameCtrl.text.trim()}');
                              print('   Age: ${ageCtrl.text.trim()}');

                              // Validate parent ID before creating child
                              if (_parentId.isEmpty) {
                                print('❌ [HomeScreen] Parent ID is empty');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'خطأ: معرف الوالد غير متوفر. الرجاء تسجيل الدخول مرة أخرى. [Parent ID: $_parentId]',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              print(
                                '🔵 [HomeScreen] Valid parent ID: $_parentId',
                              );

                              // Double-check that parent ID is valid (not the default '1')
                              if (_parentId == '1') {
                                print(
                                  '⚠️ [HomeScreen] Warning: Attempting to use default parent ID',
                                );
                                // This might indicate an authentication issue
                              }

                              final response = await _childService.createChild(
                                parentId: _parentId,
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                                name: nameCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text.trim()) ?? 0,
                              );

                              if (response.isSuccess && response.data != null) {
                                print(
                                  '✅ [HomeScreen] Child created successfully with ID: ${response.data!.id}',
                                );
                                setState(() {
                                  _children.add(response.data!);
                                });
                                Navigator.pop(ctx);

                                // Check if context is still mounted before showing snackbar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إضافة الطفل'),
                                    ),
                                  );

                                  // Refresh the list
                                  _loadChildren();
                                }
                              } else {
                                print(
                                  '❌ [HomeScreen] Failed to create child: ${response.error}',
                                );
                                // Check if context is still mounted before showing snackbar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response.error ?? 'فشل في إضافة الطفل',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              // Check if context is still mounted before showing snackbar
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ: ${e.toString()}'),
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: navy,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('حفظ'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _ContentModerationCard extends StatelessWidget {
  const _ContentModerationCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'إدارة المحتوى',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF28323B),
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PolicySettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text(
                'فتح الإعدادات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///==================== عناصر الواجهة الثابتة ====================

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
          const Spacer(),
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 22,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              const SizedBox(width: 6),
              const Text(
                'Safe Child System',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _HomeScreenState.navy,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
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

class _InfoStatCard extends StatelessWidget {
  const _InfoStatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _HomeScreenState.darkTxt,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: Colors.black26, size: 36),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none_rounded),
          label: 'إشعارات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: 'الملف',
        ),
      ],
    );
  }
}

/// صفحة مستقلة لعرض "تنبيهات جديدة" - تعرض الإشعارات من API
class NewAlertsScreen extends StatefulWidget {
  const NewAlertsScreen({super.key});

  @override
  State<NewAlertsScreen> createState() => _NewAlertsScreenState();
}

class _NewAlertsScreenState extends State<NewAlertsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _error = '';
  String _parentId = '';
  late NotificationService _notificationService;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      apiClient: _authService.apiClient,
    );
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _loadParentId();
    await _loadNotifications();
  }

  Future<void> _loadParentId() async {
    final user = await _authService.getCurrentUser();
    if (user != null && user.userType == 'parent') {
      setState(() {
        _parentId = user.id;
      });
      print('🔵 [NewAlertsScreen] Parent ID loaded: $_parentId');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Get notifications filtered by parent ID
      final response = await _notificationService.getNotifications(
        parentId: _parentId,
      );
      if (response.isSuccess && response.data != null) {
        setState(() {
          _notifications = response.data!;
          _isLoading = false;
        });
        print(
          '✅ [NewAlertsScreen] Loaded ${_notifications.length} notifications',
        );
      } else {
        setState(() {
          _error = response.error ?? 'فشل في تحميل الإشعارات';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd - HH:mm').format(timestamp);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'emergency':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.info_outline;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنبيهات جديدة'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.6,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotifications,
            ),
          ],
        ),
        body: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                  : _notifications.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد تنبيهات جديدة',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final categoryColor = _getCategoryColor(
                          notification.category,
                        );
                        final categoryIcon = _getCategoryIcon(
                          notification.category,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: categoryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    categoryIcon,
                                    color: categoryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (notification
                                          .description
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          notification.description,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTimestamp(
                                          notification.timestamp,
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }
}
