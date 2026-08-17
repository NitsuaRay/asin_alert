import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const EmergencyCard({super.key, required this.alert});

  /// Helper to determine category icon, label, and accent color
  Map<String, dynamic> _getCategoryStyle(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case 'fire':
        return {
          'label': 'FIRE DEPT',
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.deepOrange.shade700,
          'bgColor': Colors.deepOrange.shade50,
        };
      case 'medical':
        return {
          'label': 'MEDICAL',
          'icon': Icons.medical_services_rounded,
          'color': Colors.red.shade700,
          'bgColor': Colors.red.shade50,
        };
      case 'crime':
      case 'security_hostage':
        return {
          'label': 'CRIME / THREAT',
          'icon': Icons.security_rounded,
          'color': Colors.purple.shade800,
          'bgColor': Colors.purple.shade50,
        };
      case 'police':
        return {
          'label': 'POLICE',
          'icon': Icons.local_police_rounded,
          'color': Colors.blue.shade800,
          'bgColor': Colors.blue.shade50,
        };
      default:
        return {
          'label': categoryStr.toUpperCase(),
          'icon': Icons.warning_rounded,
          'color': Colors.grey.shade800,
          'bgColor': Colors.grey.shade100,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = alert['status'] ?? 'pending';
    final String rawCategory = (alert['category'] ?? 'police').toString();
    final double lat = (alert['latitude'] as num).toDouble();
    final double lng = (alert['longitude'] as num).toDouble();
    final String notes = alert['notes'] ?? '';

    // Robust silent flag detection
    final bool isSilent = alert['is_silent'] == true ||
        alert['is_silent'] == 'true' ||
        notes.contains('SILENT');

    final catStyle = _getCategoryStyle(rawCategory);
    final Color catColor = catStyle['color'] as Color;
    final Color catBgColor = catStyle['bgColor'] as Color;

    Color statusColor = Colors.red.shade700;
    if (status == 'acknowledged') statusColor = Colors.orange.shade800;
    if (status == 'en_route') statusColor = Colors.blue.shade800;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Top Status Pill & Silent Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Silent Alarm Badge
                if (isSilent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade300),
                    ),
                    child: Row(
                      children: const [
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

            const SizedBox(height: 14),

            // 🚨 Category Badge Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: catBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: catColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(catStyle['icon'] as IconData, size: 20, color: catColor),
                  const SizedBox(width: 8),
                  Text(
                    'CATEGORY: ${catStyle['label']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 📍 Coordinates Display
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  'Coordinates: $lat, $lng',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // 📝 Notes Display
            if (notes.isNotEmpty && !isSilent) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Notes: $notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],

            const Divider(height: 24),

            // 🔘 Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PoliceService.openMapDirections(lat, lng),
                    icon: const Icon(Icons.directions),
                    label: const Text('MAPS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildActionButton(alert['id'], status)),
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
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'acknowledged');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
        ),
        child: const Text(
          'ACKNOWLEDGE',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    } else if (currentStatus == 'acknowledged') {
      return ElevatedButton(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'en_route');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
        ),
        child: const Text(
          'EN ROUTE',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(alertId, 'resolved');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
        ),
        child: const Text(
          'RESOLVE',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }
  }
}