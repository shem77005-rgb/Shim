
import 'package:safechild_system/core/api/api_client.dart';
import 'package:safechild_system/features/auth/data/services/auth_service.dart';
import 'package:safechild_system/services/geo_restriction_service.dart';

late final AuthService authService;
late final ApiClient apiClient;
late final GeoRestrictionService geoRestrictionService;

Future<void> setupServices() async {
  authService = AuthService();
  await authService.init();

  apiClient = authService.apiClient;

  geoRestrictionService = GeoRestrictionService(
    apiClient: apiClient,
  );
}
