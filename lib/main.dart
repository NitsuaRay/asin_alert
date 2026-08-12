import 'package:asin_alert/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load environment variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase Backend
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    publishableKey: dotenv.get('SUPABASE_PUBLISHABLE_KEY'),
  );

  // 3. Initialize Firebase Cloud Messaging & Core Services
  await Firebase.initializeApp();
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