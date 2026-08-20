import 'package:flutter/material.dart';
import 'package:asin_alert/services/police_service.dart';

class IncidentLogsModal extends StatelessWidget {
  final String emergencyId;
  final String establishmentName;

  static const Color primaryNavy = Color(0xFF0F172A);

  const IncidentLogsModal({
    super.key,
    required this.emergencyId,
    required this.establishmentName,
  });

  static void show(
    BuildContext context, {
    required String emergencyId,
    required String establishmentName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentLogsModal(
        emergencyId: emergencyId,
        establishmentName: establishmentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle bar
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: primaryNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INCIDENT TIMELINE & LOGS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        establishmentName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // 📜 Incident Logs Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PoliceService.streamIncidentLogs(emergencyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState('Fetching incident logs...');
                }

                if (snapshot.hasError) {
                  return _buildLoadingState(
                    'Waiting to fetch incident logs...',
                  );
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isLast = index == logs.length - 1;

                    return _buildTimelineItem(log: log, isLast: isLast);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Map<String, dynamic> log,
    required bool isLast,
  }) {
    // Schema field mappings
    final String newStatus = (log['new_status'] ?? log['status'] ?? 'UPDATE')
        .toString()
        .toUpperCase();
    final String previousStatus = (log['previous_status'] ?? '')
        .toString()
        .toUpperCase();
    final String remarks = log['remarks'] ?? log['details'] ?? '';
    final String timestamp = log['created_at'] ?? '';

    // Extracted enriched profile data from stream
    final String actionByName = (log['action_by_name'] ?? '').toString().trim();
    final String actionByRole = (log['action_by_role'] ?? '')
        .toString()
        .toLowerCase();

    // Determine actor type (Establishment vs Police) based on role or state
    final bool isEstablishment =
        actionByRole == 'establishment' || newStatus == 'PENDING';
    final String actorLabel = isEstablishment
        ? 'Triggered By: '
        : 'Responder: ';
    final IconData actorIcon = isEstablishment
        ? Icons.storefront_rounded
        : Icons.badge_outlined;

    // Fallback logic if actionByName is empty
    String responderName = actionByName.isNotEmpty
        ? actionByName
        : (isEstablishment
              ? (establishmentName.isNotEmpty
                    ? establishmentName
                    : 'Establishment')
              : 'Police Officer');

    final Map<String, dynamic> statusConfig = _getStatusConfig(newStatus);
    final Color themeColor = statusConfig['color'] as Color;
    final IconData statusIcon = statusConfig['icon'] as IconData;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line & node icon
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(statusIcon, size: 12, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFE2E8F0)),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Log Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge & Full Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            newStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Formatted Date & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: primaryNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _formatDate(timestamp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Status transition flow (Previous -> New)
                    if (previousStatus.isNotEmpty &&
                        previousStatus != newStatus) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            previousStatus,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            newStatus,
                            style: TextStyle(
                              fontSize: 10,
                              color: themeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Dynamic Actor / Action By Badge
                    Row(
                      children: [
                        Icon(
                          actorIcon,
                          size: 13,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          actorLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            responderName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: primaryNavy,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Remarks / Notes Box
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          remarks,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.article_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 10),
          Text(
            'NO LOGS FOUND',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No logged activity for this incident.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: primaryNavy,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic colors and icons per emergency status
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'ACKNOWLEDGED':
        return {
          'color': const Color(0xFFD97706), // Amber
          'icon': Icons.thumb_up_alt_rounded,
        };
      case 'ENROUTE':
      case 'EN_ROUTE':
      case 'DISPATCHED':
        return {
          'color': const Color(0xFF2563EB), // Blue
          'icon': Icons.directions_car_rounded,
        };
      case 'ON_SCENE':
      case 'ARRIVED':
        return {
          'color': const Color(0xFF7C3AED), // Purple
          'icon': Icons.location_on_rounded,
        };
      case 'RESOLVED':
        return {
          'color': const Color(0xFF16A34A), // Green
          'icon': Icons.check_circle_rounded,
        };
      case 'CANCELLED':
      case 'CANCELED':
        return {
          'color': const Color(0xFFDC2626), // Red
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'color': const Color(0xFF0F172A), // Primary Navy
          'icon': Icons.info_rounded,
        };
    }
  }

  // 🕒 12-Hour Time Formatter (e.g., 02:30 PM)
  String _formatTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minuteStr $amPm';
    } catch (_) {
      return rawDate;
    }
  }

  // 📅 Date Formatter (e.g., 08/20/2026)
  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final monthStr = dt.month.toString().padLeft(2, '0');
      final dayStr = dt.day.toString().padLeft(2, '0');
      return '$monthStr/$dayStr/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
