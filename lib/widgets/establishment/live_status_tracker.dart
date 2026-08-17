import 'package:flutter/material.dart';
import '../../services/emergency_service.dart';
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

  static const Color primaryNavy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: EmergencyService.streamAlertStatus(alertId),
      builder: (context, snapshot) {
        final alert = snapshot.data ?? initialAlert;
        final status = alert['status'] as String;

        // Extract Category & Silent Mode Flag
        final category = (alert['category'] ?? 'police').toString();
        final bool isSilent =
            alert['is_silent'] == true || alert['is_silent'] == 'true';

        if (status == 'resolved' || status == 'cancelled') {
          Future.microtask(() {
            onAlertEnded();
          });
        }

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🚨 Status Header displaying Logo Watermark, Category & Silent status
                StatusHeaderCard(
                  status: status,
                  category: category,
                  isSilent: isSilent,
                ),

                const SizedBox(height: 24),

                // ⏳ Custom Vertical Timeline Tracker
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: StatusTimeline(currentStatus: status),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🛑 Emergency Cancel Action Button
                ElevatedButton.icon(
                  onPressed: () => onCancelPressed(alert['id']),
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'CANCEL EMERGENCY ALERT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}