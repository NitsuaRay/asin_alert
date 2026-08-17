import 'package:asin_alert/screens/admin_dashboard_screen.dart';
import 'package:asin_alert/screens/police_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'establishment_dashboard_screen.dart'; // Import actual establishment screen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // User is NOT logged in -> Show Login Screen
        if (session == null) {
          return const LoginScreen();
        }

        // User IS logged in -> Determine Role & Direct to Screen
        return FutureBuilder<Map<String, dynamic>?>(
          future: AuthService().getUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            final role = profile?['role'] ?? 'establishment';

            if (role == 'admin') {
              return const AdminDashboardScreen();
            } else if (role == 'police') {
              return const PoliceDashboardScreen();
            } else {
              return const EstablishmentDashboardScreen(); // Linked active screen
            }
          },
        );
      },
    );
  }

}