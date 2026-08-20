import 'package:asin_alert/screens/admin_dashboard_screen.dart';
import 'package:asin_alert/screens/police_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'establishment_dashboard_screen.dart';

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

            // If profile is null (session invalid/expired), route to Login
            if (profile == null) {
              return const LoginScreen();
            }

            final role = profile['role'];

            switch (role) {
              case 'admin':
                return const AdminDashboardScreen();
              case 'police':
                return const PoliceDashboardScreen();
              case 'establishment':
                return const EstablishmentDashboardScreen();
              default:
                return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
