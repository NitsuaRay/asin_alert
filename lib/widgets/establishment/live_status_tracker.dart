import 'package:flutter/material.dart';
import '../../screens/emergency_service.dart';
import 'status_header_card.dart';
import 'status_timeline.dart';

class LiveStatusTracker extends StatelessWidget {
  final String alertId;
  final Map<String, dynamic> initialAlert;
  final VoidCallback onAlertEnded;
  final Future<void> Function(String alertId) onCancelPressed;

  const LiveStatusTracker({
    super.key,
    required this.alertId,
    required this.initialAlert,
    required this.onAlertEnded,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: EmergencyService.streamAlertStatus(alertId),
      builder: (context, snapshot) {
        final alert = snapshot.data ?? initialAlert;
        final status = alert['status'] as String;

        if (status == 'resolved' || status == 'cancelled') {
          Future.microtask(() {
            onAlertEnded();
          });
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              StatusHeaderCard(status: status),
              const SizedBox(height: 30),
              StatusTimeline(currentStatus: status),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => onCancelPressed(alert['id']),
                icon: const Icon(Icons.cancel, color: Colors.white),
                label: const Text('CANCEL EMERGENCY ALERT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}