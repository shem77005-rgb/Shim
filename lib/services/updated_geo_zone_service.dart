import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../core/api/api_constants.dart';
import '../models/geo_zone_model.dart';

class UpdatedGeoZoneService {
  final ApiClient _apiClient;

  UpdatedGeoZoneService({required ApiClient apiClient})
    : _apiClient = apiClient;

  // Add a new geographic zone - follows the exact backend specification
  Future<ApiResponse<GeoZone>> addGeoZone({
    required int childId,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String zoneType, // 'safe' or 'restricted'
  }) async {
    try {
      // Create the zone object with only the required fields
      final zone = GeoZone(
        child: childId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        zoneType: zoneType,
      );

      // Use the existing API infrastructure which properly handles authentication and headers
      final response = await _apiClient.post(
        ApiConstants.geoZones,
        body: zone.toJson(), // This now only includes the required fields
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoZone.fromJson(response.data));
      }

      return ApiResponse.error(response.error ?? 'Failed to create zone');
    } catch (e) {
      return ApiResponse.error('Error creating zone: $e');
    }
  }

  // Get all geographic zones
  Future<ApiResponse<List<GeoZone>>> getAllGeoZones() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.geoZones,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final zones =
            (response.data as List)
                .map((json) => GeoZone.fromJson(json))
                .toList();
        return ApiResponse.success(zones);
      }

      return ApiResponse.error(response.error ?? 'Failed to load zones');
    } catch (e) {
      return ApiResponse.error('Error loading zones: $e');
    }
  }

  // Get specific geographic zone
  Future<ApiResponse<GeoZone>> getGeoZone(int zoneId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.geoZones}$zoneId/',
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoZone.fromJson(response.data));
      }

      return ApiResponse.error(response.error ?? 'Failed to load zone');
    } catch (e) {
      return ApiResponse.error('Error loading zone: $e');
    }
  }

  // Update a geographic zone
  Future<ApiResponse<GeoZone>> updateGeoZone(GeoZone zone) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.geoZones}${zone.id}/',
        body: zone.toJson(), // Only sends the required fields
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoZone.fromJson(response.data));
      }

      return ApiResponse.error(response.error ?? 'Failed to update zone');
    } catch (e) {
      return ApiResponse.error('Error updating zone: $e');
    }
  }

  // Delete a geographic zone
  Future<ApiResponse<bool>> deleteGeoZone(int zoneId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.geoZones}$zoneId/',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        return ApiResponse.success(true);
      }

      return ApiResponse.error(response.error ?? 'Failed to delete zone');
    } catch (e) {
      return ApiResponse.error('Error deleting zone: $e');
    }
  }
}
