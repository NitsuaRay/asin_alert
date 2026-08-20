import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:asin_alert/services/ota_service.dart';
import 'package:asin_alert/widgets/logout_confirmation_dialog.dart';
import 'package:asin_alert/widgets/police/emergency_card.dart';
import 'package:asin_alert/widgets/police/emergency_detail_screen.dart';
import 'package:asin_alert/widgets/police/police_bottom_navigation_bar.dart'; // Import navbar
import 'package:asin_alert/widgets/police/police_history_screen.dart';
import 'package:asin_alert/widgets/police/police_settings_screen.dart';
import 'package:asin_alert/widgets/update_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/police_service.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  RealtimeChannel? _emergencySubscription;
  int _currentTabIndex = 0; // Tracks active tab index

  // Branded Color Palette
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    PoliceService.registerResponderToken();
    _listenForIncomingEmergencies();
    EmergencyAlarmService.stopAlarm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForOtaUpdates();
    });
  }

  Future<void> _checkForOtaUpdates() async {
    final updateInfo = await OtaService.checkForUpdate();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(
          currentVersion: updateInfo['currentVersion'],
          remoteVersion: updateInfo['remoteVersion'],
          downloadUrl: updateInfo['downloadUrl'],
          changelog: updateInfo['changelog'],
        ),
      );
    }
  }

  void _listenForIncomingEmergencies() {
    _emergencySubscription = Supabase.instance.client
        .channel('public:emergencies')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'emergencies',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final eventType = payload.eventType;

            if (eventType == PostgresChangeEvent.insert) {
              await NotificationService.showAlertNotification(
                RemoteMessage(
                  notification: RemoteNotification(
                    title: '🚨 EMERGENCY PANIC ALERT!',
                    body:
                        'New ${newRecord['category']?.toString().toUpperCase() ?? 'POLICE'} alert triggered! Tap to inspect.',
                  ),
                ),
              );

              await EmergencyAlarmService.startAlarm();
            } else if (eventType == PostgresChangeEvent.update) {
              final status = newRecord['status'] ?? 'updated';

              String title = '📢 Status Updated';
              String body = 'An emergency status was changed to $status.';

              if (status == 'acknowledged') {
                title = '👮 Alert Acknowledged';
                body = 'Responders acknowledged the emergency alert!';
                await EmergencyAlarmService.stopAlarm();
              } else if (status == 'en_route') {
                title = '🚔 Officers En Route';
                body = 'A police unit is now heading to the scene!';
                await EmergencyAlarmService.stopAlarm();
              } else if (status == 'resolved') {
                title = '✅ Emergency Resolved';
                body = 'The incident has been marked as resolved.';
                await EmergencyAlarmService.stopAlarm();
              } else if (status == 'cancelled') {
                title = '❌ Alert Cancelled';
                body = 'The establishment cancelled the emergency alert.';
                await EmergencyAlarmService.stopAlarm();
              }

              await NotificationService.showAlertNotification(
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset(
              'assets/asinLogo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shield_rounded, color: accentGold, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'ASIN Alert',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentGold, width: 0.8),
              ),
              child: const Text(
                'POLICE RESPONDER',
                style: TextStyle(
                  color: accentGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: () => LogoutConfirmationDialog.show(
              context,
              accountType: 'police responder',
            ),
          ),
        ],
      ),
      body: _buildSelectedTabBody(),
      bottomNavigationBar: PoliceBottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSelectedTabBody() {
    switch (_currentTabIndex) {
      case 1:
        return const PoliceHistoryScreen(); // 👈 Render History Screen Here
      case 2:
        return const PoliceSettingsScreen();
      case 0:
      default:
        return _buildDashboardBody();
    }
  }

  Widget _buildDashboardBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PoliceService.streamActiveEmergencies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryNavy),
          );
        }

        final emergencies = snapshot.data ?? [];

        final hasPendingAlerts = emergencies.any((e) {
          final status = e['status'] ?? 'pending';
          return status == 'pending';
        });

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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ALL CLEAR',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No active emergency alerts at this time.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emergencies.length,
          itemBuilder: (context, index) {
            final alertData = emergencies[index];

            return EmergencyCard(
              alert: alertData,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmergencyDetailScreen(alert: alertData),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
