// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';

// /// Firebase Messaging Service - Handles push notifications
// class FirebaseMessagingService {
//   static final FirebaseMessagingService _instance =
//       FirebaseMessagingService._internal();
//   factory 8FirebaseMessagingService() => _instance;
//   FirebaseMessagingService._internal();

//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   String? _fcmToken;
//   String? get fcmToken => _fcmToken;

//   /// Initialize Firebase Messaging
//   Future<void> initialize() async {
//     try {
//       // Request permission for notifications
//       NotificationSettings settings = await _firebaseMessaging
//           .requestPermission(
//             alert: true,
//             announcement: false,
//             badge: true,
//             carPlay: false,
//             criticalAlert: true,
//             provisional: false,
//             sound: true,
//           );

//       print('🔵 [FCM] Permission status: ${settings.authorizationStatus}');

//       if (settings.authorizationStatus == AuthorizationStatus.authorized ||
//           settings.authorizationStatus == AuthorizationStatus.provisional) {
//         // Get FCM token
//         _fcmToken = await _firebaseMessaging.getToken();
//         print('🔵 [FCM] Token: $_fcmToken');

//         // Initialize local notifications for foreground
//         await _initializeLocalNotifications();

//         // Handle foreground messages
//         FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//         // Handle background messages
//         FirebaseMessaging.onBackgroundMessage(
//           _firebaseMessagingBackgroundHandler,
//         );

//         // Handle notification tap when app is in background
//         FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

//         // Check if app was opened from a notification
//         RemoteMessage? initialMessage =
//             await _firebaseMessaging.getInitialMessage();
//         if (initialMessage != null) {
//           _handleMessageOpenedApp(initialMessage);
//         }

//         print('✅ [FCM] Firebase Messaging initialized successfully');
//       } else {
//         print('⚠️ [FCM] Notification permission not granted');
//       }
//     } catch (e) {
//       print('❌ [FCM] Error initializing: $e');
//     }
//   }

//   /// Initialize local notifications for foreground display
//   Future<void> _initializeLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//     );

//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         print('🔵 [FCM] Local notification tapped: ${response.payload}');
//       },
//     );

//     // Create notification channel for Android
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'emergency_channel',
//       'Emergency Notifications',
//       description: 'This channel is used for emergency notifications',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//     );

//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);
//   }

//   /// Handle foreground messages
//   void _handleForegroundMessage(RemoteMessage message) {
//     print('🔵 [FCM] Foreground message received:');
//     print('🔵 [FCM] Title: ${message.notification?.title}');
//     print('🔵 [FCM] Body: ${message.notification?.body}');
//     print('🔵 [FCM] Data: ${message.data}');

//     // Show local notification
//     _showLocalNotification(message);
//   }

//   /// Handle when app is opened from notification
//   void _handleMessageOpenedApp(RemoteMessage message) {
//     print('🔵 [FCM] App opened from notification:');
//     print('🔵 [FCM] Title: ${message.notification?.title}');
//     print('🔵 [FCM] Data: ${message.data}');

//     // TODO: Navigate to specific screen based on message data
//   }

//   /// Show local notification
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     RemoteNotification? notification = message.notification;

//     if (notification != null) {
//       await _localNotifications.show(
//         notification.hashCode,
//         notification.title ?? 'تنبيه طوارئ',
//         notification.body ?? '',
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'emergency_channel',
//             'Emergency Notifications',
//             channelDescription:
//                 'This channel is used for emergency notifications',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//             enableVibration: true,
//             icon: '@mipmap/ic_launcher',
//           ),
//         ),
//         payload: message.data.toString(),
//       );
//     }
//   }

//   /// Subscribe to topic (e.g., parent ID)
//   Future<void> subscribeToTopic(String topic) async {
//     try {
//       await _firebaseMessaging.subscribeToTopic(topic);
//       print('✅ [FCM] Subscribed to topic: $topic');
//     } catch (e) {
//       print('❌ [FCM] Error subscribing to topic: $e');
//     }
//   }

//   /// Unsubscribe from topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await _firebaseMessaging.unsubscribeFromTopic(topic);
//       print('✅ [FCM] Unsubscribed from topic: $topic');
//     } catch (e) {
//       print('❌ [FCM] Error unsubscribing from topic: $e');
//     }
//   }

