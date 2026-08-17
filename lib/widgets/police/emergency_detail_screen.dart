import 'package:asin_alert/services/emergency_alarm_service.dart';
import 'package:asin_alert/services/police_service.dart';
import 'package:flutter/material.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final String emergencyId;

  const EmergencyDetailScreen({
    super.key,
    required this.emergencyId,
  });

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  // ASIN Alert Palette
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);
  static const Color royalBlue = Color(0xFF2563EB);

  /// Helper for dynamic status badge styling
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'acknowledged':
        return {
          'label': 'ACKNOWLEDGED',
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

  /// Directly updates status without showing a dialog
  Future<void> _updateStatus({
    required String currentStatus,
    required String newStatus,
  }) async {
    // Stop alarm sound if active
    await EmergencyAlarmService.stopAlarm();

    // Update Supabase Database
    await PoliceService.updateStatus(
      alertId: widget.emergencyId,
      newStatus: newStatus,
      previousStatus: currentStatus,
      remarks: null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: primaryNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        stream: PoliceService.streamEmergency(widget.emergencyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryNavy),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load emergency record.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('GO BACK'),
                  ),
                ],
              ),
            );
          }

          final alert = snapshot.data!;
          final String status = alert['status'] ?? 'pending';
          final String category = (alert['category'] ?? 'police').toString();
          final String notes = alert['notes'] ?? '';

          final double lat = alert['latitude'] is num
              ? (alert['latitude'] as num).toDouble()
              : double.tryParse(alert['latitude']?.toString() ?? '0.0') ?? 0.0;

          final double lng = alert['longitude'] is num
              ? (alert['longitude'] as num).toDouble()
              : double.tryParse(alert['longitude']?.toString() ?? '0.0') ?? 0.0;

          final bool isSilent = alert['is_silent'] == true ||
              alert['is_silent'] == 'true' ||
              notes.toUpperCase().contains('SILENT');

          final statusStyle = _getStatusStyle(status);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Status & Category Card
                      _buildHeaderCard(status, category, statusStyle, isSilent),

                      const SizedBox(height: 16),

                      // 2. Incident Location & Navigation Card
                      _buildLocationCard(lat, lng),

                      const SizedBox(height: 16),

                      // 3. User Notes Section (If present)
                      if (notes.isNotEmpty) ...[
                        _buildNotesCard(notes),
                        const SizedBox(height: 16),
                      ],

                      // 4. Incident Activity Timeline / Logs
                      _buildTimelineSection(),
                    ],
                  ),
                ),
              ),

              // 5. Bottom Action Bar
              if (status != 'resolved')
                _buildBottomActionBar(status, lat, lng),
            ],
          );
        },
      ),
    );
  }

  /// Header Status & Category Card
  Widget _buildHeaderCard(
    String status,
    String category,
    Map<String, dynamic> statusStyle,
    bool isSilent,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusStyle['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (statusStyle['color'] as Color).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: statusStyle['color'] as Color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusStyle['label'] as String,
                      style: TextStyle(
                        color: statusStyle['color'] as Color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSilent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_off_rounded,
                          size: 14, color: Colors.purple.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'SILENT ALARM',
                        style: TextStyle(
                          color: Colors.purple.shade900,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  /// Location Card with Directions Button
  Widget _buildLocationCard(double lat, double lng) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  Icons.my_location_rounded,
                  size: 18,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INCIDENT COORDINATES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lat, $lng',
                      style: const TextStyle(
                        color: primaryNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => PoliceService.openMapDirections(lat, lng),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('OPEN MAP DIRECTIONS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// User / System Notes Card
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

  /// Incident Activity Stream Timeline Log
  Widget _buildTimelineSection() {
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
          stream: PoliceService.streamIncidentLogs(widget.emergencyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final logs = snapshot.data ?? [];

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
                final createdAt = log['created_at']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded,
                          size: 18, color: primaryNavy),
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
                            if (createdAt.isNotEmpty)
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (newStatus.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            newStatus.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                            ),
                          ),
                        ),
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

  /// Sticky Action Bar at Screen Bottom
  Widget _buildBottomActionBar(String currentStatus, double lat, double lng) {
    String actionLabel = 'ACKNOWLEDGE';
    Color actionColor = accentGold;
    String nextStatus = 'acknowledged';

    if (currentStatus == 'acknowledged') {
      actionLabel = 'SET EN ROUTE';
      actionColor = royalBlue;
      nextStatus = 'en_route';
    } else if (currentStatus == 'en_route') {
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
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
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
              currentStatus: currentStatus,
              newStatus: nextStatus,
            ),
          ),
        ),
      ),
    );
  }
}