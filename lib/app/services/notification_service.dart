import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/chat/views/chat_screen.dart';
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// A notification tapped from a fully-killed state (getInitialMessage)
  /// arrives while the app is still on the splash screen - navigating then
  /// is either dropped (no navigator yet) or immediately wiped by the
  /// splash's own Get.offNamed(HOME). Park it here and let SplashView call
  /// consumePendingLaunchLink() once it has landed on Home.
  Map<String, dynamic>? _pendingLaunchData;

  Future<void> init() async {
    // FirebaseMessaging.instance must never be touched before confirming a
    // Firebase app actually exists - it throws '[core/no-app] No Firebase
    // App has been created' when Firebase.initializeApp() hasn't succeeded
    // (e.g. no google-services.json configured for this build yet). This
    // exact bug (as an eager field initializer, evaluated at construction
    // time before any guard could run) was caught and fixed in
    // docwellness-user's equivalent PushNotificationService via a real
    // device smoke test - fixed proactively here too, before it has a
    // chance to bite whenever main.dart's enableFirebaseNotifications flag
    // is turned on.
    if (Firebase.apps.isEmpty) {
      debugPrint('NotificationService: Firebase not initialized, push disabled');
      return;
    }

    final fcm = FirebaseMessaging.instance;

    // 1. Request permissions for iOS and Android 13+
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Foreground taps: FCM doesn't surface a system notification while
        // the app is in front, so we show our own (see _showLocalNotification,
        // whose payload is the message's data as JSON) - this fires when the
        // dietician taps that one. Route it exactly like a background tap.
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handleNotificationTap(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (e) {
          log('NotificationService: bad notification payload: $e');
        }
      },
    );

    // 3. Create high-importance channel for Android (required for heads-up notifications & ringing)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id must match AndroidManifest.xml
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 4. Set up Firebase Messaging listeners
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification?.title}');
        _showLocalNotification(message);
      }
    });

    // Tapped from background (app was open but backgrounded).
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) => _handleNotificationTap(message.data),
    );

    // Tapped from a fully-killed state - the message that launched the app.
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage.data);

    // 5. Get the FCM Token and register it with the backend
    // (POST /api/dietician/device-token - see deviceTokenController.js)
    await _registerCurrentToken(fcm);

    // Listen for token refreshes
    fcm.onTokenRefresh.listen((_) => _registerCurrentToken(fcm));
  }

  Future<void> _registerCurrentToken(FirebaseMessaging fcm) async {
    try {
      final fcmToken = await fcm.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      if (token == null || token!.isEmpty) return; // not logged in yet

      debugPrint('FCM token obtained, registering with backend');
      await ApiService().request(
        endPoint: '/device-token',
        method: 'POST',
        data: {
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (e) {
      debugPrint('NotificationService: token registration failed (non-fatal): $e');
    }
  }

  /// Single entry point for every notification tap (background via
  /// onMessageOpenedApp, killed via getInitialMessage, foreground via the
  /// local-notification response). Routes now if the app is past the splash
  /// screen; otherwise parks the data for SplashView to replay.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final route = Get.currentRoute;
    final ready =
        route.isNotEmpty && route != Routes.SPLASH && route != Routes.AUTH;
    if (!ready) {
      _pendingLaunchData = data;
      return;
    }
    _routeFromData(data);
  }

  /// Called by SplashView once it has navigated to Home - replays a
  /// notification tap that arrived during launch.
  void consumePendingLaunchLink() {
    final data = _pendingLaunchData;
    if (data == null) return;
    _pendingLaunchData = null;
    _routeFromData(data);
  }

  void _routeFromData(Map<String, dynamic> data) {
    final deepLink = data['deepLink'] as String?;
    if (deepLink == null || deepLink.isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;

    switch (uri.host) {
      case 'chat':
        // A chat message from a patient - open that exact conversation, the
        // same way tapping a 'chat' notification in the in-app list does
        // (see NotificationController.onTapNotification).
        final conversationId = data['conversationId'] as String?;
        if (conversationId == null || conversationId.isEmpty) {
          Get.toNamed(Routes.NOTIFICATIONS);
          return;
        }
        if (!Get.isRegistered<ChatController>()) {
          Get.put(ChatController());
        }
        Get.to(() => ChatScreen(conversationId: conversationId));
        break;
      case 'logged-data':
        // A patient logged a meal - jump to that patient's profile, where
        // the "Client Logged Data" screen is reachable.
        final patientId = data['patientId'] as String?;
        if (patientId != null && patientId.isNotEmpty) {
          Get.toNamed('/patient-profile/$patientId');
        } else {
          Get.toNamed(Routes.NOTIFICATIONS);
        }
        break;
      default:
        // Anything else (payment / consultation / diet nudges, future
        // types) - at least land on the notifications list rather than
        // dropping the tap on the floor.
        Get.toNamed(Routes.NOTIFICATIONS);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // JSON (not Map.toString()) so onDidReceiveNotificationResponse can
        // decode it and route the tap - see init() above.
        payload: jsonEncode(message.data),
      );
    }
  }
}
