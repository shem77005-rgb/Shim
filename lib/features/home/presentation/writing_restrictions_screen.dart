// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../models/child_model.dart';
// import '../../../services/child_service.dart';
// import '../../../services/writing_check_service.dart';
// import '../../../services/text_monitor_service.dart';
// import '../../../features/auth/data/services/auth_service.dart';
// import './child_word_restrictions_screen.dart';

// class WritingRestrictionsScreen extends StatefulWidget {
//   const WritingRestrictionsScreen({super.key});

//   @override
//   State<WritingRestrictionsScreen> createState() =>
//       _WritingRestrictionsScreenState();
// }

// class _WritingRestrictionsScreenState extends State<WritingRestrictionsScreen> {
//   bool _enabled = false;
//   bool _isLoading = true;
//   bool _isAccessibilityEnabled = false;
//   String? _selectedChildId;
//   String? _selectedChildName;
//   List<Child> _children = [];

//   late WritingCheckService _writingCheckService;
//   late ChildService _childService;
//   final AuthService _authService = AuthService();
//   final TextMonitorService _textMonitorService = TextMonitorService();

//   static const Color bg = Color(0xFFF3F5F6);
//   static const Color navy = Color(0xFF0A2E66);

//   @override
//   void initState() {
//     super.initState();
//     _writingCheckService = WritingCheckService(
//       apiClient: _authService.apiClient,
//     );
//     _childService = ChildService(apiClient: _authService.apiClient);
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     await _checkAccessibilityStatus();
//     await _loadChildren();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _checkAccessibilityStatus() async {
//     final isEnabled = await _textMonitorService.isTextMonitorEnabled();
//     setState(() => _isAccessibilityEnabled = isEnabled);
//   }

//   Future<void> _loadChildren() async {
//     setState(() => _isLoading = true);
//     try {
//       final user = await _authService.getCurrentUser();
//       if (user != null) {
//         final response = await _childService.getParentChildren(
//           parentId: user.id,
//         );
//         if (response.isSuccess && response.data != null) {
//           setState(() {
//             _children = response.data!;
//             if (_children.isNotEmpty) {
//               _selectedChildId = _children.first.id.toString();
//               _selectedChildName = _children.first.name;
//               _loadSettingsForChild(_selectedChildId!);
//             }
//           });
//         }
//       }
//     } catch (e) {
//       print('Error loading children: $e');
//     }
//     setState(() => _isLoading = false);
//   }

//   Future<void> _loadSettingsForChild(String childId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final key = 'writing_restrictions_$childId';
//     final isEnabled = prefs.getBool(key) ?? false;
//     setState(() => _enabled = isEnabled);
//     await _textMonitorService.setWritingRestrictionsEnabled(isEnabled);
//   }

//   Future<void> _saveSettingsForChild(String childId, bool enabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('writing_restrictions_$childId', enabled);
//     await _textMonitorService.setWritingRestrictionsEnabled(enabled);

//     if (enabled && _selectedChildName != null) {
//       final user = await _authService.getCurrentUser();
//       final token = await _authService.getToken();
//       final refreshToken = await _authService.getRefreshToken();

//       // Determine the correct parent ID
//       String parentId = user?.id ?? '';
//       if (user?.userType == 'child') {
//         // If current user is a child, find the parent ID from the children list
//         // Look for the child in the loaded children list to get their parent ID
//         final child = _children.firstWhere(
//           (c) => c.id.toString() == childId,
//           orElse:
//               () => _children.firstWhere(
//                 (c) => c.name == _selectedChildName!,
//                 orElse:
//                     () => Child(
//                       id: '',
//                       parentId: user?.id ?? '',
//                       email: '',
//                       name: '',
//                       age: 0,
//                     ),
//               ),
//         );
//         parentId = child.parentId;
//       }

//       await _textMonitorService.saveChildInfo(
//         parentId: parentId,
//         childName: _selectedChildName!,
//         childId: childId,
//         token: token ?? '',
//         refreshToken: refreshToken,
//       );
//     }
//   }

