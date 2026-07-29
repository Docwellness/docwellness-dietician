import 'dart:io';

import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification click routing here
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

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Handle navigation when app is opened from background state via notification
    });

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
        payload: message.data.toString(),
      );
    }
  }
}
