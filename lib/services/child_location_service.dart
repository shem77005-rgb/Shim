import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/geo_zone_model.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';

class ChildLocationService {
  static StreamSubscription<Position>? _positionStream;
  static Timer? _locationTimer;
  static List<GeoZone> _zones = [];
  static String? _accessToken;
  static int? _childId;
  static Position? _lastPosition;

  static ApiClient? _apiClient;

  static void initialize(String accessToken, int childId) {
    _accessToken = accessToken;
    _childId = childId;

    // Initialize the API client with the access token
    _apiClient = ApiClient();
    if (_accessToken != null) {
      _apiClient!.setAuthToken(_accessToken!);
    }
  }

  static ApiClient _getApiClient() {
    if (_apiClient == null) {
      _apiClient = ApiClient();
      if (_accessToken != null) {
        _apiClient!.setAuthToken(_accessToken!);
      }
    }
    return _apiClient!;
  }

  static Future<void> startLocationMonitoring() async {
    // Request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Load zones for the child
    await _loadZones();

    // Start location stream with distance filter
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // Update every 20 meters
      ),
    ).listen((Position position) {
      _checkPositionAndSendAlert(position);
    });

    // Fallback: Update every 30 seconds if location doesn't change much
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      Position currentPos = await Geolocator.getCurrentPosition();
      _checkPositionAndSendAlert(currentPos);
    });
  }

  static Future<void> _loadZones() async {
    try {
      final apiClient = ChildLocationService._getApiClient();
      final response = await apiClient.get<List<dynamic>>(
        ApiConstants.geoZones,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        List<dynamic> data = response.data!;
        _zones =
            data
                .where((zone) => zone['child'] == _childId)
                .map((json) => GeoZone.fromJson(json))
                .toList();
      } else if (response.hasError) {
        print('Error loading zones: ${response.error}');
      }
    } catch (e) {
      print('Error loading zones: $e');
    }
  }

  static void _checkPositionAndSendAlert(Position position) {
    // Send current location to backend
    _sendLocationToBackend(position);

    // Check each zone
    for (GeoZone zone in _zones) {
      bool isInside = _isLocationInZone(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
        zone.radius.toDouble(),
      );

      // Send alert if child enters a restricted zone
      if (zone.zoneType == 'restricted' && isInside) {
        _sendAlertToParent(zone, 'enter');
      }

      // Send alert if child exits a safe zone
      if (zone.zoneType == 'safe' && !isInside) {
        _sendAlertToParent(zone, 'exit');
      }
    }

    _lastPosition = position;
  }

  static bool _isLocationInZone(
    double childLat,
    double childLng,
    double zoneLat,
    double zoneLng,
    double radius,
  ) {
    const earthRadius = 6371000; // meters
    double dLat = _degToRad(zoneLat - childLat);
    double dLon = _degToRad(zoneLng - childLng);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(childLat)) *
            cos(_degToRad(zoneLat)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance <= radius;
  }

  static double _degToRad(double deg) => deg * (pi / 180);

  static Future<void> _sendLocationToBackend(Position position) async {
    try {
      final apiClient = ChildLocationService._getApiClient();
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiConstants.childLocations,
        body: {
          'child': _childId,
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        requiresAuth: true,
      );

      if (response.hasError) {
        print('Error sending location: ${response.error}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  static Future<void> _sendAlertToParent(GeoZone zone, String event) async {
    try {
      final apiClient = ChildLocationService._getApiClient();

      // Send alert to backend
      final alertResponse = await apiClient.post<Map<String, dynamic>>(
        ApiConstants.geoAlerts,
        body: {'child': _childId, 'zone': zone.id, 'event': event},
        requiresAuth: true,
      );

      if (alertResponse.hasError) {
        print('Error sending alert: ${alertResponse.error}');
      }

      // Send notification to parent
      final notificationResponse = await apiClient.post<Map<String, dynamic>>(
        ApiConstants.notificationsSend,
        body: {
          'child_id': _childId,
          'title': 'Geographical Alert',
          'description': 'Child entered restricted area: ${zone.name}',
          'category': 'security',
        },
        requiresAuth: false, // Notifications endpoint might not require auth
      );

      if (notificationResponse.hasError) {
        print('Error sending notification: ${notificationResponse.error}');
      }
    } catch (e) {
      print('Error sending alert: $e');
    }
  }

  static void stopLocationMonitoring() {
    _positionStream?.cancel();
    _locationTimer?.cancel();
  }

  static List<GeoZone> getZones() => _zones;
  static Position? getLastPosition() => _lastPosition;
}
