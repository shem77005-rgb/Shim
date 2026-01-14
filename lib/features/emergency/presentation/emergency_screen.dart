import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
import '../../../services/emergency_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/policy_service.dart';
import '../../../services/text_monitor_service.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/data/services/auth_service.dart';
import '../../children/presentation/child_login_screen.dart';
import '../../../native_bridge.dart'; // ✅ مهم

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

  // ✅ Key for one-time setup
  static const String _setupDoneKey = 'child_setup_done_v1';

  late final AnimationController _pulse;
  late final Animation<double> _scale;

  late final EmergencyService _emergencyService;
  late final NotificationService _notificationService;
  late final ChildService _childService;

  // Use the singleton instance of AuthService
  final AuthService _authService = AuthService();

  bool _writingMonitoringEnabled = false;
  String? _selectedChildId;
  String? _selectedChildName;
  List<Child> _children = [];
  bool _isLoadingChildren = false;

  @override
  void initState() {
    super.initState();

    _emergencyService = EmergencyService(apiClient: _authService.apiClient);
    _notificationService = NotificationService(apiClient: _authService.apiClient);
    _childService = ChildService(apiClient: _authService.apiClient);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ block-app: setup dialog once للطفل فقط
      _maybeShowSetupDialogOnce();

      // ✅ main: Load children and writing monitoring status
      _initializeChildData();

      // ✅ main: Always save child info to Android service if child is passed
      if (widget.child != null) {
        _checkAndSaveChildInfoIfEnabled(widget.child!);
      }
    });
  }

  // ================================================================
  // ✅ main branch: TextMonitor saving
  // ================================================================

  Future<void> _checkAndSaveChildInfoIfEnabled(Child child) async {
    final token = await _authService.getToken();
    final refreshToken = await _authService.getRefreshToken();

    final textMonitorService = TextMonitorService();
    await textMonitorService.saveChildInfo(
      parentId: child.parentId,
      childName: child.name,
      childId: child.id.toString(),
      token: token ?? '',
      refreshToken: refreshToken,
    );
  }

  Future<void> _initializeChildData() async {
    await _loadChildren();
    if (_selectedChildId != null) {
      await _loadWritingMonitoringStatus(_selectedChildId!);
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoadingChildren = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final response = await _childService.getParentChildren(parentId: user.id);
        if (response.isSuccess && response.data != null) {
          setState(() {
            _children = response.data!;
            if (_children.isNotEmpty && _selectedChildId == null) {
              _selectedChildId = _children.first.id.toString();
              _selectedChildName = _children.first.name;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
    }

    setState(() {
      _isLoadingChildren = false;
    });
  }

  Future<void> _loadWritingMonitoringStatus(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'writing_restrictions_$childId';
    final isEnabled = prefs.getBool(key) ?? false;
    setState(() {
      _writingMonitoringEnabled = isEnabled;
    });
  }

  Future<void> _saveWritingMonitoringStatus(String childId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('writing_restrictions_$childId', enabled);

    final textMonitorService = TextMonitorService();
    await textMonitorService.setWritingRestrictionsEnabled(enabled);

    if (enabled && _selectedChildName != null) {
      final user = await _authService.getCurrentUser();
      final token = await _authService.getToken();
      final refreshToken = await _authService.getRefreshToken();

      // Determine the correct parent ID
      String parentId = user?.id ?? '';
      if (user?.userType == 'child') {
        final child = _children.firstWhere(
          (c) => c.id.toString() == childId,
          orElse: () => _children.firstWhere(
            (c) => c.name == _selectedChildName!,
            orElse: () => Child(
              id: '',
              parentId: user?.id ?? '',
              email: '',
              name: '',
              age: 0,
            ),
          ),
        );
        parentId = child.parentId;
      }

      await textMonitorService.saveChildInfo(
        parentId: parentId,
        childName: _selectedChildName!,
        childId: childId,
        token: token ?? '',
        refreshToken: refreshToken,
      );
    }
  }

  Widget _buildChildAndWritingMonitoringSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          'قيود الكتابة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر الطفل:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FutureBuilder<UserData?>(
                    future: _authService.getCurrentUser(),
                    builder: (context, snapshot) {
                      final currentUser = snapshot.data;
                      if (currentUser != null && currentUser.userType == 'child') {
                        return DropdownButton<String>(
                          isExpanded: true,
                          underline: Container(),
                          value: currentUser.id,
                          items: [
                            DropdownMenuItem<String>(
                              value: currentUser.id,
                              child: Text(currentUser.name),
                            ),
                          ],
                          onChanged: (value) {},
                        );
                      } else {
                        return DropdownButton<String>(
                          isExpanded: true,
                          underline: Container(),
                          value: _selectedChildId,
                          hint: const Text('اختر طفل'),
                          items: _children.map((child) {
                            return DropdownMenuItem<String>(
                              value: child.id.toString(),
                              child: Text(child.name),
                            );
                          }).toList(),
                          onChanged: _isLoadingChildren
                              ? null
                              : (value) {
                                  if (value != null) {
                                    final child = _children.firstWhere(
                                      (c) => c.id.toString() == value,
                                    );
                                    setState(() {
                                      _selectedChildId = value;
                                      _selectedChildName = child.name;
                                    });
                                    _loadWritingMonitoringStatus(value);
                                  }
                                },
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _writingMonitoringEnabled,
                      onChanged: (value) async {
                        final currentUser = await _authService.getCurrentUser();
                        if (currentUser != null &&
                            currentUser.userType == 'child' &&
                            !value) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'لا يمكنك تعطيل مراقبة الكتابة. يتطلب إذن من الوالد.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        setState(() {
                          _writingMonitoringEnabled = value;
                        });
                        if (_selectedChildId != null) {
                          _saveWritingMonitoringStatus(_selectedChildId!, value);
                        }
                      },
                      activeColor: Colors.white,
                      activeTrackColor: navy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفعيل مراقبة الكتابة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _writingMonitoringEnabled ? 'الحماية مفعلّة' : 'الحماية معطّلة',
                            style: TextStyle(
                              color: _writingMonitoringEnabled ? navy : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'تحليل النصوص بالذكاء الاصطناعي في جميع التطبيقات',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ✅ block-app: Setup dialog once (child only)
  // ================================================================

  Future<void> _maybeShowSetupDialogOnce() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ امنعها عن الأب نهائياً
    final role = (prefs.getString('user_role') ?? '').trim().toLowerCase();
    if (role != 'child') return;

    final done = prefs.getBool(_setupDoneKey) ?? false;
    if (done) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تفعيل حماية الطفل (مرة واحدة)'),
            content: const Text(
              'لتفعيل حظر التطبيقات تلقائيًا على جهاز الطفل، يلزم منح صلاحيتين مرة واحدة فقط:\n\n'
              '1) Usage Access\n'
              '2) الظهور فوق التطبيقات (Overlay)\n\n'
              'بعد التفعيل لن تظهر هذه الرسالة مرة أخرى.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await NativeBridge.openUsageAccessSettings();
                },
                child: const Text('فتح Usage Access'),
              ),
              TextButton(
                onPressed: () async {
                  await NativeBridge.openOverlaySettings();
                },
                child: const Text('فتح Overlay'),
              ),
              FilledButton(
                onPressed: () async {
                  await NativeBridge.startMonitoring();

                  // ✅ اسحب policy من السيرفر وطبّقها (لو الطفل)
                  try {
                    await PolicyService(apiClient: _authService.apiClient)
                        .fetchAndApplyChildPolicy();
                  } catch (_) {}

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_setupDoneKey, true);

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('تم - تشغيل الحماية'),
              ),
            ],
          ),
        );
      },
    );
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
        final currentUser = await _authService.getCurrentUser();

        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('خطأ: لم يتم تحميل معلومات المستخدم. الرجاء تسجيل الدخول مرة أخرى.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        String parentId = '';
        if (widget.child != null && widget.child!.parentId.isNotEmpty) {
          parentId = widget.child!.parentId;
        } else {
          final prefs = await SharedPreferences.getInstance();
          parentId = prefs.getString('parent_id') ?? '';
        }

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

        final response = await _emergencyService.sendEmergencyAlert(
          childId: currentUser.id,
          parentId: parentId,
        );

        final childName = widget.child?.name ?? currentUser.name;

        // ✅ main: notification includes childId (keep newest feature)
        final notificationResponse = await _notificationService.sendEmergencyNotification(
          childName: childName,
          parentId: parentId,
          childId: currentUser.id,
        );

        if (notificationResponse.isSuccess) {
          debugPrint('✅ Emergency notification sent for child: $childName');
        } else {
          debugPrint('⚠️ Failed to send notification: ${notificationResponse.error}');
        }

        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال إشعار الطوارئ ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          String errorMessage = response.error ?? 'فشل في إرسال إشعار الطوارئ';

          if (errorMessage.contains('Authentication credentials were not provided') ||
              errorMessage.contains('انتهت جلسة العمل')) {
            errorMessage = 'انتهت جلسة العمل. الرجاء تسجيل الدخول مرة أخرى.';
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
            SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
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
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ✅ block-app: عرض معلومات الطفل إن توفرت
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                  // صورة الطوارئ
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

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12.withOpacity(.06), blurRadius: 8),
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
                          'بالضغط على هذا الزر سيتم إشعار ولي الأمر فورًا   ولا يمكن التراجع بعد التنفيذ.',
                          style: TextStyle(fontSize: 14.5, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: danger,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _confirmAndSend,
                      child: const Text(
                        'إرسال طوارئ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ main: قسم قيود الكتابة كامل
                  _buildChildAndWritingMonitoringSection(),

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
