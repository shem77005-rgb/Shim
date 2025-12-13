// import 'package:flutter/material.dart';

// import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
// import 'child_edit_screen.dart';

// class ChildModel {
//   String name;
//   String age;   // مثال: "7 سنوات"
//   String gender; // "ذكر" / "أنثى"
//   String email;
//   String password;

//   ChildModel({
//     required this.name,
//     required this.age,
//     required this.gender,
//     required this.email,
//     required this.password,
//   });

//   ChildModel copyWith({
//     String? name,
//     String? age,
//     String? gender,
//     String? email,
//     String? password,
//   }) {
//     return ChildModel(
//       name: name ?? this.name,
//       age: age ?? this.age,
//       gender: gender ?? this.gender,
//       email: email ?? this.email,
//       password: password ?? this.password,
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   static const Color bg = Color(0xFFF3F5F6);
//   static const Color navy = Color(0xFF0A2E66);
//   static const Color darkTxt = Color(0xFF28323B);

//   // القائمة تبدأ فارغة
//   final List<ChildModel> _children = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: Directionality(
//           textDirection: TextDirection.rtl,
//           child: Column(
//             children: [
//               const _TopBar(),
//               const SizedBox(height: 10),
//               const _SearchField(),

//               // بطاقات إحصائية مختصرة
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   children: const [
//                     Expanded(
//                       child: _InfoStatCard(
//                         title: 'تلقي إشعارات الطوارئ',
//                         subtitle: 'لا يوجد جديد',
//                         icon: Icons.priority_high_rounded,
//                         color: Color(0xFFE74C3C),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: _InfoStatCard(
//                         title: 'تنبيهات جديدة',
//                         subtitle: 'لا يوجد إشعارات',
//                         icon: Icons.verified_rounded,
//                         color: Color(0xFF27AE60),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                   children: [
//                     // عنوان القسم + زر إضافة طفل
//                     Row(
//                       children: [
//                         const Text('حسابات الأبناء',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w800, color: darkTxt)),
//                         const Spacer(),
//                       TextButton.icon(
//                         onPressed: _openAddChildSheet,
//                         icon: const Icon(Icons.add, size: 16),
//                         label: const Text('إضافة طفل'),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Color.fromRGBO(255, 255, 255, 1), backgroundColor: const Color(0xFF27AE60),
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         ),
//                       ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),

//                     // لو القائمة فارغة نعرض بطاقة فارغة
//                     if (_children.isEmpty)
//                       const _EmptyCard(
//                         title: 'لا توجد حسابات أبناء بعد',
//                         subtitle: 'اضغط على زر "إضافة طفل" لإضافة أول حساب',
//                       )
//                     else
//                       Material(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(14),
//                         child: ListView.separated(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: _children.length,
//                           separatorBuilder: (_, __) => const Divider(height: 1),
//                           itemBuilder: (_, i) {
//                             final c = _children[i];
//                             return ListTile(
//                               leading: const Icon(Icons.child_care_outlined),
//                               title: Text(c.name),
//                               subtitle: Text('${c.age} • ${c.gender}'),
//                               trailing: TextButton(
//                                 onPressed: () async {
//                                   final updated = await Navigator.push<ChildModel>(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => ChildEditScreen(child: c),
//                                     ),
//                                   );
//                                   if (updated != null) {
//                                     setState(() => _children[i] = updated);
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(content: Text('تم حفظ التعديلات')),
//                                     );
//                                   }
//                                 },
//                                 child: const Text('تعديل'),
//                               ),
//                             );
//                           },
//                         ),
//                       ),

//                     const SizedBox(height: 14),
//                     const _SectionTitle(text: 'إدارة المحتوى'),
//                     const _ContentModerationCard(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: const _BottomNavBar(),
//     );
//   }

//   // نموذج إضافة طفل (BottomSheet)
//   void _openAddChildSheet() {
//     final nameCtrl = TextEditingController();
//     final ageCtrl = TextEditingController();
//     final emailCtrl = TextEditingController();
//     String gender = 'ذكر';
//     final passCtrl = TextEditingController();
//     final formKey = GlobalKey<FormState>();
//     bool obscure = true;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         return Directionality(
//           textDirection: TextDirection.rtl,
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: 16, right: 16, top: 12,
//               bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//             ),
//             child: StatefulBuilder(
//               builder: (ctx, setSheetState) {
//                 return Form(
//                   key: formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 34, height: 4,
//                         margin: const EdgeInsets.only(bottom: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.black26, borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       const Text('إضافة طفل',
//                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
//                       const SizedBox(height: 12),

