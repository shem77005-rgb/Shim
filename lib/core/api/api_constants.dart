/// API Constants - All API endpoints and configurations
class ApiConstants {
  // Base URL - Django Development Server
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Full Base URL
  static String get fullBaseUrl => baseUrl;

  // Authentication Endpoints
  static const String register = '/api/register/';
  static const String login = '/api/login/';
  static const String logout = '/api/logout/';
  static const String refreshToken = '/api/refresh/';
  static const String forgotPassword = '/api/forgot-password/';
  static const String resetPassword = '/api/reset-password/';

  // Parent Endpoints
  static const String parentLogin = '/api/login/';
  static const String parentRegister = '/api/register/';

  // Child Endpoints
  static const String childLogin = '/api/child/login/';
  static const String childRegister = '/api/children/';
  static const String childUpdate = '/api/children/'; // PUT /api/children/{id}/
  static const String emergencyAlert = '/api/emergency/';

  // Notifications Endpoints
  static const String notifications = '/api/notifications/';

  // Writing Check Endpoint (AI Text Analysis)
  static const String writingCheck = '/api/v1/writing-check/';

  // Restricted Words Endpoints
  static const String restrictedWords = '/api/v1/restricted-words/';
  static const String restrictedWordsByChild =
      '/api/v1/restricted-words/?child_id=';
  static const String restrictedWordsRemoveByChild =
      '/api/v1/restricted-words/child/'; // Use: {restrictedWordsRemoveByChild}{childId}/remove/

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headersf
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';

  static String childFcmToken(int childId) => '/api/children/$childId/fcm-token/';
  static const String childPolicy = '/api/child/policy/';
  static String childApps(int childId) => '/api/children/$childId/apps/';
  static String childAppsInventory(int childId) => '/api/children/$childId/apps/inventory/';
  static String childPolicyForParent(int childId) => '/api/children/$childId/policy/';

}
