import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:safechild_system/core/di/service_locator.dart';

import 'package:safechild_system/models/geo_zone_model.dart';
import 'package:safechild_system/services/child_geo_service.dart';
import 'package:safechild_system/services/permission_service.dart';

class ChildGeographicalRestrictionsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildGeographicalRestrictionsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildGeographicalRestrictionsScreen> createState() =>
      _ChildGeographicalRestrictionsScreenState();
}

class _ChildGeographicalRestrictionsScreenState
    extends State<ChildGeographicalRestrictionsScreen> {
  // ✅ استخدم الخدمات التي تم تهيئتها في service_locator.dart
  late final ChildGeoService _childGeoService;

  Position? _currentPosition;
  List<GeoZone> _currentZones = [];

  StreamSubscription<LocationTrackerEvent>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    // تهيئة الخدمة باستخدام geoRestrictionService و authService من service_locator
    _childGeoService = ChildGeoService(
      geoService: geoRestrictionService,
      authService: authService,
    );

    // بدء تتبع الموقع والمناطق الجغرافية
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    // First check and request location permissions
    bool hasPermission = await PermissionService.isLocationPermissionGranted();

    if (!hasPermission) {
      hasPermission = await PermissionService.requestLocation();

      if (!hasPermission) {
        // Show error message if permission is denied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('التطبيق يحتاج إذن تحديد الموقع للعمل بشكل صحيح'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تفعيل خدمات الموقع على الجهاز'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Now start the location stream
    _locationSubscription = _childGeoService.monitorLocationStream().listen(
      (event) {
        setState(() {
          _currentPosition = event.position;
          _currentZones = event.zones;
        });
      },
      onError: (error) {
        print('Error in location stream: \$error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تتبع الموقع: \$error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // جلب المنطقة الحالية فوراً (اختياري)
    try {
      final zones = await _childGeoService.checkCurrentZone();
      final position = await _getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentZones = zones;
        });
      }
    } catch (e) {
      print('❌ Error getting initial position: \$e');
    }
  }

  /// Get the current location of the device
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions denied.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions denied forever.');
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('القيود الجغرافية - ${widget.childName}')),
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [_buildInfoCard(), Expanded(child: _buildMap())],
              ),
    );
  }

  /// ---------------- UI ----------------

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الموقع الحالي',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}'
              ' , Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 8),
            Text(
              _currentZones.isEmpty
                  ? 'لم يتم إضافة مناطق جغرافية لهذا الطفل'
                  : 'المناطق الحالية:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            _currentZones.isEmpty
                ? const SizedBox.shrink() // Empty space when no zones
                : Column(
                  children:
                      _currentZones
                          .map(
                            (zone) => Text('✔ ${zone.name} (${zone.zoneType})'),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final LatLng currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return FlutterMap(
      options: MapOptions(center: currentLatLng, zoom: 15),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safechild.system',
        ),

        /// Marker (موقع الطفل)
        MarkerLayer(
          markers: [
            Marker(
              point: currentLatLng,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ],
        ),

        /// Zones - only show if there are zones for this child
        if (_currentZones.isNotEmpty)
          CircleLayer(
            circles:
                _currentZones
                    .map(
                      (zone) => CircleMarker(
                        point: LatLng(zone.latitude, zone.longitude),
                        radius: zone.radius.toDouble(),
                        useRadiusInMeter: true,
                        color:
                            zone.zoneType == 'safe'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                        borderColor:
                            zone.zoneType == 'safe' ? Colors.green : Colors.red,
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
