import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onTap;

  // ASIN Alert Palette
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  const EmergencyCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  /// Helper to determine category icon, label, and accent color
  Map<String, dynamic> _getCategoryStyle(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case 'fire':
        return {
          'label': 'FIRE DEPT',
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.deepOrange.shade800,
          'bgColor': Colors.deepOrange.shade50,
        };
      case 'medical':
        return {
          'label': 'MEDICAL',
          'icon': Icons.medical_services_rounded,
          'color': Colors.red.shade800,
          'bgColor': Colors.red.shade50,
        };
      case 'crime':
      case 'security_hostage':
        return {
          'label': 'CRIME / THREAT',
          'icon': Icons.security_rounded,
          'color': Colors.purple.shade900,
          'bgColor': Colors.purple.shade50,
        };
      case 'police':
        return {
          'label': 'POLICE',
          'icon': Icons.local_police_rounded,
          'color': primaryNavy,
          'bgColor': const Color(0xFFF1F5F9),
        };
      default:
        return {
          'label': categoryStr.toUpperCase(),
          'icon': Icons.warning_rounded,
          'color': const Color(0xFF475569),
          'bgColor': const Color(0xFFF1F5F9),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final String alertId = alert['id']?.toString() ?? '';
    final String status = alert['status'] ?? 'pending';
    final String rawCategory = (alert['category'] ?? 'police').toString();
    
    final double lat = alert['latitude'] is num 
        ? (alert['latitude'] as num).toDouble() 
        : double.tryParse(alert['latitude']?.toString() ?? '0.0') ?? 0.0;
        
    final double lng = alert['longitude'] is num 
        ? (alert['longitude'] as num).toDouble() 
        : double.tryParse(alert['longitude']?.toString() ?? '0.0') ?? 0.0;
        
    final String notes = alert['notes'] ?? '';

    // Robust silent flag detection
    final bool isSilent = alert['is_silent'] == true ||
        alert['is_silent'] == 'true' ||
        notes.toUpperCase().contains('SILENT');

    final catStyle = _getCategoryStyle(rawCategory);
    final Color catColor = catStyle['color'] as Color;
    final Color catBgColor = catStyle['bgColor'] as Color;

    Color statusColor = Colors.red.shade700;
    String statusLabel = 'PENDING';

    if (status == 'acknowledged') {
      statusColor = accentGold;
      statusLabel = 'ACKNOWLEDGED';
    } else if (status == 'en_route') {
      statusColor = const Color(0xFF2563EB); // Royal Blue
      statusLabel = 'EN ROUTE';
    } else if (status == 'resolved') {
      statusColor = Colors.green.shade700;
      statusLabel = 'RESOLVED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: status == 'pending'
              ? Colors.red.shade300
              : const Color(0xFFE2E8F0),
          width: status == 'pending' ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔴 Status Vertical Accent Bar on the Left Edge
                Container(
                  width: 6,
                  color: statusColor,
                ),

                // Main Card Contents
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🏷️ Top Status Bar & Silent Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Modern Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Silent Alarm Badge
                            if (isSilent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.purple.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.volume_off_rounded,
                                      size: 14,
                                      color: Colors.purple.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SILENT ALARM',
                                      style: TextStyle(
                                        color: Colors.purple.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 🚨 Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: catBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catStyle['icon'] as IconData,
                                size: 18,
                                color: catColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CATEGORY: ${catStyle['label']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 📍 Coordinates Container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryNavy.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 16,
                                  color: primaryNavy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'INCIDENT LOCATION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '$lat, $lng',
                                      style: const TextStyle(
                                        color: primaryNavy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 📝 Notes Display Box
                        if (notes.isNotEmpty && !isSilent) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentGold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.sticky_note_2_rounded,
                                  size: 16,
                                  color: accentGold,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notes,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF78350F),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                        const SizedBox(height: 14),

                        // 🔘 Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    PoliceService.openMapDirections(lat, lng),
                                icon: const Icon(Icons.directions_rounded,
                                    size: 18),
                                label: const Text('DIRECTIONS'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryNavy,
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  side: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(alertId, status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String alertId, String currentStatus) {
    if (currentStatus == 'pending') {
      return ElevatedButton.icon(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(
            alertId: alertId,
            newStatus: 'acknowledged',
            previousStatus: currentStatus,
            remarks: 'Acknowledged emergency from list card.',
          );
        },
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text('ACKNOWLEDGE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: accentGold.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (currentStatus == 'acknowledged') {
      return ElevatedButton.icon(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(
            alertId: alertId,
            newStatus: 'en_route',
            previousStatus: currentStatus,
            remarks: 'Unit en route to the incident location.',
          );
        },
        icon: const Icon(Icons.alt_route_rounded, size: 18),
        label: const Text('EN ROUTE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () async {
          await EmergencyAlarmService.stopAlarm();
          await PoliceService.updateStatus(
            alertId: alertId,
            newStatus: 'resolved',
            previousStatus: currentStatus,
            remarks: 'Emergency marked resolved from list card.',
          );
        },
        icon: const Icon(Icons.verified_user_rounded, size: 18),
        label: const Text('RESOLVE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.green.shade700.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
  }
}