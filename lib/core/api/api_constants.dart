/// API Constants - All API endpoints and configurations
class ApiConstants {
  // Base URL - Django Development Server (Android Emulator)
  // Use 10.0.2.2 to access localhost from Android Emulator
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
  static const String childLogin = '/api/login/';
  static const String childRegister = '/api/children/';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';
}
