import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> alert;

  const EmergencyDetailScreen({super.key, required this.alert});

  // Palette constants
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);
  static const Color royalBlue = Color(0xFF2563EB);

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

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'claimed':
      case 'acknowledged':
        return {
          'label': 'CLAIMED',
          'color': accentGold,
          'bgColor': const Color(0xFFFFFBEB),
        };
      case 'en_route':
        return {
          'label': 'EN ROUTE',
          'color': royalBlue,
          'bgColor': const Color(0xFFEFF6FF),
        };
      case 'resolved':
        return {
          'label': 'RESOLVED',
          'color': Colors.green.shade700,
          'bgColor': Colors.green.shade50,
        };
      default:
        return {
          'label': 'PENDING',
          'color': Colors.red.shade700,
          'bgColor': Colors.red.shade50,
        };
    }
  }

  /// Custom Floating Feedback SnackBar
  void _showFeedbackSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatReadableDate(String dateStr) {
    if (dateStr.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();

      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour:$minute $period';

      // Show "Today at 3:45 PM" if it occurred today
      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        return 'Today at $timeStr';
      }

      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = monthNames[dateTime.month - 1];

      return '$month ${dateTime.day}, ${dateTime.year} • $timeStr';
    } catch (_) {
      return dateStr;
    }
  }

  /// Action: Claim Emergency
  Future<void> _claimEmergency(BuildContext context, String alertId) async {
    await EmergencyAlarmService.stopAlarm();

    // Extract responder ID from current user session or alert map
    final String responderId = alert['responder_id']?.toString() ?? '';

    bool success = await PoliceService.claimEmergency(alertId, responderId);

    if (context.mounted) {
      _showFeedbackSnackBar(
        context,
        message: success
            ? 'Emergency claimed successfully.'
            : 'Failed to claim emergency.',
        isError: !success,
      );
    }
  }

  /// Action: Confirm & Release Emergency
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
            const Text(
              'This will remove you as the assigned responder and place the alert back into the pending queue for other officers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
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

      _showFeedbackSnackBar(
        context,
        message: success
            ? 'Emergency released back to pending queue.'
            : 'Failed to release emergency.',
        isError: !success,
      );
    }
  }

  /// Action: Progress Emergency Status
  Future<void> _updateStatus(
    BuildContext context, {
    required String emergencyId,
    required String currentStatus,
    required String newStatus,
  }) async {
    await EmergencyAlarmService.stopAlarm();

    await PoliceService.updateStatus(
      alertId: emergencyId,
      newStatus: newStatus,
      previousStatus: currentStatus,
      remarks: null,
    );

    if (context.mounted) {
      _showFeedbackSnackBar(
        context,
        message:
            'Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}',
        isError: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String emergencyId = alert['id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'EMERGENCY DETAIL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: PoliceService.streamEmergency(emergencyId),
        builder: (context, snapshot) {
          final currentAlert = snapshot.hasData && snapshot.data!.isNotEmpty
              ? snapshot.data!
              : alert;

          final String rawStatus = (currentAlert['status'] ?? 'pending')
              .toString()
              .toLowerCase()
              .trim();
          final String category = (currentAlert['category'] ?? 'police')
              .toString();
          final String notes = currentAlert['notes'] ?? '';

          // Responder & Dispatch status checks
          final String? rawResponder = currentAlert['responder_id']
              ?.toString()
              .trim();
          final String? responderId =
              (rawResponder == null ||
                  rawResponder.isEmpty ||
                  rawResponder == 'null')
              ? null
              : rawResponder;

          final String? responderName = alert['responder_name']?.toString();

          final bool isMyDispatch = alert['is_my_dispatch'] == true;

          final profileObj =
              currentAlert['profiles'] ??
              currentAlert['profile'] ??
              currentAlert['establishment'];

          final String establishmentName =
              currentAlert['establishment_name'] ??
              (profileObj is Map
                  ? (profileObj['full_name'] ??
                        profileObj['establishment_name'])
                  : null) ??
              'Unknown Establishment';

          final String address =
              currentAlert['address'] ??
              (profileObj is Map ? profileObj['address'] : null) ??
              '';
          final String barangay =
              currentAlert['barangay'] ??
              (profileObj is Map ? profileObj['barangay'] : null) ??
              '';
          final String phone =
              currentAlert['phone_number'] ??
              currentAlert['phone'] ??
              (profileObj is Map
                  ? (profileObj['phone_number'] ?? profileObj['phone'])
                  : null) ??
              '';

          final String fullAddress = [
            if (address.isNotEmpty && address != 'No address provided') address,
            if (barangay.isNotEmpty && barangay != 'No barangay provided')
              'Brgy. $barangay',
            'Asingan, Pangasinan',
          ].join(', ');

          final double lat = currentAlert['latitude'] is num
              ? (currentAlert['latitude'] as num).toDouble()
              : double.tryParse(
                      currentAlert['latitude']?.toString() ?? '0.0',
                    ) ??
                    0.0;

          final double lng = currentAlert['longitude'] is num
              ? (currentAlert['longitude'] as num).toDouble()
              : double.tryParse(
                      currentAlert['longitude']?.toString() ?? '0.0',
                    ) ??
                    0.0;

          final bool isSilent =
              currentAlert['is_silent'] == true ||
              currentAlert['is_silent'] == 'true' ||
              notes.toUpperCase().contains('SILENT');

          final statusStyle = _getStatusStyle(rawStatus);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(
                        status: rawStatus,
                        category: category,
                        statusStyle: statusStyle,
                        isSilent: isSilent,
                        alertId: emergencyId,
                        responderId:
                            responderId, // Pass responder_id column from emergency data
                        responderName: responderName,
                        isMyDispatch: isMyDispatch,
                      ),
                      const SizedBox(height: 16),
                      _buildEstablishmentCard(
                        establishmentName: establishmentName,
                        contactNumber: phone,
                        fullAddress: fullAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildLocationCard(lat, lng),
                      const SizedBox(height: 16),
                      if (notes.isNotEmpty) ...[
                        _buildNotesCard(notes),
                        const SizedBox(height: 16),
                      ],
                      _buildTimelineSection(emergencyId),
                    ],
                  ),
                ),
              ),
              if (rawStatus != 'resolved')
                _buildBottomActionBar(
                  context,
                  emergencyId: emergencyId,
                  status: rawStatus,
                  responderId: responderId,
                  isMyDispatch: isMyDispatch,
                  lat: lat,
                  lng: lng,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required String status,
    required String category,
    required Map<String, dynamic> statusStyle,
    required bool isSilent,
    required String? responderId,
    required String? alertId,
    required String? responderName,
    bool isMyDispatch = false,
  }) {
    final categoryStyle = _getCategoryStyle(category);
    final statusColor = statusStyle['color'] as Color? ?? primaryNavy;
    final statusBg =
        statusStyle['bgColor'] as Color? ?? const Color(0xFFF1F5F9);
    final statusLabel = (statusStyle['label'] as String? ?? status)
        .toUpperCase();

    // Compute displayName once at top level with fallback options
    final displayName = (responderName != null && responderName.isNotEmpty)
        ? responderName
        : (isMyDispatch ? 'You' : 'Another Officer');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Status Badge & Optional Silent Alarm Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Silent Alarm Pill
              if (isSilent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.purple.shade200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_off_rounded,
                        size: 14,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 5),
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

          const SizedBox(height: 18),

          // Incident Category Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (categoryStyle['bgColor'] as Color? ??
                      const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  categoryStyle['icon'] as IconData? ?? Icons.warning_rounded,
                  size: 24,
                  color: categoryStyle['color'] as Color? ?? primaryNavy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INCIDENT CATEGORY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (categoryStyle['label'] as String? ?? category)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryNavy,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Responder Claim/Release Status Banner
          const SizedBox(height: 16),
          if (responderId != null && responderId.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMyDispatch
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMyDispatch
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.badge_rounded,
                    size: 18,
                    color: isMyDispatch ? royalBlue : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyDispatch
                              ? 'CLAIMED BY YOU'
                              : 'ASSIGNED RESPONDER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isMyDispatch
                                ? royalBlue
                                : const Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isMyDispatch ? royalBlue : primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: accentGold,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'UNCLAIMED — Ready for Dispatch',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEstablishmentCard({
    required String establishmentName,
    required String contactNumber,
    required String fullAddress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryNavy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
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
                      'ESTABLISHMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      establishmentName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (contactNumber.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHONE NUMBER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (fullAddress.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOCATION / ADDRESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(double lat, double lng) {
    // Formatted coordinate values (fallbacks to 6 decimal places for clean UI if non-zero)
    final String latStr = lat != 0.0 ? lat.toStringAsFixed(6) : 'N/A';
    final String lngStr = lng != 0.0 ? lng.toStringAsFixed(6) : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.near_me_rounded,
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
                      'GPS LOCATION DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Incident Coordinates',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Latitude & Longitude Separated Cards
          Row(
            children: [
              // Latitude Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LATITUDE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        latStr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Longitude Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LONGITUDE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        lngStr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Directions Button Action
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => PoliceService.openMapDirections(lat, lng),
              icon: const Icon(
                Icons.directions_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text('OPEN MAP DIRECTIONS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_rounded, size: 18, color: accentGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOTES / REMARKS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(String emergencyId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INCIDENT ACTIVITY LOGS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: PoliceService.streamIncidentLogs(emergencyId),
          builder: (context, snapshot) {
            // 1. Show Loading Animation while waiting for stream or before first data emit
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Loading activity logs...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Handle Stream Errors gracefully
            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Text(
                  'Unable to load activity logs.',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              );
            }

            final logs = snapshot.data ?? [];

            // 3. Show Empty State only after confirming data exists and length is 0
            if (logs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No activity logs recorded yet.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                final newStatus = (log['new_status'] ?? '').toString();
                final remarks = log['remarks'] ?? 'Status updated';
                final formattedDate = _formatReadableDate(
                  log['created_at']?.toString() ?? '',
                );

                final statusStyle = _getStatusStyle(newStatus);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 18,
                        color: statusStyle['color'] as Color? ?? primaryNavy,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remarks,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryNavy,
                              ),
                            ),
                            if (formattedDate.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (newStatus.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (statusStyle['color'] as Color).withValues(
                                alpha: .3,
                              ),
                            ),
                          ),
                          child: Text(
                            statusStyle['label'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: statusStyle['color'] as Color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context, {
    required String emergencyId,
    required String status,
    String? responderId,
    bool isMyDispatch = false,
    required double lat,
    required double lng,
  }) {
    // 1. UNCLAIMED STATE: Show Claim Button
    if (responderId == null || responderId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: royalBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.front_hand_rounded, color: Colors.white),
              label: const Text(
                'CLAIM EMERGENCY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => _claimEmergency(context, emergencyId),
            ),
          ),
        ),
      );
    }
    // 2. CLAIMED BY ANOTHER OFFICER
    if (!isMyDispatch) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'CLAIMED BY ANOTHER OFFICER',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. CLAIMED BY YOU: Show Status Progression & Release Options
    String actionLabel = 'ACKNOWLEDGE';
    Color actionColor = accentGold;
    String nextStatus = 'acknowledged';

    if (status == 'acknowledged') {
      actionLabel = 'SET EN ROUTE';
      actionColor = royalBlue;
      nextStatus = 'en_route';
    } else if (status == 'en_route') {
      actionLabel = 'MARK RESOLVED';
      actionColor = Colors.green.shade700;
      nextStatus = 'resolved';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Release Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRelease(context, emergencyId),
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text(
                    'RELEASE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(
                      color: Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Primary Status Action Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () => _updateStatus(
                    context,
                    emergencyId: emergencyId,
                    currentStatus: status,
                    newStatus: nextStatus,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
