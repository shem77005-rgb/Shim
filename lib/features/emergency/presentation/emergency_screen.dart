import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/child_model.dart';
import '../../../services/child_service.dart';
import '../../../services/emergency_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/text_monitor_service.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/data/services/auth_service.dart';
import '../../children/presentation/child_login_screen.dart';

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
    // Initialize the emergency service with the authenticated API client
    _emergencyService = EmergencyService(apiClient: _authService.apiClient);
    _notificationService = NotificationService(
      apiClient: _authService.apiClient,
    );
    _childService = ChildService(apiClient: _authService.apiClient);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);

    // Load children and writing monitoring status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChildData();
      // If child data was passed to the screen, save it to the Android service
      // if writing restrictions are enabled
      if (widget.child != null) {
        _checkAndSaveChildInfoIfEnabled(widget.child!);
      }
    });
  }

  Future<void> _checkAndSaveChildInfoIfEnabled(Child child) async {
    // Always save the child info when a child logs in, regardless of whether restrictions are enabled
    // This ensures the Android service has the correct child information
    final token = await _authService.getToken();
    final refreshToken = await _authService.getRefreshToken();

    final textMonitorService = TextMonitorService();
    await textMonitorService.saveChildInfo(
      parentId: child.parentId, // Use the parent ID from the child object
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
        final response = await _childService.getParentChildren(
          parentId: user.id,
        );
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

  Future<void> _saveWritingMonitoringStatus(
    String childId,
    bool enabled,
  ) async {
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
        // If current user is a child, find the parent ID from the children list
        // Look for the child in the loaded children list to get their parent ID
        final child = _children.firstWhere(
          (c) => c.id.toString() == childId,
          orElse:
              () => _children.firstWhere(
                (c) => c.name == _selectedChildName!,
                orElse:
                    () => Child(
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
                // Child Selection
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
                      if (currentUser != null &&
                          currentUser.userType == 'child') {
                        // If the current user is a child, show only their name
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
                          onChanged: (value) {
                            // Disabled for child users
                          },
                        );
                      } else {
                        // If the current user is a parent, show all children
                        return DropdownButton<String>(
                          isExpanded: true,
                          underline: Container(),
                          value: _selectedChildId,
                          hint: const Text('اختر طفل'),
                          items:
                              _children.map((child) {
                                return DropdownMenuItem<String>(
                                  value: child.id.toString(),
                                  child: Text(child.name),
                                );
                              }).toList(),
                          onChanged:
                              _isLoadingChildren
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
                // Writing Monitoring Toggle
                Row(
                  children: [
                    Switch(
                      value: _writingMonitoringEnabled,
                      onChanged: (value) async {
                        // Check if user is a child trying to disable the protection
                        final currentUser = await _authService.getCurrentUser();
                        if (currentUser != null &&
                            currentUser.userType == 'child' &&
                            !value) {
                          // If child is trying to turn OFF
                          // Show error message
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
                          // Don't change the toggle value
                          return;
                        }

                        setState(() {
                          _writingMonitoringEnabled = value;
                        });
                        if (_selectedChildId != null) {
                          _saveWritingMonitoringStatus(
                            _selectedChildId!,
                            value,
                          );
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _writingMonitoringEnabled
                                ? 'الحماية مفعلّة'
                                : 'الحماية معطّلة',
                            style: TextStyle(
                              color:
                                  _writingMonitoringEnabled
                                      ? navy
                                      : Colors.black45,
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

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد إرسال الطوارئ'),
              content: const Text(
                'هل تريد بالتأكيد إرسال إشعار طارئ إلى ولي الأمر؟',
              ),
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
        // Get the current user (child)
        final currentUser = await _authService.getCurrentUser();

        if (currentUser == null) {
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
          // Navigate back to login screen
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Get parent ID - either from the child object or from auth service
        String parentId = '';
        if (widget.child != null && widget.child!.parentId.isNotEmpty) {
          parentId = widget.child!.parentId;
        } else {
          // Fallback to getting parent ID from auth service
          final prefs = await SharedPreferences.getInstance();
          parentId = prefs.getString('parent_id') ?? '';
        }

        // Validate we have both child and parent IDs
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

        // Send emergency alert
        final response = await _emergencyService.sendEmergencyAlert(
          childId: currentUser.id,
          parentId: parentId,
        );

        // Also send a notification to the parent
        final childName = widget.child?.name ?? currentUser.name;
        print(
          '🔵 [EmergencyScreen] Sending notification for child: $childName to parent: $parentId',
        );

        final notificationResponse = await _notificationService
            .sendEmergencyNotification(
              childName: childName,
              parentId: parentId,
              childId: currentUser.id,
            );

        if (notificationResponse.isSuccess) {
          print('✅ [EmergencyScreen] Notification sent successfully!');
          debugPrint('✅ Emergency notification sent for child: $childName');
        } else {
          print(
            '❌ [EmergencyScreen] Failed to send notification: ${notificationResponse.error}',
          );
          debugPrint(
            '⚠️ Failed to send notification: ${notificationResponse.error}',
          );
        }

        if (response.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال إشعار الطوارئ ✅'),
              backgroundColor: Colors.green,
            ),
          );

          // Log the emergency alert
          debugPrint(
            'Emergency alert sent for child: ${currentUser.name} (ID: ${currentUser.id}) to parent ID: $parentId',
          );
        } else if (mounted) {
          // Handle specific authentication errors
          String errorMessage = response.error ?? 'فشل في إرسال إشعار الطوارئ';

          // Check if it's an authentication error
          if (errorMessage.contains(
                'Authentication credentials were not provided',
              ) ||
              errorMessage.contains('انتهت جلسة العمل')) {
            errorMessage = 'انتهت جلسة العمل. الرجاء تسجيل الدخول مرة أخرى.';

            // Navigate back to login screen
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
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
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
          automaticallyImplyLeading: false, // Disable the back button
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Child information is intentionally hidden on emergency screen for privacy
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
                        ),
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
                        'إرسال تنبية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Child Selection and Writing Monitoring Section
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
