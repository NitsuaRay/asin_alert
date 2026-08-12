import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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

            if (role == 'police') {
              return const PoliceDashboardScreen();
            } else {
              return const EstablishmentDashboardScreen();
            }
          },
        );
      },
    );
  }
}

// Temporary Placeholder screens until built
class EstablishmentDashboardScreen extends StatelessWidget {
  const EstablishmentDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Establishment Panic View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: const Center(child: Text('Establishment Panic Button Dashboard')),
    );
  }
}

class PoliceDashboardScreen extends StatelessWidget {
  const PoliceDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PNP Asingan Station Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: const Center(child: Text('Police Realtime Incident Stream Dashboard')),
    );
  }
}