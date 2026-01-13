import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/child_model.dart';
import '../../../models/geo_zone_model.dart';
import '../../../services/child_service.dart';
import '../../../services/geo_restriction_service.dart';
import '../../../features/auth/data/services/auth_service.dart';
import '../../../core/di/service_locator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class GeographicalZonesScreen extends StatefulWidget {
  const GeographicalZonesScreen({super.key});

  @override
  State<GeographicalZonesScreen> createState() =>
      _GeographicalZonesScreenState();
}

class _GeographicalZonesScreenState extends State<GeographicalZonesScreen> {
  bool _isLoading = true;
  String? _selectedChildId;
  String? _selectedChildName;
  List<Child> _children = [];
  List<GeoZone> _zones = [];

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
          // Filter children to ensure only those belonging to this parent are shown
          final parentChildren = response.data!;
          setState(() {
            _children = parentChildren;
            if (_children.isNotEmpty) {
              _selectedChildId = _children.first.id.toString();
              _selectedChildName = _children.first.name;
              _loadZonesForChild(_selectedChildId!);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading children: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadZonesForChild(String childId) async {
    try {
      // Load only zones for the specific child
      final response = await _geoRestrictionService.getZonesForChild(childId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _zones = response.data!;
        });
      }
    } catch (e) {
      print('Error loading zones: $e');
    }
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
      if (_selectedChildId != null) {
        _loadZonesForChild(_selectedChildId!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إضافة المنطقة: ${response.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteZone(int zoneId) async {
    final response = await _geoRestrictionService.deleteZone(zoneId);
    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المنطقة الجغرافية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      if (_selectedChildId != null) {
        _loadZonesForChild(_selectedChildId!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف المنطقة: ${response.error}'),
          backgroundColor: Colors.red,
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
            'المناطق الجغرافية',
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
          // Zones List
          _buildZonesCard(),
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
                  _loadZonesForChild(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesCard() {
    if (_zones.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'لا توجد مناطق جغرافية محددة',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على "إضافة منطقة جغرافية" لإنشاء منطقة جغرافية جديدة',
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
              'المناطق الحالية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._zones.map((zone) => _buildZoneItem(zone)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneItem(GeoZone zone) {
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
                    zone.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${zone.latitude.toStringAsFixed(4)}, ${zone.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              zone.zoneType == 'safe'
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          zone.zoneType == 'safe' ? 'آمنة' : 'محظورة',
                          style: TextStyle(
                            color:
                                zone.zoneType == 'safe'
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (zone.startTime != null && zone.endTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                zone.isActive
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'س:${zone.startTime} - ${zone.endTime}',
                            style: TextStyle(
                              color: zone.isActive ? Colors.blue : Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteZone(zone);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف المنطقة'),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteZone(GeoZone zone) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: Text(
                'هل أنت متأكد من رغبتك في حذف المنطقة "${zone.name}"؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteZone(zone.id!);
                  },
                  child: const Text('حذف'),
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
  double _selectedLatitude = 24.7136; // Default to Riyadh coordinates
  double _selectedLongitude = 46.6753;
  bool _isMapSelectionMode = false;
  bool _isSearching = false;
  List<Location> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('إضافة منطقة جغرافية لـ ${widget.childName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle between manual entry and map selection
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('إدخال يدوي'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('اختيار من الخريطة'),
                        ),
                      ],
                      selected: {_isMapSelectionMode},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isMapSelectionMode = newSelection.first;
                          if (_isMapSelectionMode) {
                            // Initialize controllers with current values
                            _latitudeController.text =
                                _selectedLatitude.toString();
                            _longitudeController.text =
                                _selectedLongitude.toString();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isMapSelectionMode)
                // Map selection view
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Search bar on top of the map
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'البحث عن موقع...',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) async {
                                if (value.length > 3) {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                  try {
                                    List<Location> locations =
                                        await locationFromAddress(value);
                                    setState(() {
                                      _searchResults = locations;
                                      _isSearching = false;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      _isSearching = false;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _searchResults = [];
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (_searchResults.isNotEmpty)
                          Positioned(
                            top: 60,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                itemCount:
                                    _searchResults.length > 5
                                        ? 5
                                        : _searchResults.length,
                                itemBuilder: (context, index) {
                                  Location location = _searchResults[index];
                                  return ListTile(
                                    title: Text('الموقع ${index + 1}'),
                                    subtitle: Text(
                                      '${location.latitude}, ${location.longitude}',
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedLatitude = location.latitude;
                                        _selectedLongitude = location.longitude;
                                        _searchResults = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        // Map with tap gesture recognition
                        GestureDetector(
                          onTapUp: (TapUpDetails details) async {
                            // Convert screen coordinates to map coordinates
                            // For now, we'll simulate getting the coordinates based on the map center
                            // In a real implementation, we would use map controller methods to convert pixel to lat/lng

                            // Update the selected position to where user tapped
                            // For simplicity, we'll use the current center + small offset based on tap position
                            RenderBox box =
                                context.findRenderObject() as RenderBox;
                            Offset localOffset = box.globalToLocal(
                              details.globalPosition,
                            );

                            // Calculate relative position on the map
                            double dx =
                                (localOffset.dx - box.size.width / 2) * 0.00001;
                            double dy =
                                (localOffset.dy - box.size.height / 2) *
                                -0.00001;

                            double newLat = _selectedLatitude + dy;
                            double newLng = _selectedLongitude + dx;

                            setState(() {
                              _selectedLatitude = newLat;
                              _selectedLongitude = newLng;
                              _latitudeController.text = newLat.toStringAsFixed(
                                6,
                              );
                              _longitudeController.text = newLng
                                  .toStringAsFixed(6);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم تحديد الموقع: ${newLat.toStringAsFixed(6)}, ${newLng.toStringAsFixed(6)}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: FlutterMap(
                            options: MapOptions(
                              center: LatLng(
                                _selectedLatitude,
                                _selectedLongitude,
                              ),
                              zoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _selectedLatitude,
                                      _selectedLongitude,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: ElevatedButton(
                            onPressed: () {
                              // Simulate getting current location or letting user set a specific location
                              // In a real implementation, you'd get the tap coordinates properly
                              setState(() {
                                _latitudeController.text = _selectedLatitude
                                    .toStringAsFixed(6);
                                _longitudeController.text = _selectedLongitude
                                    .toStringAsFixed(6);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'الرجاء تحديد الموقع على الخريطة يدويًا',
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            child: const Text('تحديد الموقع'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Manual entry view
                Expanded(
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
                          onChanged: (value) async {
                            if (value.length > 3) {
                              // Search for location when user types more than 3 characters
                              setState(() {
                                _isSearching = true;
                              });
                              try {
                                List<Location> locations =
                                    await locationFromAddress(value);
                                setState(() {
                                  _searchResults = locations;
                                  _isSearching = false;
                                });
                              } catch (e) {
                                setState(() {
                                  _isSearching = false;
                                });
                              }
                            } else {
                              setState(() {
                                _searchResults = [];
                              });
                            }
                          },
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView.builder(
                              itemCount:
                                  _searchResults.length > 5
                                      ? 5
                                      : _searchResults.length,
                              itemBuilder: (context, index) {
                                Location location = _searchResults[index];
                                return ListTile(
                                  title: Text('الموقع ${index + 1}'),
                                  subtitle: Text(
                                    '${location.latitude}, ${location.longitude}',
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedLatitude = location.latitude;
                                      _selectedLongitude = location.longitude;
                                      _latitudeController.text = location
                                          .latitude
                                          .toStringAsFixed(6);
                                      _longitudeController.text = location
                                          .longitude
                                          .toStringAsFixed(6);
                                      _searchResults = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'خط العرض (Latitude)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'خط الطول (Longitude)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                            DropdownMenuItem(
                              value: 'safe',
                              child: Text('منطقة آمنة'),
                            ),
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
            ],
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

      // Update selected coordinates in case they were changed via map
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;

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
          content: Text('الرجاء التأكد من صحة القيم المدخلة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
