import 'dart:typed_data';
import 'package:asin_alert/services/EmergencyAlarmService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final bool isSilent = message.data['is_silent'] == 'true' ||
      message.data['is_silent'] == true;

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    if (isSilent) {
      await NotificationService.showSilentNotification(message);
    } else {
      await NotificationService.showSirenNotification(message);
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final Int64List _vibrationPattern = Int64List.fromList([
    0,
    1000,
    500,
    1000,
  ]);

  // 🔊 Loud Siren Channel
  static final AndroidNotificationChannel _sirenChannel =
      AndroidNotificationChannel(
    'siren_channel_v3',
    'Emergency Siren Alerts',
    description: 'High-priority emergency alerts for PNP police responders.',
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('siren'),
    enableVibration: true,
    vibrationPattern: _vibrationPattern,
  );

  // 🤫 Soundless Channel (Visual Banner Only)
  static final AndroidNotificationChannel _silentChannel =
      AndroidNotificationChannel(
    'silent_alert_channel_v2', // Bumped ID to force Android to apply new soundless rules
    'Silent Panic Alerts',
    description: 'Discreet emergency alerts without audio or siren.',
    importance: Importance.high,
    playSound: false, // 🔇 No Audio
    enableVibration: false, // 🔇 No Loud Vibration
  );

  /// Initialize Local Notifications & FCM Message Handlers
  static Future<void> initialize() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

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
      await androidPlugin.createNotificationChannel(_silentChannel);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 📩 Foreground Notification Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final bool isSilent = message.data['is_silent'] == 'true' ||
          message.data['is_silent'] == true;

      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', currentUser.id)
            .maybeSingle();

        final String userRole =
            profileResponse?['role']?.toString().toLowerCase() ?? '';

        if (userRole == 'police') {
          if (isSilent) {
            // Display soundless banner, DO NOT start continuous EmergencyAlarmService audio
            await showSilentNotification(message);
          } else {
            // Loud alert
            await showSirenNotification(message, playSound: false);
            await EmergencyAlarmService.startAlarm();
          }
        } else {
          // Establishment side
          if (isSilent) {
            await showSilentNotification(message);
          } else {
            await showSirenNotification(message, playSound: true);
          }
        }
      } catch (e) {
        debugPrint('Error checking user role in FCM handler: $e');
        if (isSilent) {
          await showSilentNotification(message);
        } else {
          await showSirenNotification(message);
        }
      }
    });
  }

  /// Displays the High-Priority Siren Banner
  static Future<void> showSirenNotification(
    RemoteMessage message, {
    bool playSound = true,
  }) async {
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
      playSound: playSound,
      sound: playSound
          ? const RawResourceAndroidNotificationSound('siren')
          : null,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: playSound,
        presentAlert: true,
        presentBadge: true,
        sound: playSound ? 'siren.aiff' : null,
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  /// Displays a Soundless Notification Banner
  static Future<void> showSilentNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '🤫 SILENT EMERGENCY ALERT';
    final body =
        notification?.body ?? message.data['body'] ?? 'A silent panic alert was triggered discretely.';

    const androidDetails = AndroidNotificationDetails(
      'silent_alert_channel_v2',
      'Silent Panic Alerts',
      channelDescription: 'Discreet emergency alerts without siren audio.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false, // 🔇 NO SOUND
      sound: null,
      enableVibration: false, // 🔇 NO LOUD VIBRATION
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: false, // 🔇 NO SOUND
        presentAlert: true,
        presentBadge: true,
        sound: null,
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