//                       _field(nameCtrl, 'اسم الطفل',
//                           validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null),
//                       _field(ageCtrl, 'العمر (مثال: 8 سنوات)',
//                           validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل العمر' : null),

//                       // اختيار الجنس
//                       Row(
//                         children: [
//                           const Text('الجنس:'),
//                           const SizedBox(width: 8),
//                           ChoiceChip(
//                             selected: gender == 'ذكر',
//                             label: const Text('ذكر'),
//                             onSelected: (_) => setSheetState(() => gender = 'ذكر'),
//                           ),
//                           const SizedBox(width: 8),
//                           ChoiceChip(
//                             selected: gender == 'أنثى',
//                             label: const Text('أنثى'),
//                             onSelected: (_) => setSheetState(() => gender = 'أنثى'),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),

//                       _field(emailCtrl, 'البريد الإلكتروني',
//                           keyboard: TextInputType.emailAddress,
//                           validator: (v) {
//                             if (v == null || v.trim().isEmpty) return 'أدخل البريد';
//                             final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
//                             return ok ? null : 'صيغة بريد غير صحيحة';
//                           }),

//                       // كلمة المرور
//                       TextFormField(
//                         controller: passCtrl,
//                         obscureText: obscure,
//                         decoration: InputDecoration(
//                           labelText: 'كلمة المرور',
//                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                           suffixIcon: IconButton(
//                             onPressed: () => setSheetState(() => obscure = !obscure),
//                             icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
//                           ),
//                         ),
//                         validator: (v) {
//                           if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
//                           final strong = v.length >= 8 &&
//                               RegExp(r'[A-Z]').hasMatch(v) &&
//                               RegExp(r'[a-z]').hasMatch(v) &&
//                               RegExp(r'[0-9]').hasMatch(v) &&
//                               RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v);
//                           return strong ? null : 'اجعلها قوية (8+ كبير/صغير/رقم/رمز)';
//                         },
//                       ),
//                       const SizedBox(height: 14),