//   /// Get the FCM token for sending to backend
//   Future<String?> getToken() async {
//     _fcmToken = await _firebaseMessaging.getToken();
//     return _fcmToken;
//   }
// }

// /// Background message handler (must be top-level function)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('🔵 [FCM] Background message received: ${message.messageId}');
// }

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safechild_system/native_bridge.dart';
import '../core/api/api_constants.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const String _roleKey = 'user_role';
  static const String _lastPolicyPayloadKey = 'last_policy_payload';
  static const String _pendingPolicyKey = 'pending_policy_update';
  static const String _policyAppliedOnceKey = 'policy_applied_once';

  static const String _childIdKey = 'child_id';
  static const String _accessTokenKey = 'auth_token';

  Future<void> initialize() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      debugPrint('🟦 [FCM] Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('🟦 [FCM] Token: $_fcmToken');

        await _initializeLocalNotifications();

        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          _fcmToken = newToken;
          debugPrint('🟦 [FCM] Token refreshed: $_fcmToken');
        });

        FirebaseMessaging.onMessage.listen((msg) async {
          await _handleIncomingMessage(msg, source: 'foreground');
        });

        FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
          await _handleIncomingMessage(msg, source: 'opened_app');
        });

        final initial = await _firebaseMessaging.getInitialMessage();
        if (initial != null) {
          await _handleIncomingMessage(initial, source: 'initial_message');
        }

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        await _tryApplyPendingPolicyIfChild();

        debugPrint('✅ [FCM] Initialized');
      } else {
        debugPrint('⚠️ [FCM] Permission not granted');
      }
    } catch (e) {
      debugPrint('❌ [FCM] initialize error: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🟦 [FCM] Local notification tapped: ${response.payload}');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Notifications',
      description: 'This channel is used for emergency notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<String> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_roleKey) ?? '').trim().toLowerCase();
  }

  Future<bool> _isChildDevice() async {
    final role = await _getRole();
    final isChild = role == 'child';
    debugPrint('🟦 [Policy] _isChildDevice=$isChild (role=$role)');
    return isChild;
  }

  Future<int?> _getChildIdSafe(SharedPreferences prefs) async {
    final intId = prefs.getInt(_childIdKey);
    if (intId != null) return intId;

    final strId = prefs.getString(_childIdKey);
    if (strId == null || strId.trim().isEmpty) return null;

    return int.tryParse(strId.trim());
  }

  Future<void> syncChildTokenToServer() async {
    try {
      if (!await _isChildDevice()) {
        debugPrint('🟡 [FCM] Token sync skipped (not child)');
        return;
      }

      final token = _fcmToken ?? await _firebaseMessaging.getToken();
      _fcmToken = token;

      debugPrint('🟦 [FCM] sync token=$_fcmToken');

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [FCM] Token sync skipped (empty token)');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final childId = await _getChildIdSafe(prefs);
      final accessToken = prefs.getString(_accessTokenKey);

      debugPrint('🟦 [FCM] childId=$childId accessToken?=${accessToken != null && accessToken.isNotEmpty}');

      if (childId == null) {
        debugPrint('⚠️ [FCM] Token sync skipped (missing/invalid child_id)');
        return;
      }
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ [FCM] Token sync skipped (missing auth_token)');
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.fullBaseUrl,
          connectTimeout: ApiConstants.connectionTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Accept': ApiConstants.acceptJson,
          },
        ),
      );

      final url = ApiConstants.childFcmToken(childId);
      debugPrint('🟦 [FCM] POST $url');

      final resp = await dio.post(
        url,
        data: {"token": token},
        options: Options(headers: {"Authorization": "Bearer $accessToken"}),
      );

      debugPrint('🟦 [FCM] token sync status=${resp.statusCode} body=${resp.data}');
      debugPrint('✅ [FCM] Token synced to server for child=$childId');
    } catch (e) {
      debugPrint('❌ [FCM] Token sync failed: $e');
    }
  }

  /// مهم: رجعت bool عشان PolicyService يقدر يطبع نتيجة التطبيق
  Future<bool> applyPolicyPayload(Map<String, dynamic> data) async {
    return await _applyPolicyFromData(data);
  }

  Future<void> _tryApplyPendingPolicyIfChild() async {
    try {
      if (!await _isChildDevice()) return;

      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(_pendingPolicyKey);
      if (pending == null || pending.isEmpty) return;

      debugPrint('🟦 [Policy] Found pending policy -> applying...');

      final decoded = jsonDecode(pending);
      if (decoded is Map<String, dynamic>) {
        await _applyPolicyFromData(decoded);
      }

      await prefs.remove(_pendingPolicyKey);
    } catch (e) {
      debugPrint('❌ [Policy] apply pending error: $e');
    }
  }

  Future<void> _handleIncomingMessage(RemoteMessage message, {required String source}) async {
    debugPrint('🟦 [FCM][$source] title=${message.notification?.title}');
    debugPrint('🟦 [FCM][$source] data=${message.data}');

    final type = (message.data['type'] ?? '').toString().trim();

    if (type == 'policy_update') {
      if (!await _isChildDevice()) {
        debugPrint('🟡 [Policy] Ignored policy_update (not child)');
        return;
      }

      await _applyPolicyFromData(message.data);
      return;
    }

    _showLocalNotification(message);
  }

  Future<bool> _applyPolicyFromData(Map<String, dynamic> data) async {
    try {
      if (!await _isChildDevice()) {
        debugPrint('🟡 [Policy] blocked apply (not child)');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPolicyPayloadKey, jsonEncode(data));

      debugPrint('🟦 [Policy] payload=${jsonEncode(data)}');

      final rulesRaw = data['rules'];
      List<dynamic> rulesList = [];

      if (rulesRaw == null) {
        debugPrint('⚠️ [Policy] No rules in payload');
        return false;
      }

      if (rulesRaw is String) {
        final decoded = jsonDecode(rulesRaw);
        if (decoded is Map && decoded['rules'] is List) {
          rulesList = decoded['rules'] as List;
        } else if (decoded is List) {
          rulesList = decoded;
        } else {
          debugPrint('⚠️ [Policy] rules string not parseable');
          return false;
        }
      } else if (rulesRaw is List) {
        rulesList = rulesRaw;
      } else if (rulesRaw is Map && (rulesRaw['rules'] is List)) {
        rulesList = rulesRaw['rules'] as List;
      }

      debugPrint('🟦 [Policy] rulesCount=${rulesList.length}');

      if (rulesList.isEmpty) {
        debugPrint('🟡 [Policy] Empty rules -> nothing to apply');
        return true;
      }

      debugPrint('🟦 [Policy] clearAllLimits()');
      await NativeBridge.clearAllLimits();

      int applied = 0;

      for (final r in rulesList) {
        if (r is! Map) continue;

        final pkg = (r['package'] ?? r['pkg'] ?? '').toString().trim();
        final limitAny = r['limit_ms'] ?? r['millis'] ?? r['ms'] ?? 0;

        if (pkg.isEmpty) continue;

        final limitMs = limitAny is int ? limitAny : int.tryParse(limitAny.toString()) ?? 0;
        if (limitMs <= 0) continue;

        debugPrint('🟦 [Policy] setLimit pkg=$pkg limitMs=$limitMs');
        await NativeBridge.setLimit(pkg, limitMs);
        applied++;
      }

      debugPrint('🟦 [Policy] appliedLimits=$applied -> startMonitoring()');
      await NativeBridge.startMonitoring();

      await prefs.setBool(_policyAppliedOnceKey, true);
      debugPrint('✅ [Policy] Monitoring started');
      return true;
    } catch (e) {
      debugPrint('❌ [Policy] apply error: $e');
      return false;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'تنبيه',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Notifications',
          channelDescription: 'This channel is used for emergency notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data.toString(),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🟦 [FCM][background] data=${message.data}');

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_background_message', jsonEncode(message.data));

    final type = (message.data['type'] ?? '').toString().trim();
    if (type == 'policy_update') {
      await prefs.setString('pending_policy_update', jsonEncode(message.data));
      debugPrint('🟦 [FCM][background] policy_update saved as pending');
    }
  } catch (e) {
    debugPrint('❌ [FCM][background] error: $e');
  }
}

