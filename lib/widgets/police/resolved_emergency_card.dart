import 'package:flutter/material.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:asin_alert/widgets/police/incident_logs_modal.dart';

class ResolvedEmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color resolvedGreen = Color(0xFF16A34A);

  const ResolvedEmergencyCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String emergencyId = alert['id']?.toString() ?? '';
    // Extract payload data safely
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
    final String category = (alert['category'] ?? 'GENERAL')
        .toString()
        .toUpperCase();
    final String notes = alert['notes'] ?? '';
    final double lat = alert['latitude'] is num
        ? (alert['latitude'] as num).toDouble()
        : double.tryParse(alert['latitude']?.toString() ?? '0.0') ?? 0.0;

    final double lng = alert['longitude'] is num
        ? (alert['longitude'] as num).toDouble()
        : double.tryParse(alert['longitude']?.toString() ?? '0.0') ?? 0.0;

    final String resolvedAt = alert['resolved_at'] ?? alert['created_at'] ?? '';

    // Category Styling Helper
    final Map<String, dynamic> catStyle = _getCategoryStyle(category);
    final Color catColor = catStyle['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          splashColor: primaryNavy.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Top Header: Resolved Badge + Category Pill
                Row(
                  children: [
                    // Resolved Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: resolvedGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: resolvedGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: resolvedGreen,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'RESOLVED',
                            style: TextStyle(
                              color: resolvedGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: catColor.withValues(alpha: 0.25),
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
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 🏢 Establishment Avatar Icon + Name + Physical Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Icon Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryNavy.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 22,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name & Address Column
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 12),

                // 🌐 Coordinates & Resolved Date Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$lat, $lng',
                        style: const TextStyle(
                          color: primaryNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (resolvedAt.isNotEmpty) ...[
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(resolvedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 📝 Incident Notes Display Box
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 14,
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
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 🔘 Action Button Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            PoliceService.openMapDirections(lat, lng),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('DIRECTIONS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryNavy,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (emergencyId.isNotEmpty) {
                            IncidentLogsModal.show(
                              context,
                              emergencyId: emergencyId,
                              establishmentName: establishmentName,
                            );
                          }
                        },
                        icon: const Icon(Icons.history_rounded, size: 15),
                        label: const Text('VIEW LOGS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Visual categorization styling helper
  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'FIRE':
        return {
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.orange.shade700,
        };
      case 'MEDICAL':
        return {
          'icon': Icons.medical_services_rounded,
          'color': Colors.red.shade600,
        };
      case 'CRIME':
      case 'SECURITY':
        return {
          'icon': Icons.security_rounded,
          'color': Colors.indigo.shade600,
        };
      default:
        return {
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFF0F172A),
        };
    }
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }
}
