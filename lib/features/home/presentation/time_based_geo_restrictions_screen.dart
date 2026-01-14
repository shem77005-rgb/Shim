import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/child_model.dart';
import '../../../models/geo_zone_model.dart';
import '../../../services/child_service.dart';
import '../../../services/geo_restriction_service.dart';
import '../../../features/auth/data/services/auth_service.dart';
import '../../../core/di/service_locator.dart';
import 'package:geolocator/geolocator.dart';

class TimeBasedGeoRestrictionsScreen extends StatefulWidget {
  const TimeBasedGeoRestrictionsScreen({super.key});

  @override
  State<TimeBasedGeoRestrictionsScreen> createState() =>
      _TimeBasedGeoRestrictionsScreenState();
}

class _TimeBasedGeoRestrictionsScreenState
    extends State<TimeBasedGeoRestrictionsScreen> {
  bool _enabled = false;
  bool _isLoading = true;
  String? _selectedChildId;
  String? _selectedChildName;
  List<Child> _children = [];
  List<TimeRestriction> _timeRestrictions = [];

  late GeoRestrictionService _geoRestrictionService;
  late ChildService _childService;
  final AuthService _authService = AuthService();

  static const Color bg = Color(0xFFF3F5F6);
  static const Color navy = Color(0xFF0A2E66);

  @override
  void initState() {
    super.initState();
    _geoRestrictionService = geoRestrictionService;
    _childService = ChildService(apiClient: _authService.apiClient);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final response = await _childService.getParentChildren(
          parentId: user.id,
        );
        if (response.isSuccess && response.data != null) {
          setState(() {
            _children = response.data!;
            if (_children.isNotEmpty) {
              _selectedChildId = _children.first.id.toString();
              _selectedChildName = _children.first.name;
              _loadTimeRestrictionsForChild(_selectedChildId!);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading children: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadTimeRestrictionsForChild(String childId) async {
    // For now, load from shared preferences - in a real app, this would come from the API
    final prefs = await SharedPreferences.getInstance();
    final restrictions = <TimeRestriction>[];

    // Load time restrictions for this child
    final startTime = prefs.getString('geo_time_start_$childId') ?? '';
    final endTime = prefs.getString('geo_time_end_$childId') ?? '';
    final isActive = prefs.getBool('geo_time_active_$childId') ?? false;

    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      restrictions.add(
        TimeRestriction(
          id: 1,
          childId: childId,
          startTime: startTime,
          endTime: endTime,
          isActive: isActive,
        ),
      );
    }

    setState(() {
      _timeRestrictions = restrictions;
    });
  }

  Future<void> _saveTimeRestrictionsForChild(
    String childId,
    TimeRestriction restriction,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('geo_time_start_$childId', restriction.startTime);
    await prefs.setString('geo_time_end_$childId', restriction.endTime);
    await prefs.setBool('geo_time_active_$childId', restriction.isActive);

    // Update the UI
    setState(() {
      _timeRestrictions = [restriction];
    });
  }

  Future<void> _addTimeRestriction() async {
    if (_selectedChildId == null) return;

    final restriction = await showDialog<TimeRestriction>(
      context: context,
      builder:
          (context) => _TimeRestrictionDialog(
            initialRestriction: TimeRestriction(
              id: _timeRestrictions.length + 1,
              childId: _selectedChildId!,
              startTime: '08:00',
              endTime: '20:00',
              isActive: true,
            ),
          ),
    );

    if (restriction != null) {
      await _saveTimeRestrictionsForChild(_selectedChildId!, restriction);
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
        floatingActionButton:
            _selectedChildId != null
                ? FloatingActionButton.extended(
                  onPressed: _addGeographicalZone,
                  icon: const Icon(Icons.add_location),
                  label: const Text('إضافة منطقة جغرافية'),
                  backgroundColor: navy,
                )
                : null,
      ),
    );
  }

  Future<void> _addGeographicalZone() async {
    if (_selectedChildId == null || _selectedChildName == null) return;

    final zone = await showDialog<GeoZone>(
      context: context,
      builder:
          (context) => _GeographicalZoneDialog(
            childId: _selectedChildId!,
            childName: _selectedChildName!,
          ),
    );

    if (zone != null) {
      await _createGeographicalZone(zone);
    }
  }

  Future<void> _createGeographicalZone(GeoZone zone) async {
    final response = await _geoRestrictionService.createZone(zone);
    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المنطقة الجغرافية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload zones if needed
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إضافة المنطقة: ${response.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            onPressed: _loadChildren,
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
            'القيود الجغرافية الزمنية',
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
          // Child Selection
          _buildChildSelectionCard(),
          const SizedBox(height: 12),
          // Time Restrictions List
          _buildTimeRestrictionsCard(),
          const SizedBox(height: 12),
          // Add New Restriction Button
          ElevatedButton.icon(
            onPressed: _addTimeRestriction,
            icon: const Icon(Icons.add),
            label: const Text('إضافة قيد زمني جديد'),
            style: ElevatedButton.styleFrom(backgroundColor: navy),
          ),
        ],
      ),
    );
  }

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
              items:
                  _children.map<DropdownMenuItem<String>>((child) {
                    return DropdownMenuItem<String>(
                      value: child.id.toString(),
                      child: Text(child.name),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final child = _children.firstWhere(
                    (c) => c.id.toString() == value,
                  );
                  setState(() {
                    _selectedChildId = value;
                    _selectedChildName = child.name;
                  });
                  _loadTimeRestrictionsForChild(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRestrictionsCard() {
    if (_timeRestrictions.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'لا توجد قيود زمنية محددة',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على "إضافة قيد زمني جديد" لإضافة قيود جغرافية زمنية',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'القيود الزمنية الحالية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._timeRestrictions
                .map((restriction) => _buildTimeRestrictionItem(restriction))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRestrictionItem(TimeRestriction restriction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'من ${restriction.startTime} إلى ${restriction.endTime}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restriction.isActive ? 'القيد مفعّل' : 'القيد غير مفعّل',
                    style: TextStyle(
                      color: restriction.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: restriction.isActive,
              onChanged: (value) {
                final updatedRestriction = TimeRestriction(
                  id: restriction.id,
                  childId: restriction.childId,
                  startTime: restriction.startTime,
                  endTime: restriction.endTime,
                  isActive: value,
                );
                _saveTimeRestrictionsForChild(
                  restriction.childId,
                  updatedRestriction,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding geographical zones
class _GeographicalZoneDialog extends StatefulWidget {
  final String childId;
  final String childName;

  const _GeographicalZoneDialog({
    required this.childId,
    required this.childName,
  });

  @override
  State<_GeographicalZoneDialog> createState() =>
      _GeographicalZoneDialogState();
}

class _GeographicalZoneDialogState extends State<_GeographicalZoneDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: '100',
  );
  String _zoneType = 'safe';
  String _startTime = '08:00';
  String _endTime = '20:00';
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('إضافة منطقة جغرافية لـ ${widget.childName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنطقة',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط العرض (Latitude)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'خط الطول (Longitude)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _radiusController,
                  decoration: const InputDecoration(
                    labelText: 'نصف القطر (متر)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _zoneType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المنطقة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'safe', child: Text('منطقة آمنة')),
                    DropdownMenuItem(
                      value: 'restricted',
                      child: Text('منطقة محظورة'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _zoneType = value ?? 'safe';
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Time restrictions section
                const Divider(),
                const Text(
                  'القيود الزمنية',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('وقت البدء'),
                        subtitle: Text(_startTime),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectStartTime,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('وقت الانتهاء'),
                        subtitle: Text(_endTime),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('تفعيل القيد الزمني'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(onPressed: _saveZone, child: const Text('حفظ')),
        ],
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _parseTime(_startTime),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (time != null) {
      setState(() {
        _startTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _parseTime(_endTime),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (time != null) {
      setState(() {
        _endTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  void _saveZone() {
    final name = _nameController.text.trim();
    final latitudeStr = _latitudeController.text.trim();
    final longitudeStr = _longitudeController.text.trim();
    final radiusStr = _radiusController.text.trim();

    if (name.isEmpty ||
        latitudeStr.isEmpty ||
        longitudeStr.isEmpty ||
        radiusStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final latitude = double.parse(latitudeStr);
      final longitude = double.parse(longitudeStr);
      final radius = double.parse(radiusStr);

      final zone = GeoZone(
        child: int.tryParse(widget.childId) ?? 0,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        zoneType: _zoneType,
        startTime: _startTime,
        endTime: _endTime,
        isActive: _isActive,
      );

      Navigator.pop(context, zone);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء التأكد من صحة القيم المدخلة: \$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class TimeRestriction {
  final int id;
  final String childId;
  final String startTime;
  final String endTime;
  final bool isActive;

  TimeRestriction({
    required this.id,
    required this.childId,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });
}

class _TimeRestrictionDialog extends StatefulWidget {
  final TimeRestriction initialRestriction;

  const _TimeRestrictionDialog({required this.initialRestriction});

  @override
  State<_TimeRestrictionDialog> createState() => _TimeRestrictionDialogState();
}

class _TimeRestrictionDialogState extends State<_TimeRestrictionDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.initialRestriction.startTime);
    _endTime = _parseTime(widget.initialRestriction.endTime);
    _isActive = widget.initialRestriction.isActive;
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة قيد زمني جديد'),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('وقت البدء'),
              subtitle: Text(_formatTime(_startTime)),
              trailing: const Icon(Icons.access_time),
              onTap: _selectStartTime,
            ),
            ListTile(
              title: const Text('وقت الانتهاء'),
              subtitle: Text(_formatTime(_endTime)),
              trailing: const Icon(Icons.access_time),
              onTap: _selectEndTime,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تفعيل القيد'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final restriction = TimeRestriction(
              id: widget.initialRestriction.id,
              childId: widget.initialRestriction.childId,
              startTime: _formatTime(_startTime),
              endTime: _formatTime(_endTime),
              isActive: _isActive,
            );
            Navigator.pop(context, restriction);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
