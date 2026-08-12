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

// Temporary Placeholder screens until built in next phases


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A.S.I.N. System Administration'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Admin Management & Verification Dashboard'),
      ),
    );
  }
}