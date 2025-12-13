# Core API Module

This directory contains the core API infrastructure used throughout the application.

## Files Overview

### 📄 `api_constants.dart`
**Purpose:** Centralized API configuration and endpoints

**Contains:**
- Base URL configuration
- API endpoints for all features
- Timeout settings
- HTTP headers configuration

**Example:**
```dart
ApiConstants.baseUrl           // 'https://your-api-domain.com/api'
ApiConstants.parentLogin       // '/auth/parent/login'
ApiConstants.connectionTimeout // Duration(seconds: 30)
```

### 📄 `api_client.dart`
**Purpose:** HTTP client wrapper for making API requests

**Features:**
- Handles GET, POST, PUT, DELETE requests
- Automatic token management
- Error handling and parsing
- Timeout management
- Response formatting

**Example:**
```dart
final apiClient = ApiClient();

// POST request
final response = await apiClient.post(
  '/auth/login',
  body: {'email': 'user@example.com', 'password': 'pass123'},
);

// GET request with auth
final response = await apiClient.get(
  '/user/profile',
  requiresAuth: true,
);
```

### 📄 `api_response.dart`
**Purpose:** Generic response wrapper for type-safe API responses

**Structure:**
```dart
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
}
```

**Usage:**
```dart
final response = await apiClient.post(...);

if (response.isSuccess) {
  print(response.data); // Access successful data
} else {
  print(response.error); // Access error message
}
```

## Architecture Flow

```
UI Layer (Screens)
      ↓
Service Layer (AuthService, etc.)
      ↓
API Client (ApiClient)
      ↓
HTTP Layer (http package)
      ↓
Backend API
```

## Key Features

✅ **Centralized Configuration** - All API settings in one place  
✅ **Type Safety** - Generic response types  
✅ **Error Handling** - Comprehensive error messages  
✅ **Token Management** - Automatic authentication  
✅ **Reusability** - Used across all features  

## Usage in Services

When creating a new service, use the API client:

```dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_response.dart';

class MyService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<MyData>> fetchData() async {
    final response = await _apiClient.get<dynamic>(
      ApiConstants.myEndpoint,
      requiresAuth: true,
    );

    if (response.isSuccess) {
      final data = MyData.fromJson(response.data);
      return ApiResponse.success(data);
    } else {
      return ApiResponse.error(response.error ?? 'فشل جلب البيانات');
    }
  }
}
```

## Configuration

Before using the API in production:

1. Update `baseUrl` in `api_constants.dart`
2. Verify all endpoint paths match your backend
3. Adjust timeout settings if needed
4. Test with your actual API

## Error Messages

All error messages are in Arabic for user-facing errors:
- Network errors
- Timeout errors
- Authentication errors
- Server errors
- Validation errors
