import 'dart:typed_data';
import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final bool isSilent =
      message.data['is_silent'] == 'true' || message.data['is_silent'] == true;

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    if (isSilent) {
      await NotificationService.showSilentNotification(message);
    } else {
      await NotificationService.showAlertNotification(message);
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

  // 📳 Vibrating Emergency Channel (No Siren Sound)
  static final AndroidNotificationChannel _vibrationChannel =
      AndroidNotificationChannel(
        'vibration_alert_channel_v1', // Bumped ID to force Android to apply non-audio rule
        'Emergency Alert (Vibrate Only)',
        description:
            'High-priority emergency vibration alerts for PNP police responders.',
        importance: Importance.max,
        playSound: false, // 🔇 No Notification Siren Sound
        enableVibration: true, // 📳 Vibrate
        vibrationPattern: _vibrationPattern,
      );

  // 🤫 Soundless & Vibrationless Channel (Visual Banner Only)
  static final AndroidNotificationChannel _silentChannel =
      AndroidNotificationChannel(
        'silent_alert_channel_v2',
        'Silent Panic Alerts',
        description: 'Discreet emergency alerts without audio or vibration.',
        importance: Importance.high,
        playSound: false, // 🔇 No Audio
        enableVibration: false, // 🔇 No Vibration
      );

  /// Initialize Local Notifications & FCM Message Handlers
  static Future<void> initialize() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          badge: true,
          sound: false,
          criticalAlert: true,
        );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
    );

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
      await androidPlugin.createNotificationChannel(_vibrationChannel);
      await androidPlugin.createNotificationChannel(_silentChannel);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 📩 Foreground Notification Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final bool isSilent =
          message.data['is_silent'] == 'true' ||
          message.data['is_silent'] == true;

      // 🔍 Extract emergency status from message payload
      final String status = (message.data['status'] ?? '')
          .toString()
          .toLowerCase();
      final bool isAudioStatus =
          status == 'acknowledged' ||
          status == 'en_route' ||
          status == 'enroute';

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
            await showSilentNotification(message);
          } else {
            await showAlertNotification(message);

            // Audio alarm via EmergencyAlarmService triggered only when status requires it
            if (isAudioStatus) {
              await EmergencyAlarmService.startAlarm();
            }
          }
        } else {
          // Establishment side
          if (isSilent) {
            await showSilentNotification(message);
          } else {
            await showAlertNotification(message);
          }
        }
      } catch (e) {
        debugPrint('Error checking user role in FCM handler: $e');
        if (isSilent) {
          await showSilentNotification(message);
        } else {
          await showAlertNotification(message);
        }
      }
    });
  }

  /// Displays the High-Priority Vibrating Banner (No Siren Audio)
  static Future<void> showAlertNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title'] ??
        '🚨 EMERGENCY PANIC ALERT';
    final body =
        notification?.body ??
        message.data['body'] ??
        'An establishment has triggered an urgent alert!';

    final androidDetails = AndroidNotificationDetails(
      'vibration_alert_channel_v1',
      'Emergency Alert (Vibrate Only)',
      channelDescription:
          'High-priority emergency vibration alerts for PNP police responders.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: false, // 🔇 NO SIREN AUDIO
      sound: null,
      enableVibration: true, // 📳 VIBRATE ONLY
      vibrationPattern: _vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: false, // 🔇 NO SIREN AUDIO
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

  /// Displays a Soundless & Vibrationless Notification Banner
  static Future<void> showSilentNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title'] ??
        '🤫 SILENT EMERGENCY ALERT';
    final body =
        notification?.body ??
        message.data['body'] ??
        'A silent panic alert was triggered discretely.';

    const androidDetails = AndroidNotificationDetails(
      'silent_alert_channel_v2',
      'Silent Panic Alerts',
      channelDescription: 'Discreet emergency alerts without audio or vibration.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false, // 🔇 NO SOUND
      sound: null,
      enableVibration: false, // 🔇 NO VIBRATION
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: false,
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