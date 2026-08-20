import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback? onTap;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  const EmergencyCard({super.key, required this.alert, this.onTap});

  Map<String, dynamic> _getCategoryStyle(String categoryStr) {
    switch (categoryStr.trim().toLowerCase()) {
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
          'label': 'THREAT',
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

  Future<void> _confirmRelease(BuildContext context, String alertId) async {
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Icon(
                    Icons.assignment_return_rounded,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Release Emergency?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ACTION REQUIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentGold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message body
            Text(
              'This will remove you as the assigned responder and place the alert back into the pending queue for other officers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: primaryNavy,
                      backgroundColor: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: const Text('RELEASE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      bool success = await PoliceService.releaseEmergency(alertId);
      if (!context.mounted) return;

      final bool isError = !success;
      final String message = success
          ? 'Emergency released back to pending queue.'
          : 'Failed to release emergency.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: isError ? Colors.white : accentGold,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade700 : primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String alertId = alert['id']?.toString() ?? '';
    final String status = alert['status'] ?? 'pending';
    final String rawCategory = (alert['category'] ?? 'police').toString();
    final String? responderId = alert['responder_id']?.toString();
    final String? responderName = alert['responder_name']?.toString();
    final bool isMyDispatch = alert['is_my_dispatch'] == true;

    final String establishmentName =
        alert['establishment_name'] ?? 'Unknown Establishment';
    final String address = alert['address'] ?? 'No address provided';
    final String barangay = alert['barangay'] ?? 'No barangay provided';

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
    final bool isSilent =
        alert['is_silent'] == true ||
        alert['is_silent'] == 'true' ||
        notes.toUpperCase().contains('SILENT');

    // 4. Strict Pending/Unclaimed Check
    final bool isPendingOrUnclaimed =
        status == 'pending' || responderId == null;

    final catStyle = _getCategoryStyle(rawCategory);
    final Color catColor = catStyle['color'] as Color;
    final Color catBgColor = catStyle['bgColor'] as Color;

    Color statusColor = Colors.red.shade700;
    String statusLabel = 'PENDING';

    if (status == 'claimed' || responderId != null) {
      statusColor = Colors.orange.shade800;
      statusLabel = 'CLAIMED';
    }
    if (status == 'en_route') {
      statusColor = const Color(0xFF2563EB);
      statusLabel = 'EN ROUTE';
    } else if (status == 'resolved') {
      statusColor = Colors.green.shade700;
      statusLabel = 'RESOLVED';
    }

    if (isPendingOrUnclaimed ) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        EmergencyAlarmService.startAlarm();
      });
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
          color: status == 'pending' && responderId == null
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Category Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                            if (isMyDispatch && status != 'resolved') ...[
                              const SizedBox(width: 6),
                              // RELEASE BUTTON
                              IconButton.outlined(
                                onPressed: () =>
                                    _confirmRelease(context, alertId),
                                icon: Icon(
                                  Icons.assignment_return_rounded,
                                  size: 15,
                                  color: Colors.red.shade700,
                                ),
                                tooltip: 'Release Emergency',
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade200),
                                  padding: const EdgeInsets.all(5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
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

                        // Establishment Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                Icons.storefront_rounded,
                                size: 20,
                                color: primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 12),
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

                        // GPS Box
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

                        // Action Controls based on claiming state
                        _buildActionSection(
                          context,
                          alertId: alertId,
                          status: status,
                          responderId: responderId,
                          responderName: responderName,
                          isMyDispatch: isMyDispatch,
                          lat: lat,
                          lng: lng,
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

  Widget _buildActionSection(
    BuildContext context, {
    required String alertId,
    required String status,
    required String? responderId,
    required String? responderName,
    required bool isMyDispatch,
    required double lat,
    required double lng,
  }) {
    // 1. Unclaimed State
    if (responderId == null || responderId.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            await EmergencyAlarmService.stopAlarm();

            bool claimed = await PoliceService.claimEmergency(
              alertId,
              'Claimed by responder', // Added second positional argument
            );

            if (!context.mounted) return;

            if (claimed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency claimed! You are assigned.'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Another responder has already claimed this emergency.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.touch_app_rounded, size: 18),
          label: const Text('CLAIM & RESPOND'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 13),
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
      );
    }

    // 2. Claimed by Another Officer
    if (!isMyDispatch) {
      final name = responderName ?? 'another officer';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_pin_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Handled by $name',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Claimed by Current Officer (is_my_dispatch == true)
    if (status == 'resolved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'RESOLVED',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => PoliceService.openMapDirections(lat, lng),
                icon: const Icon(Icons.near_me_rounded, size: 16),
                label: const Text('NAVIGATE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: status == 'en_route'
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        await PoliceService.updateStatus(
                          alertId: alertId,
                          newStatus: 'resolved',
                          previousStatus: status,
                          remarks: 'Emergency resolved.',
                        );
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 16),
                      label: const Text('RESOLVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () async {
                        await PoliceService.updateStatus(
                          alertId: alertId,
                          newStatus: 'en_route',
                          previousStatus: status,
                          remarks: 'En route to location.',
                        );
                      },
                      icon: const Icon(Icons.alt_route_rounded, size: 16),
                      label: const Text('EN ROUTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
