import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:studentos/app/router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'studentos_notifications',
    'StudentOS notifications',
    description: 'StudentOS notification alerts',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || Firebase.apps.isEmpty) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await messaging.requestPermission();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        _openRoute(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _openMessage(initialMessage);
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final notification = message.notification;
    final android = notification?.android;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: android?.smallIcon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _routeFrom(message),
    );
  }

  void _openMessage(RemoteMessage message) {
    _openRoute(_routeFrom(message));
  }

  void _openRoute(String? route) {
    final location = route?.trim();
    notificationRouter.go(
      location == null || location.isEmpty || !location.startsWith('/')
          ? '/404'
          : location,
    );
  }

  String? _routeFrom(RemoteMessage message) {
    final dataRoute = message.data['route']?.toString().trim();
    if (dataRoute != null && dataRoute.isNotEmpty) return dataRoute;

    final body = message.notification?.body?.trim();
    return body != null && body.startsWith('/') ? body : null;
  }
}
