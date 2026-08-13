import 'package:asin_alert/services/EmergencyAlarmService.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';


class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const EmergencyCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
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