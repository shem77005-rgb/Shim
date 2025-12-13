# هيكل ربط API - نظام SafeChild

## الهيكل التنظيمي للمشروع

```
lib/
├── core/
│   └── api/
│       ├── api_constants.dart      # روابط API والإعدادات
│       ├── api_client.dart         # عميل HTTP
│       └── api_response.dart       # نموذج الاستجابة العامة
│
└── features/
    └── auth/
        ├── data/
        │   ├── models/
        │   │   └── auth_models.dart     # نماذج الطلب والاستجابة
        │   └── services/
        │       └── auth_service.dart    # خدمة المصادقة
        └── presentation/
            ├── parent_login_screen.dart    # شاشة دخول ولي الأمر
            ├── parent_signup_screen.dart   # شاشة تسجيل ولي الأمر
            └── child_login_screen.dart     # شاشة دخول الطفل
```

## المكونات الرئيسية

### 1. ثوابت API (`core/api/api_constants.dart`)
يحتوي على جميع روابط API والإعدادات:
- رابط الخادم الأساسي
- نقاط نهاية المصادقة (تسجيل دخول، إنشاء حساب، تسجيل خروج)
- إعدادات المهلة الزمنية
- إعدادات الرؤوس

**كيفية تحديث رابط API:**
```dart
// في ملف api_constants.dart، قم بتغيير:
static const String baseUrl = 'https://your-api-domain.com/api';
```

### 2. عميل API (`core/api/api_client.dart`)
يتعامل مع:
- طلبات GET, POST, PUT, DELETE
- إدارة رمز المصادقة (Token)
- معالجة الأخطاء
- تحليل الاستجابات
- إدارة المهلة الزمنية

### 3. استجابة API (`core/api/api_response.dart`)
نموذج استجابة عامة يحتوي على:
```dart
ApiResponse<T> {
  T? data;           // البيانات المُرجعة
  String? error;     // رسالة الخطأ
  bool isSuccess;    // هل العملية نجحت؟
}
```

### 4. نماذج المصادقة (`features/auth/data/models/auth_models.dart`)
يحتوي على:
- `LoginRequest` - بيانات تسجيل الدخول
- `SignupRequest` - بيانات إنشاء الحساب
- `AuthResponse` - استجابة المصادقة
- `UserData` - معلومات المستخدم

### 5. خدمة المصادقة (`features/auth/data/services/auth_service.dart`)
خدمة تحتوي على:
- `parentLogin()` - تسجيل دخول ولي الأمر
- `parentSignup()` - إنشاء حساب ولي الأمر
- `childLogin()` - تسجيل دخول الطفل
- `logout()` - تسجيل الخروج
- تخزين الرموز باستخدام SharedPreferences

## أمثلة الاستخدام

### تسجيل دخول ولي الأمر
```dart
final authService = AuthService();

final response = await authService.parentLogin(
  email: 'parent@example.com',
  password: 'SecurePass123!',
);

if (response.isSuccess) {
  // تسجيل الدخول نجح
  print('الرمز: ${response.data.token}');
  print('المستخدم: ${response.data.user.email}');
} else {
  // تسجيل الدخول فشل
  print('خطأ: ${response.error}');
}
```

### إنشاء حساب ولي الأمر
```dart
final authService = AuthService();

final response = await authService.parentSignup(
  email: 'newparent@example.com',
  password: 'SecurePass123!',
  confirmPassword: 'SecurePass123!',
  name: 'أحمد محمد',
  phone: '+966501234567',
);

if (response.isSuccess) {
  // تم إنشاء الحساب بنجاح
  print('تم إنشاء الحساب!');
} else {
  print('خطأ: ${response.error}');
}
```

### تسجيل دخول الطفل
```dart
final authService = AuthService();

final response = await authService.childLogin(
  email: 'child@example.com',
  password: 'ChildPass123!',
);

if (response.isSuccess) {
  // تسجيل الدخول نجح
} else {
  print('خطأ: ${response.error}');
}
```

## نقاط النهاية (Endpoints)

### نقاط نهاية المصادقة

