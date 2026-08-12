import 'package:asin_alert/services/EmergencyAlarmService.dart';
import 'package:asin_alert/services/notification_service.dart';
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
    // 1. Register FCM token
    PoliceService.registerResponderToken();

    // 2. Listen to NEW incoming emergencies and trigger continuous siren!
    _listenForIncomingEmergencies();
  }

  void _listenForIncomingEmergencies() {
    _emergencySubscription = Supabase.instance.client
        .channel('public:emergencies')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'emergencies',
          callback: (payload) async {
            final newEmergency = payload.newRecord;

            // Trigger the High-Priority Siren Notification Banner
            await NotificationService.showSirenNotification(
              RemoteMessage(
                notification: RemoteNotification(
                  title: '🚨 EMERGENCY PANIC ALERT!',
                  body:
                      'New ${newEmergency['category']?.toString().toUpperCase() ?? 'POLICE'} alert triggered! Tap to inspect.',
                ),
              ),
            );

            // 🚨 START CONTINUOUS SIREN AUDIO & VIBRATION LOOP
            await EmergencyAlarmService.startAlarm();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _emergencySubscription?.unsubscribe();
    // 🛑 Ensure alarm stops when leaving screen
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

          // If there are pending alerts, ensure alarm is playing; otherwise stop alarm
          final hasPendingAlerts =
              emergencies.any((e) => (e['status'] ?? 'pending') == 'pending');

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
              final alert = emergencies[index];
              return _buildEmergencyCard(alert);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> alert) {
    final String status = alert['status'] ?? 'pending';
    final double lat = (alert['latitude'] as num).toDouble();
    final double lng = (alert['longitude'] as num).toDouble();
    final String notes = alert['notes'] ?? '';
    final bool isSilent = notes.contains('SILENT');

    Color statusColor = Colors.red;
    if (status == 'acknowledged') statusColor = Colors.orange.shade800;
    if (status == 'en_route') statusColor = Colors.blue.shade800;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isSilent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, size: 14, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'SILENT ALARM',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Category: ${alert['category'].toString().toUpperCase()}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Coordinates: $lat, $lng',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            if (notes.isNotEmpty && !isSilent) ...[
              const SizedBox(height: 8),
              Text('Notes: $notes',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        PoliceService.openMapDirections(lat, lng),
                    icon: const Icon(Icons.directions),
                    label: const Text('MAPS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(alert['id'], status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String alertId, String currentStatus) {
    if (currentStatus == 'pending') {
      return ElevatedButton(
        onPressed: () async {
          // 🛑 Stop siren & vibration immediately when acknowledged!
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'acknowledged');
        },
        style:
            ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
        child: const Text('ACKNOWLEDGE',
            style: TextStyle(color: Colors.white, fontSize: 11)),
      );
    } else if (currentStatus == 'acknowledged') {
      return ElevatedButton(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'en_route');
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
        child: const Text('EN ROUTE',
            style: TextStyle(color: Colors.white, fontSize: 11)),
      );
    } else {
      return ElevatedButton(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'resolved');
        },
        style:
            ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
        child: const Text('RESOLVE',
            style: TextStyle(color: Colors.white, fontSize: 11)),
      );
    }
  }
}