import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child_location_model.dart';
import '../models/geo_alert_model.dart';
import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';

class ParentMonitoringService {
  static String? _accessToken;
  static ApiClient? _apiClient;

  static void initialize(String accessToken) {
    _accessToken = accessToken;

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

  // Get child's current location
  static Future<ChildLocation?> getCurrentLocation(int childId) async {
    try {
      final apiClient = _getApiClient();
      final response = await apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.childLocationByChild}$childId/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return ChildLocation.fromJson(response.data!);
      } else if (response.hasError) {
        print('Error getting location: ${response.error}');
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get recent alerts
  static Future<List<GeoAlert>> getRecentAlerts(int childId) async {
    try {
      final apiClient = _getApiClient();
      final response = await apiClient.get<List<dynamic>>(
        '${ApiConstants.recentGeoAlerts}$childId/recent',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!.map((json) => GeoAlert.fromJson(json)).toList();
      } else if (response.hasError) {
        print('Error getting alerts: ${response.error}');
      }
      return [];
    } catch (e) {
      print('Error getting alerts: $e');
      return [];
    }
  }

  // Get location history
  static Future<List<ChildLocation>> getLocationHistory(int childId) async {
    try {
      final apiClient = _getApiClient();
      final response = await apiClient.get<List<dynamic>>(
        '${ApiConstants.childLocationHistory}$childId/history',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!
            .map((json) => ChildLocation.fromJson(json))
            .toList();
      } else if (response.hasError) {
        print('Error getting history: ${response.error}');
      }
      return [];
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }
}
