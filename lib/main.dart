import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_gate.dart';

// 1. MUST be a top-level function (outside any class or main)
// This executes in an isolated background thread when a push notification arrives while the app is killed or minimized.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");

  // Trigger high-priority siren notification and alarm sound in background
  await NotificationService.showSirenNotification(message);
  await EmergencyAlarmService.startAlarm();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    publishableKey: dotenv.get('SUPABASE_PUBLISHABLE_KEY'),
  );

  // Initialize Firebase Cloud Messaging & Core Services
  await Firebase.initializeApp();

  // 2. Register the top-level background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();

  runApp(const AsinAlertApp());
}

class AsinAlertApp extends StatelessWidget {
  const AsinAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A.S.I.N. Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          secondary: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}