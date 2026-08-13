import 'package:asin_alert/services/EmergencyAlarmService.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:asin_alert/widgets/police/emergency_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/police_service.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  RealtimeChannel? _emergencySubscription;

  @override
  void initState() {
    super.initState();
    PoliceService.registerResponderToken();
    _listenForIncomingEmergencies();
  }

  void _listenForIncomingEmergencies() {
    _emergencySubscription = Supabase.instance.client
        .channel('public:emergencies')
        .onPostgresChanges(
          event: PostgresChangeEvent
              .all, // 👈 Listens to INSERT, UPDATE, and DELETE
          schema: 'public',
          table: 'emergencies',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final eventType = payload.eventType;

            // 1. New Emergency Alert Inserted
            if (eventType == PostgresChangeEvent.insert) {
              await NotificationService.showSirenNotification(
                RemoteMessage(
                  notification: RemoteNotification(
                    title: '🚨 EMERGENCY PANIC ALERT!',
                    body:
                        'New ${newRecord['category']?.toString().toUpperCase() ?? 'POLICE'} alert triggered! Tap to inspect.',
                  ),
                ),
              );

              await EmergencyAlarmService.startAlarm();
            }
            // 2. Existing Emergency Status Updated (Acknowledged / En Route / Resolved)
            else if (eventType == PostgresChangeEvent.update) {
              final status = newRecord['status'] ?? 'updated';

              String title = '📢 Status Updated';
              String body = 'An emergency status was changed to $status.';

              if (status == 'acknowledged') {
                title = '👮 Alert Acknowledged';
                body = 'Responders acknowledged the emergency alert!';
              } else if (status == 'en_route') {
                title = '🚔 Officers En Route';
                body = 'A police unit is now heading to the scene!';
              } else if (status == 'resolved') {
                title = '✅ Emergency Resolved';
                body = 'The incident has been marked as resolved.';
              }

              await NotificationService.showSirenNotification(
                RemoteMessage(
                  notification: RemoteNotification(title: title, body: body),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _emergencySubscription?.unsubscribe();
    EmergencyAlarmService.stopAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PNP Asingan Station Monitor'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              EmergencyAlarmService.stopAlarm();
              AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: PoliceService.streamActiveEmergencies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final emergencies = snapshot.data ?? [];

          final hasPendingAlerts = emergencies.any(
            (e) => (e['status'] ?? 'pending') == 'pending',
          );

          if (!hasPendingAlerts) {
            EmergencyAlarmService.stopAlarm();
          } else {
            EmergencyAlarmService.startAlarm();
          }

          if (emergencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, size: 80, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'ALL CLEAR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active emergency alerts at this time.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              return EmergencyCard(alert: emergencies[index]);
            },
          );
        },
      ),
    );
  }
}
