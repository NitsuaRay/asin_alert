import 'package:asin_alert/services/admin_service.dart';
import 'package:flutter/material.dart';

class SafetyAndIncidentsTab extends StatefulWidget {
  const SafetyAndIncidentsTab({super.key});

  @override
  State<SafetyAndIncidentsTab> createState() => _SafetyAndIncidentsTabState();
}

class _SafetyAndIncidentsTabState extends State<SafetyAndIncidentsTab> {
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'all'; // 'all', 'emergencies', 'incidents'

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Activity', Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'emergencies',
                  'Emergency Alerts',
                  Icons.warning_amber_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'incidents',
                  'Incident Logs',
                  Icons.receipt_long_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Feed
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getEmergenciesStream(),
              builder: (context, emergencySnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _adminService.getIncidentsStream(),
                  builder: (context, incidentSnapshot) {
                    if (emergencySnapshot.connectionState ==
                            ConnectionState.waiting ||
                        incidentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final emergencies = (emergencySnapshot.data ?? []).map((e) {
                      final item = Map<String, dynamic>.from(e);
                      item['record_type'] = 'emergency';
                      return item;
                    }).toList();

                    final incidents = (incidentSnapshot.data ?? []).map((i) {
                      final item = Map<String, dynamic>.from(i);
                      item['record_type'] = 'incident';
                      return item;
                    }).toList();

                    // Combine & filter
                    List<Map<String, dynamic>> combined = [];
                    if (_selectedFilter == 'all') {
                      combined = [...emergencies, ...incidents];
                    } else if (_selectedFilter == 'emergencies') {
                      combined = emergencies;
                    } else {
                      combined = incidents;
                    }

                    // Sort combined list by date descending
                    combined.sort((a, b) {
                      final dateA = DateTime.tryParse(
                            a['created_at']?.toString() ?? '',
                          ) ??
                          DateTime(1970);
                      final dateB = DateTime.tryParse(
                            b['created_at']?.toString() ?? '',
                          ) ??
                          DateTime(1970);
                      return dateB.compareTo(dateA);
                    });

                    if (combined.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No records found for this category',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: combined.length,
                      itemBuilder: (context, index) {
                        final item = combined[index];
                        final isEmergency =
                            item['record_type'] == 'emergency';
                        final isResolved = item['status'] == 'resolved';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEmergency
                                  ? (isResolved
                                      ? Colors.grey.shade300
                                      : Colors.red.shade300)
                                  : Colors.grey.shade200,
                              width: isEmergency && !isResolved ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isEmergency
                                      ? (isResolved
                                          ? Colors.grey.shade100
                                          : Colors.red.shade50)
                                      : const Color(0xFFEFF6FF),
                                  child: Icon(
                                    isEmergency
                                        ? Icons.warning_amber_rounded
                                        : Icons.receipt_long_rounded,
                                    color: isEmergency
                                        ? (isResolved
                                            ? Colors.grey
                                            : Colors.red)
                                        : const Color(0xFF1E40AF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isEmergency
                                                  ? (item['category']?.toString().toUpperCase() ??
                                                      'EMERGENCY ALERT')
                                                  : (item['remarks'] ??
                                                      'STATUS: ${item['new_status']?.toString().toUpperCase()}'),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildBadge(
                                            label: isEmergency
                                                ? (item['status']?.toString().toUpperCase() ?? 'EMERGENCY')
                                                : 'LOGGED',
                                            color: isEmergency
                                                ? (isResolved ? Colors.grey : Colors.red)
                                                : Colors.blue,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (isEmergency) ...[
                                        Text(
                                          'Notes: ${item['notes'] ?? 'No additional notes'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ] else ...[
                                        // Display status change transition from incident_logs
                                        Text(
                                          'Transition: ${item['previous_status'] ?? 'NEW'} ➔ ${item['new_status'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Action by: ${item['action_by'] ?? 'System'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        'Time: ${item['created_at'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isEmergency && !isResolved) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      await _adminService
                                          .resolveEmergency(item['id']);
                                    },
                                    child: const Text(
                                      'Resolve',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }

  Widget _buildBadge({required String label, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}