//   Future<void> _openAccessibilitySettings() async {
//     await _textMonitorService.openAccessibilitySettings();
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: const Text('تفعيل خدمة مراقبة النصوص'),
//               content: const Text(
//                 'لتفعيل خدمة مراقبة النصوص:\n\n'
//                 '1. ابحث عن "SafeChild Text Monitor"\n'
//                 '2. اضغط عليها وفعّل الخدمة\n'
//                 '3. ارجع إلى التطبيق',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     _checkAccessibilityStatus();
//                   },
//                   child: const Text('تم'),
//                 ),
//               ],
//             ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: bg,
//         body: SafeArea(
//           child: Column(
//             children: [
//               _buildTopBar(),
//               const SizedBox(height: 8),
//               _buildHeader(),
//               const SizedBox(height: 14),
//               if (_isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else if (_children.isEmpty)
//                 const Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Text(
//                     'لا يوجد أطفال مسجلين',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 )
//               else
//                 Expanded(child: _buildMainContent()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTopBar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 16,
//             backgroundColor: Colors.blue.shade50,
//             child: const Icon(Icons.person, size: 18),
//           ),
//           const Spacer(),
//           const Text(
//             'Safe Child System',
//             style: TextStyle(fontWeight: FontWeight.w700, color: navy),
//           ),
//           const Spacer(),
//           IconButton(
//             onPressed: _checkAccessibilityStatus,
//             icon: const Icon(Icons.refresh, color: Colors.black54),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           const Text(
//             'قيود الكتابة',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w900,
//               color: Color(0xFF28323B),
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.chevron_right),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Accessibility Status Card
//           _buildAccessibilityCard(),
//           const SizedBox(height: 12),
//           // Child Selection
//           _buildChildSelectionCard(),
//           const SizedBox(height: 12),
//           // Enable/Disable Switch
//           _buildEnableCard(),
//           const SizedBox(height: 6),
//           const Text(
//             'ملاحظة: يتم مراقبة النصوص في جميع التطبيقات عند تفعيل الخدمة.',
//             style: TextStyle(color: Colors.black45, fontSize: 12.5),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildAccessibilityCard() {
//     return Card(
//       color:
//           _isAccessibilityEnabled
//               ? Colors.green.shade50
//               : Colors.orange.shade50,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(
//               _isAccessibilityEnabled
//                   ? Icons.check_circle
//                   : Icons.warning_amber_rounded,
//               color: _isAccessibilityEnabled ? Colors.green : Colors.orange,
//               size: 32,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _isAccessibilityEnabled
//                         ? 'خدمة المراقبة مفعّلة'
//                         : 'خدمة المراقبة غير مفعّلة',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color:
//                           _isAccessibilityEnabled
//                               ? Colors.green.shade700
//                               : Colors.orange.shade700,
//                     ),
//                   ),
//                   Text(
//                     _isAccessibilityEnabled
//                         ? 'يتم مراقبة النصوص في جميع التطبيقات'
//                         : 'يجب تفعيل الخدمة في إعدادات إمكانية الوصول',
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
//                   ),
//                 ],
//               ),
//             ),
//             if (!_isAccessibilityEnabled)
//               ElevatedButton(
//                 onPressed: _openAccessibilitySettings,
//                 style: ElevatedButton.styleFrom(backgroundColor: navy),
//                 child: const Text(
//                   'تفعيل',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildChildSelectionCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'اختر الطفل',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<String>(
//               value: _selectedChildId,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//               ),
//               items:
//                   _children.map<DropdownMenuItem<String>>((child) {
//                     return DropdownMenuItem<String>(
//                       value: child.id.toString(),
//                       child: Text(child.name),
//                     );
//                   }).toList(),
//               onChanged: (value) {
//                 if (value != null) {
//                   final child = _children.firstWhere(
//                     (c) => c.id.toString() == value,
//                   );
//                   setState(() {
//                     _selectedChildId = value;
//                     _selectedChildName = child.name;
//                   });
//                   _loadSettingsForChild(value);
//                 }
//               },
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton(
//                 onPressed:
//                     _selectedChildId != null
//                         ? () {
//                           final selectedChild = _children.firstWhere(
//                             (child) => child.id.toString() == _selectedChildId,
//                           );
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) => ChildWordRestrictionsScreen(
//                                     child: selectedChild,
//                                   ),
//                             ),
//                           );
//                         }
//                         : null,
//                 child: const Text('إدارة الكلمات المحظورة للطفل'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEnableCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Row(
//           children: [
//             Switch(
//               value: _enabled,
//               onChanged:
//                   _isAccessibilityEnabled
//                       ? (v) {
//                         setState(() => _enabled = v);
//                         if (_selectedChildId != null)
//                           _saveSettingsForChild(_selectedChildId!, v);
//                       }
//                       : null,
//               activeColor: Colors.white,
//               activeTrackColor: navy,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const Text(
//                     'تفعيل مراقبة الكتابة',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'تحليل النصوص بالذكاء الاصطناعي في جميع التطبيقات',
//                     style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _enabled ? 'الحماية مفعلّة' : 'الحماية معطّلة',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: _enabled ? navy : Colors.black45,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
import '../../../services/writing_check_service.dart';
import '../../../services/text_monitor_service.dart';
import '../../../features/auth/data/services/auth_service.dart';
import './child_word_restrictions_screen.dart';

class WritingRestrictionsScreen extends StatefulWidget {
  const WritingRestrictionsScreen({super.key});

  @override
  State<WritingRestrictionsScreen> createState() =>
      _WritingRestrictionsScreenState();
}

class _WritingRestrictionsScreenState extends State<WritingRestrictionsScreen> {
  bool _enabled = false;
  bool _isLoading = true;
  bool _isAccessibilityEnabled = false;
  String? _selectedChildId;
  String? _selectedChildName;
  List<Child> _children = [];

  late WritingCheckService _writingCheckService;
  late ChildService _childService;
  final AuthService _authService = AuthService();
  final TextMonitorService _textMonitorService = TextMonitorService();

  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);

  @override
  void initState() {
    super.initState();
    _writingCheckService = WritingCheckService(
      apiClient: _authService.apiClient,
    );
    _childService = ChildService(apiClient: _authService.apiClient);
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAccessibilityStatus();
    await _loadChildren();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkAccessibilityStatus() async {
    final isEnabled = await _textMonitorService.isTextMonitorEnabled();
    setState(() => _isAccessibilityEnabled = isEnabled);
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // جلب الأطفال حسب معرف الأب
        final response = await _childService.getParentChildren(
          parentId: user.id,
        );
        if (response.isSuccess && response.data != null) {
          setState(() {
            _children = response.data!;
            // فلترة الأطفال فقط الذين لديهم نفس parentId
            _children = _children.where((child) => child.parentId == user.id).toList();
            if (_children.isNotEmpty) {
              _selectedChildId = _children.first.id.toString();
              _selectedChildName = _children.first.name;
              _loadSettingsForChild(_selectedChildId!);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading children: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSettingsForChild(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'writing_restrictions_$childId';
    final isEnabled = prefs.getBool(key) ?? false;
    setState(() => _enabled = isEnabled);
    await _textMonitorService.setWritingRestrictionsEnabled(isEnabled);
  }

  Future<void> _saveSettingsForChild(String childId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writing_restrictions_$childId', enabled);
    await _textMonitorService.setWritingRestrictionsEnabled(enabled);

    if (enabled && _selectedChildName != null) {
      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();
      final refreshToken = await _authService.getRefreshToken();

      String parentId = user?.id ?? '';

      await _textMonitorService.saveChildInfo(
        parentId: parentId,
        childName: _selectedChildName!,
        childId: childId,
        token: token ?? '',
        refreshToken: refreshToken,
      );
    }
  }

  Future<void> _openAccessibilitySettings() async {
    await _textMonitorService.openAccessibilitySettings();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تفعيل خدمة مراقبة النصوص'),
          content: const Text(
            'لتفعيل خدمة مراقبة النصوص:\n\n'
            '1. ابحث عن "SafeChild Text Monitor"\n'
            '2. اضغط عليها وفعّل الخدمة\n'
            '3. ارجع إلى التطبيق',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _checkAccessibilityStatus();
              },
              child: const Text('تم'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 14),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لا يوجد أطفال مسجلين',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.person, size: 18),
          ),
          const Spacer(),
          const Text(
            'Safe Child System',
            style: TextStyle(fontWeight: FontWeight.w700, color: navy),
          ),
          const Spacer(),
          IconButton(
            onPressed: _checkAccessibilityStatus,
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAccessibilityCard(),
          const SizedBox(height: 12),
          _buildChildSelectionCard(),
          const SizedBox(height: 12),
          _buildEnableCard(),
          const SizedBox(height: 6),
          const Text(
            'ملاحظة: يتم مراقبة النصوص في جميع التطبيقات عند تفعيل الخدمة.',
            style: TextStyle(color: Colors.black45, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAccessibilityCard() {
    return Card(
      color: _isAccessibilityEnabled ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isAccessibilityEnabled
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: _isAccessibilityEnabled ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAccessibilityEnabled
                        ? 'خدمة المراقبة مفعّلة'
                        : 'خدمة المراقبة غير مفعّلة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isAccessibilityEnabled
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  Text(
                    _isAccessibilityEnabled
                        ? 'يتم مراقبة النصوص في جميع التطبيقات'
                        : 'يجب تفعيل الخدمة في إعدادات إمكانية الوصول',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            if (!_isAccessibilityEnabled)
              ElevatedButton(
                onPressed: _openAccessibilitySettings,
                style: ElevatedButton.styleFrom(backgroundColor: navy),
                child: const Text(
                  'تفعيل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // تعديل: عرض الأطفال حسب parentId فقط
  Widget _buildChildSelectionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الطفل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedChildId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _children.map<DropdownMenuItem<String>>((child) {
                return DropdownMenuItem<String>(
                  value: child.id.toString(),
                  child: Text(child.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final child = _children.firstWhere((c) => c.id.toString() == value);
                  setState(() {
                    _selectedChildId = value;
                    _selectedChildName = child.name;
                  });
                  _loadSettingsForChild(value);
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _selectedChildId != null
                    ? () {
                        final selectedChild = _children.firstWhere(
                            (child) => child.id.toString() == _selectedChildId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChildWordRestrictionsScreen(child: selectedChild),
                          ),
                        );
                      }
                    : null,
                child: const Text('إدارة الكلمات المحظورة للطفل'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Switch(
              value: _enabled,
              onChanged: _isAccessibilityEnabled
                  ? (v) {
                      setState(() => _enabled = v);
                      if (_selectedChildId != null) _saveSettingsForChild(_selectedChildId!, v);
                    }
                  : null,
              activeColor: Colors.white,
              activeTrackColor: navy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'تفعيل مراقبة الكتابة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تحليل النصوص بالذكاء الاصطناعي في جميع التطبيقات',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _enabled ? 'الحماية مفعلّة' : 'الحماية معطّلة',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _enabled ? navy : Colors.black45,
                    ),
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