| الطريقة | الرابط | الوصف |
|--------|--------|-------|
| POST | `/auth/parent/login` | تسجيل دخول ولي الأمر |
| POST | `/auth/parent/signup` | إنشاء حساب ولي الأمر |
| POST | `/auth/child/login` | تسجيل دخول الطفل |
| POST | `/auth/logout` | تسجيل الخروج |

### صيغة الطلب والاستجابة المتوقعة

#### طلب تسجيل الدخول
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

#### طلب إنشاء الحساب
```json
{
  "email": "user@example.com",
  "password": "password123",
  "confirm_password": "password123",
  "name": "أحمد محمد",
  "phone": "+966501234567"
}
```

#### استجابة المصادقة
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "email": "user@example.com",
    "name": "أحمد محمد",
    "phone": "+966501234567",
    "user_type": "parent",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

## المميزات

✅ **هيكل منظم** - فصل واضح للمسؤوليات  
✅ **أمان النوع** - نماذج قوية النوع  
✅ **معالجة الأخطاء** - رسائل خطأ شاملة بالعربية  
✅ **إدارة الرموز** - تخزين واسترجاع تلقائي للرموز  
✅ **حالات التحميل** - مؤشرات تحميل مدمجة  
✅ **نمط Singleton** - نسخة واحدة من AuthService  
✅ **معالجة المهلة** - إدارة انتهاء وقت الشبكة  
✅ **كشف عدم الاتصال** - معالجة أخطاء الاتصال بالشبكة  

## المكتبات المطلوبة

أضف هذه المكتبات إلى `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

## الخطوات التالية

للربط مع خادم API الخاص بك:

1. **تحديث رابط API** في `api_constants.dart`
2. **تعديل النماذج** إذا كانت صيغة استجابة API مختلفة
3. **اختبار النقاط** مع الخادم الفعلي
4. **إضافة نقاط إضافية** حسب الحاجة

## رسائل الخطأ

جميع رسائل الخطأ بالعربية:
- `لا يوجد اتصال بالإنترنت` - لا يوجد اتصال بالإنترنت
- `انتهت مهلة الاتصال` - انتهت مهلة الاتصال
- `فشل تسجيل الدخول` - فشل تسجيل الدخول
- `فشل إنشاء الحساب` - فشل إنشاء الحساب
- `انتهت جلسة العمل` - يجب تسجيل الدخول مرة أخرى
- `غير مصرح لك بالوصول` - غير مصرح
- `خطأ في الخادم` - مشكلة في الخادم

## ملاحظات الأمان

- يتم إرسال كلمات المرور بشكل آمن (تأكد من استخدام HTTPS في الإنتاج)
- يتم تخزين الرموز محليًا باستخدام SharedPreferences
- يتم إضافة الرمز تلقائيًا إلى الطلبات المصادقة
- تسجيل الخروج يمسح جميع بيانات المصادقة المخزنة

## كيفية استخدام الهيكل في شاشات أخرى

### مثال: إضافة نقطة نهاية جديدة

1. **أضف الرابط في `api_constants.dart`:**
```dart
static const String getChildren = '/parent/children';
```

2. **أنشئ خدمة جديدة أو أضف إلى خدمة موجودة:**
```dart
Future<ApiResponse<List<Child>>> getChildren() async {
  final response = await _apiClient.get<dynamic>(
    ApiConstants.getChildren,
    requiresAuth: true,
  );
  
  if (response.isSuccess && response.data != null) {
    // تحويل البيانات إلى قائمة
    return ApiResponse.success(children);
  } else {
    return ApiResponse.error(response.error ?? 'فشل جلب البيانات');
  }
}
```

3. **استخدمه في الشاشة:**
```dart
final response = await service.getChildren();
if (response.isSuccess) {
  // عرض البيانات
}
```

## الدعم والمساعدة

للحصول على المساعدة:
1. راجع الأمثلة في هذا المستند
2. تحقق من رسائل الخطأ في Console
3. تأكد من صحة رابط API
4. تحقق من اتصالك بالإنترنت
