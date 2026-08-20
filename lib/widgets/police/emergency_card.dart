import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onTap;

  // ASIN Alert Palette
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  const EmergencyCard({super.key, required this.alert, this.onTap});

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

    // 🏬 Establishment Name & Address
    final String establishmentName =
        alert['establishment_name'] ?? 'Unknown Establishment';
    final String address = alert['address'] ?? 'No address provided';
    final String barangay = alert['barangay'] ?? 'No barangay provided';

    // Build formatted full address with Barangay, Asingan, Pangasinan
    final String fullAddress = [
      address,
      if (barangay.isNotEmpty) 'Brgy. $barangay',
      'Asingan, Pangasinan',
    ].where((part) => part.trim().isNotEmpty).join(', ');

    final double lat = alert['latitude'] is num
        ? (alert['latitude'] as num).toDouble()
        : double.tryParse(alert['latitude']?.toString() ?? '0.0') ?? 0.0;

    final double lng = alert['longitude'] is num
        ? (alert['longitude'] as num).toDouble()
        : double.tryParse(alert['longitude']?.toString() ?? '0.0') ?? 0.0;

    final String notes = alert['notes'] ?? '';

    // Robust silent flag detection
    final bool isSilent =
        alert['is_silent'] == true ||
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: status == 'pending'
              ? Colors.red.shade200
              : const Color(0xFFEDF2F7),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          splashColor: primaryNavy.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔴 Status Vertical Bar (Slightly thicker & rounded accent edge)
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // Main Card Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🏷️ Top Header: Status + Category Pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Silent Indicator
                            if (isSilent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF5FF),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFFE9D5FF),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.volume_off_rounded,
                                      size: 11,
                                      color: Color(0xFF7E22CE),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'SILENT',
                                      style: TextStyle(
                                        color: Color(0xFF6B21A8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),

                            // Category Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: catBgColor,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: catColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    catStyle['icon'] as IconData,
                                    size: 12,
                                    color: catColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${catStyle['label']}'.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: catColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        // 🏢 Establishment Name & Location Block
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Establishment Icon Badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryNavy.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryNavy.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .storefront_rounded, // Or Icons.business_rounded / Icons.domain_rounded
                                size: 20,
                                color: primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name + Address Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    establishmentName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: primaryNavy,
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          fullAddress,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // 🌐 GPS Coordinates Section (Subtle Card Tile)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryNavy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 14,
                                  color: primaryNavy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GPS COORDINATES',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF94A3B8),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '$lat, $lng',
                                      style: const TextStyle(
                                        color: primaryNavy,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
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
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.sticky_note_2_rounded,
                                  size: 15,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notes,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF92400E),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // 🔘 Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    PoliceService.openMapDirections(lat, lng),
                                icon: const Icon(
                                  Icons.directions_rounded,
                                  size: 16,
                                ),
                                label: const Text('DIRECTIONS'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryNavy,
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
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