//                       SizedBox(
//                         width: double.infinity,
//                         child: FilledButton(
//                           onPressed: () {
//                             if (!(formKey.currentState?.validate() ?? false)) return;
//                             setState(() {
//                               _children.add(ChildModel(
//                                 name: nameCtrl.text.trim(),
//                                 age: ageCtrl.text.trim(),
//                                 gender: gender,
//                                 email: emailCtrl.text.trim(),
//                                 password: passCtrl.text,
//                               ));
//                             });
//                             Navigator.pop(ctx);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text('تم إضافة الطفل')),
//                             );
//                           },
//                           style: FilledButton.styleFrom(
//                             backgroundColor: navy,
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                           child: const Text('حفظ'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _field(
//     TextEditingController c,
//     String label, {
//     String? Function(String?)? validator,
//     TextInputType? keyboard,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: TextFormField(
//         controller: c,
//         validator: validator,
//         keyboardType: keyboard,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//         ),
//       ),
//     );
//   }
// }

// class _ContentModerationCard extends StatelessWidget {
//   const _ContentModerationCard();

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
//         child: Row(
//           children: [
//             const Expanded(
//               child: Text(
//                 'إدارة المحتوى',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w800,
//                   fontSize: 16,
//                   color: Color(0xFF28323B),
//                 ),
//               ),
//             ),
//             FilledButton.icon(
//               style: FilledButton.styleFrom(
//                 backgroundColor: const Color(0xFF27AE60),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const PolicySettingsScreen()),
//                 );
//               },
//               icon: const Icon(Icons.settings_outlined, size: 18),
//               label: const Text(
//                 'فتح الإعدادات',
//                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ///==================== عناصر الواجهة الثابتة ====================

// class _TopBar extends StatelessWidget {
//   const _TopBar();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
//       decoration: const BoxDecoration(color: Colors.white, boxShadow: [
//         BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
//       ]),
//       child: Row(
//         children: [
//           const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
//           const Spacer(),
//           Row(
//             children: [
//               Image.asset('assets/images/logo.png',
//                   height: 22, errorBuilder: (_, __, ___) => const SizedBox()),
//               const SizedBox(width: 6),
//               const Text(
//                 'Safe Child System',
//                 style: TextStyle(fontWeight: FontWeight.w700, color: _HomeScreenState.navy),
//               ),
//             ],
//           ),
//           const Spacer(),
//           IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
//         ],
//       ),
//     );
//   }
// }

// class _SearchField extends StatelessWidget {
//   const _SearchField();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//       child: TextField(
//         decoration: InputDecoration(
//           hintText: 'ابحث',
//           prefixIcon: const Icon(Icons.search),
//           isDense: true,
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.black12),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.black12),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _InfoStatCard extends StatelessWidget {
//   const _InfoStatCard({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.color,
//   });
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundColor: color.withOpacity(.12),
//               child: Icon(icon, color: color),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontWeight: FontWeight.w700)),
//                   const SizedBox(height: 4),
//                   Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   const _SectionTitle({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, top: 12),
//       child: Text(text,
//           style: const TextStyle(fontWeight: FontWeight.w800, color: _HomeScreenState.darkTxt)),
//     );
//   }
// }

// class _EmptyCard extends StatelessWidget {
//   const _EmptyCard({required this.title, required this.subtitle});
//   final String title;
//   final String subtitle;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Icon(Icons.inbox_outlined, color: Colors.black26, size: 36),
//             const SizedBox(height: 8),
//             Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
//             const SizedBox(height: 4),
//             Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _BottomNavBar extends StatelessWidget {
//   const _BottomNavBar();

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: 0,
//       onTap: (_) {},
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
//         BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: 'إشعارات'),
//         BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'الملف'),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';
import 'child_edit_screen.dart';

import 'package:safechild_system/features/notifications/presentation/notifications_screen.dart';

// Import the new Child model and service
import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
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
    final authService = AuthService();
    _childService = ChildService(apiClient: authService.apiClient);
    _loadParentId().then((_) => _loadChildren());
  }

  Future<void> _loadParentId() async {
    // Get parent ID from authenticated user
    final authService = AuthService();
    final user = await authService.getCurrentUser();
    if (user != null) {
      print('🔵 [HomeScreen] Loaded parent ID from user: ${user.id}');
      setState(() {
        _parentId = user.id;
      });
    } else {
      // Fallback to stored parent_id or default
      final prefs = await SharedPreferences.getInstance();
      final storedParentId =
          prefs.getString('parent_id') ?? '1'; // Default to '1' for testing
      print('🔵 [HomeScreen] Using stored/default parent ID: $storedParentId');
      setState(() {
        _parentId = storedParentId;
      });
    }
    print('🔵 [HomeScreen] Final parent ID: $_parentId');
  }

  Future<void> _loadChildren() async {
    if (_parentId.isEmpty) return;
    print('🔵 [HomeScreen] Loading children for parent ID: $_parentId');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _childService.getParentChildren(
        parentId: _parentId,
      );
      if (response.isSuccess && response.data != null) {
        setState(() {
          _children.clear();
          _children.addAll(response.data!);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'فشل في تحميل قائمة الأطفال'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                          title: 'تلقي إشعارات الطوارئ',
                          subtitle: 'لا يوجد جديد',
                          icon: Icons.priority_high_rounded,
                          color: Color(0xFFE74C3C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // الآن: البطاقة الثانية - عند الضغط تفتح شاشة الإشعارات (NotificationsScreen)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: const _InfoStatCard(
                          title: 'تنبيهات جديدة',
                          subtitle: 'عرض التنبيهات recent',
                          icon: Icons.verified_rounded,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم حفظ التعديلات'),
                                      ),
                                    );
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
                              final response = await _childService.createChild(
                                parentId: _parentId,
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                                name: nameCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text.trim()) ?? 0,
                              );

                              if (response.isSuccess && response.data != null) {
                                setState(() {
                                  _children.add(response.data!);
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إضافة الطفل'),
                                  ),
                                );

                                // Refresh the list
                                _loadChildren();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.error ?? 'فشل في إضافة الطفل',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('حدث خطأ: ${e.toString()}'),
                                ),
                              );
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

/// صفحة مستقلة لعرض "تنبيهات جديدة" (مبدئية، غير مرتبطة بصفحة الطوارئ)
class NewAlertsScreen extends StatelessWidget {
  const NewAlertsScreen({super.key});

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
        ),
        body: const SafeArea(
          child: Center(
            child: Text(
              'هنا ستعرض "التنبيهات الجديدة".\nحالياً صفحة بسيطة مستقلة عن الطوارئ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
