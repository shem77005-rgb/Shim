import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../core/api/api_constants.dart';
import '../models/geo_zone_model.dart';
import '../models/child_location_model.dart';
import '../models/geo_alert_model.dart';
import '../features/auth/data/services/auth_service.dart';

class GeoRestrictionService {
  final ApiClient _apiClient;

  GeoRestrictionService({required ApiClient apiClient})
    : _apiClient = apiClient;

  // ================= GEO ZONES =================

  Future<ApiResponse<List<GeoZone>>> getZones() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.geoZones,
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.get(
            ApiConstants.geoZones,
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            final zones =
                (retryResponse.data as List)
                    .map((json) => GeoZone.fromJson(json))
                    .toList();
            return ApiResponse.success(zones);
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to load zones',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

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

  Future<ApiResponse<GeoZone>> createZone(GeoZone zone) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.geoZones,
        body: zone.toJson(),
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.post(
            ApiConstants.geoZones,
            body: zone.toJson(),
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            return ApiResponse.success(GeoZone.fromJson(retryResponse.data));
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to create zone',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoZone.fromJson(response.data));
      }

      return ApiResponse.error(response.error ?? 'Failed to create zone');
    } catch (e) {
      return ApiResponse.error('Error creating zone: $e');
    }
  }

  Future<ApiResponse<GeoZone>> updateZone(GeoZone zone) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.geoZones}${zone.id}/',
        body: zone.toJson(),
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.put(
            '${ApiConstants.geoZones}${zone.id}/',
            body: zone.toJson(),
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            return ApiResponse.success(GeoZone.fromJson(retryResponse.data));
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to update zone',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoZone.fromJson(response.data));
      }

      return ApiResponse.error(response.error ?? 'Failed to update zone');
    } catch (e) {
      return ApiResponse.error('Error updating zone: $e');
    }
  }

  Future<ApiResponse<bool>> deleteZone(int zoneId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.geoZones}$zoneId/',
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.delete(
            '${ApiConstants.geoZones}$zoneId/',
            requiresAuth: true,
          );

          return retryResponse.isSuccess
              ? ApiResponse.success(true)
              : ApiResponse.error(
                retryResponse.error ?? 'Failed to delete zone',
              );
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      return response.isSuccess
          ? ApiResponse.success(true)
          : ApiResponse.error(response.error ?? 'Failed to delete zone');
    } catch (e) {
      return ApiResponse.error('Error deleting zone: $e');
    }
  }

  // ================= CHILD LOCATION =================

  Future<ApiResponse<ChildLocation>> getLastLocation(int childId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.childLocationByChild}$childId/',
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.get(
            '${ApiConstants.childLocationByChild}$childId/',
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            return ApiResponse.success(
              ChildLocation.fromJson(retryResponse.data),
            );
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to load last location',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(ChildLocation.fromJson(response.data));
      }

      return ApiResponse.error('Failed to load last location');
    } catch (e) {
      return ApiResponse.error('Error loading last location: $e');
    }
  }

  Future<ApiResponse<bool>> sendLocation(
    int childId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.childLocations,
        body: {'child': childId, 'latitude': latitude, 'longitude': longitude},
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.post(
            ApiConstants.childLocations,
            body: {
              'child': childId,
              'latitude': latitude,
              'longitude': longitude,
            },
            requiresAuth: true,
          );

          return retryResponse.isSuccess
              ? ApiResponse.success(true)
              : ApiResponse.error(
                retryResponse.error ?? 'Failed to send location',
              );
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      return response.isSuccess
          ? ApiResponse.success(true)
          : ApiResponse.error('Failed to send location');
    } catch (e) {
      return ApiResponse.error('Error sending location: $e');
    }
  }

  // ================= GEO ALERTS =================

  Future<ApiResponse<List<GeoAlert>>> getChildAlerts(int childId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.geoAlertsByChild}$childId/',
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.get(
            '${ApiConstants.geoAlertsByChild}$childId/',
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            final alerts =
                (retryResponse.data as List)
                    .map((json) => GeoAlert.fromJson(json))
                    .toList();
            return ApiResponse.success(alerts);
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to load alerts',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        final alerts =
            (response.data as List)
                .map((json) => GeoAlert.fromJson(json))
                .toList();
        return ApiResponse.success(alerts);
      }

      return ApiResponse.error('Failed to load alerts');
    } catch (e) {
      return ApiResponse.error('Error loading alerts: $e');
    }
  }

  Future<ApiResponse<GeoAlert>> createGeoAlert(GeoAlert alert) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.geoAlerts,
        body: alert.toJson(),
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.post(
            ApiConstants.geoAlerts,
            body: alert.toJson(),
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            return ApiResponse.success(GeoAlert.fromJson(retryResponse.data));
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to create geo alert',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(GeoAlert.fromJson(response.data));
      }

      return ApiResponse.error('Failed to create geo alert');
    } catch (e) {
      return ApiResponse.error('Error creating geo alert: $e');
    }
  }

  // Method to get zones for a specific child
  Future<ApiResponse<List<GeoZone>>> getZonesForChild(int childId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.geoZonesByChild(childId),
        requiresAuth: true,
      );

      if (response.error?.contains('انتهت الجلسة') == true ||
          response.error?.contains('Session ended') == true) {
        print(
          '🔒 [GeoRestrictionService] Authentication failed, attempting token refresh',
        );

        // Try to refresh the token
        final authService = AuthService();
        final refreshResponse = await authService.refreshToken();

        if (refreshResponse.isSuccess) {
          print(
            '✅ [GeoRestrictionService] Token refreshed successfully, retrying request',
          );
          // Retry the request with the new token
          final retryResponse = await _apiClient.get(
            ApiConstants.geoZonesByChild(childId),
            requiresAuth: true,
          );

          if (retryResponse.isSuccess && retryResponse.data != null) {
            final zones =
                (retryResponse.data as List)
                    .map((json) => GeoZone.fromJson(json))
                    .toList();
            return ApiResponse.success(zones);
          } else {
            print(
              '❌ [GeoRestrictionService] Retry failed: ${retryResponse.error}',
            );
            return ApiResponse.error(
              retryResponse.error ?? 'Failed to load zones for child',
            );
          }
        } else {
          print(
            '❌ [GeoRestrictionService] Token refresh failed: ${refreshResponse.error}',
          );
          return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
        }
      }

      if (response.isSuccess && response.data != null) {
        final zones =
            (response.data as List)
                .map((json) => GeoZone.fromJson(json))
                .toList();
        return ApiResponse.success(zones);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load zones for child',
      );
    } catch (e) {
      return ApiResponse.error('Error loading zones for child: $e');
    }
  }
}
