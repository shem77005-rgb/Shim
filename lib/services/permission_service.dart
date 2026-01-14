import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request location permission for the app
  static Future<bool> requestLocation() async {
    // Check if location permissions are already granted
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    // Request location permission
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    // For Android, we can request background location separately
    if (status.isPermanentlyDenied) {
      // Open app settings to allow user to grant permission
      await openAppSettings();
      status = await Permission.location.status;
      return status.isGranted;
    }

    return false;
  }

  /// Request background location permission specifically for Android
  static Future<bool> requestBackgroundLocation() async {
    var status = await Permission.locationAlways.status;

    if (status.isGranted) {
      return true;
    }

    // Request background location permission
    status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Check if location permissions are granted
  static Future<bool> isLocationPermissionGranted() async {
    var status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if background location permission is granted (Android)
  static Future<bool> isBackgroundLocationPermissionGranted() async {
    var status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  /// Open app settings to allow user to grant permissions
  static Future<bool> openAppSettings() async {
    return await Permission.location.request().then((status) async {
      if (status.isPermanentlyDenied) {
        return await openAppSettings();
      }
      return status.isGranted;
    });
  }
}
