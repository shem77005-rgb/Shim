import 'package:geolocator/geolocator.dart';
import '../models/geo_zone_model.dart';
import '../models/geo_alert_model.dart';
import 'geo_restriction_service.dart';
import '../features/auth/data/services/auth_service.dart';
import 'permission_service.dart';

class ChildGeoService {
  final GeoRestrictionService _geoService;
  final AuthService _authService;

  ChildGeoService({
    required GeoRestrictionService geoService,
    required AuthService authService,
  }) : _geoService = geoService,
       _authService = authService;

  /// Check if the current location is inside any of the defined zones
  Future<List<GeoZone>> checkCurrentZone() async {
    try {
      final position = await _getCurrentLocation();
      if (position == null) return [];

      // Get zones for the current child only
      final childId = await _getChildId();
      if (childId == null) return [];

      final zonesResponse = await _geoService.getZonesForChild(childId);
      if (!zonesResponse.isSuccess || zonesResponse.data == null) {
        return [];
      }

      // Check which zones the current location is in
      final currentZones = <GeoZone>[];

      for (final zone in zonesResponse.data!) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );

        if (distance <= zone.radius) {
          // Check if the zone has time restrictions
          if (_isWithinTimeRestriction(zone)) {
            currentZones.add(zone);
          }
        }
      }

      return currentZones;
    } catch (e) {
      print('Error checking current zone: $e');
      return [];
    }
  }

  /// Check if the current time is within the zone's time restrictions
  bool _isWithinTimeRestriction(GeoZone zone) {
    // If the zone doesn't have time restrictions, it's always active
    if (zone.startTime == null || zone.endTime == null || !zone.isActive) {
      return true;
    }

    try {
      final now = DateTime.now();

      // Parse start and end times from HH:MM format
      final startTimeParts = zone.startTime!.split(':');
      final endTimeParts = zone.endTime!.split(':');

      // Create DateTime objects for today with the specified times
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      // Handle case where end time is past midnight (e.g. 22:00 to 06:00)
      if (endTime.isBefore(startTime)) {
        // This is a cross-midnight period
        return now.isAfter(startTime) || now.isBefore(endTime);
      } else {
        // Normal period within same day
        return now.isAfter(startTime) && now.isBefore(endTime);
      }
    } catch (e) {
      print('Error parsing time restriction: $e');
      // If there's an error parsing times, assume the zone is active
      return true;
    }
  }

  /// Monitor zone entry/exit events
  Future<void> monitorZoneTransitions({
    Function(List<GeoZone> enteredZones)? onEnter,
    Function(List<GeoZone> exitedZones)? onExit,
  }) async {
    try {
      final currentZones = await checkCurrentZone();

      // Get previous zones from storage or cache
      final previousZones = await _getPreviousZones();

      // Compare zones to detect transitions
      final enteredZones =
          currentZones
              .where(
                (zone) =>
                    !previousZones.any((prevZone) => prevZone.id == zone.id),
              )
              .toList();

      final exitedZones =
          previousZones
              .where(
                (zone) =>
                    !currentZones.any((currZone) => currZone.id == zone.id),
              )
              .toList();

      // Save current zones as previous zones for next comparison
      await _saveCurrentZones(currentZones);

      if (enteredZones.isNotEmpty && onEnter != null) {
        onEnter(enteredZones);
      }

      if (exitedZones.isNotEmpty && onExit != null) {
        onExit(exitedZones);
      }
    } catch (e) {
      print('Error monitoring zone transitions: $e');
    }
  }

  /// Send an alert when a zone boundary is crossed
  Future<bool> sendGeoAlert({
    required int childId,
    required String eventType, // 'entry' or 'exit'
    required double latitude,
    required double longitude,
    int? geoZoneId,
    String? message,
  }) async {
    try {
      final geoAlert = GeoAlert(
        child: childId,
        geoZone: geoZoneId,
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().toIso8601String(),
        message: message,
      );

      final response = await _geoService.createGeoAlert(geoAlert);
      return response.isSuccess;
    } catch (e) {
      print('Error sending geo alert: $e');
      return false;
    }
  }

  /// Get the current location of the device
  Future<Position?> _getCurrentLocation() async {
    // Check if location permissions are granted
    final hasPermission = await PermissionService.isLocationPermissionGranted();
    if (!hasPermission) {
      // Request location permission
      final granted = await PermissionService.requestLocation();
      if (!granted) {
        print('Location permissions denied.');
        return null;
      }
    }

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

  /// Get the current child's ID from auth
  Future<int?> _getChildId() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && user.userType == 'child') {
        // Parse the user ID as integer
        return int.tryParse(user.id) ?? null;
      }
      return null;
    } catch (e) {
      print('Error getting child ID: $e');
      return null;
    }
  }

  /// Get previous zones from storage/cache
  Future<List<GeoZone>> _getPreviousZones() async {
    // In a real implementation, this would fetch from shared preferences or database
    // For now, returning an empty list
    return [];
  }

  /// Save current zones to storage/cache
  Future<void> _saveCurrentZones(List<GeoZone> zones) async {
    // In a real implementation, this would save to shared preferences or database
    // For now, just a placeholder
  }

  /// Continuously monitor location and check for zone boundaries
  Stream<LocationTrackerEvent> monitorLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).asyncMap((position) async {
      final zones = await checkCurrentZone();
      return LocationTrackerEvent(position: position, zones: zones);
    });
  }

  getCurrentPosition() {}
}

class LocationTrackerEvent {
  final Position position;
  final List<GeoZone> zones;

  LocationTrackerEvent({required this.position, required this.zones});
}
