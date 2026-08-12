import 'dart:typed_data';
import 'package:asin_alert/services/EmergencyAlarmService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showSirenNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Explicit urgent vibration pattern: [delay, vibrate, pause, vibrate]
  static final Int64List _vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);

  // Bumped channel ID to force Android to apply the vibration pattern
  static final AndroidNotificationChannel _sirenChannel =
      AndroidNotificationChannel(
        'siren_channel_v3',
        'Emergency Siren Alerts',
        description:
            'High-priority emergency alerts for PNP police responders.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('siren'), // Points to res/raw/siren.mp3
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      );

  /// Initialize Local Notifications & FCM Message Handlers
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_sirenChannel);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showSirenNotification(message);
      EmergencyAlarmService.startAlarm();
    });
  }

  /// Displays the High-Priority Heads-Up Banner with custom Siren sound & vibration
  static Future<void> showSirenNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? '🚨 EMERGENCY PANIC ALERT';
    final body =
        notification?.body ?? 'An establishment has triggered an urgent alert!';

    final androidDetails = AndroidNotificationDetails(
      'siren_channel_v3',
      'Emergency Siren Alerts',
      channelDescription:
          'High-priority emergency alerts for PNP police responders.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('siren'),
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        sound: 'siren.aiff',
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}