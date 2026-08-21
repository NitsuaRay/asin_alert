import 'package:flutter/material.dart';
import 'package:asin_alert/services/emergency_service.dart';
import 'package:intl/intl.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatusFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';
  final Map<String, String> _responderNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Checks snapshot data for responder_ids and fetches missing names from `profiles`
  void _resolveResponderNames(List<Map<String, dynamic>> emergencies) {
    final missingIds = emergencies
        .map((e) => e['responder_id']?.toString())
        .where(
          (id) =>
              id != null && id.isNotEmpty && !_responderNames.containsKey(id),
        )
        .cast<String>()
        .toSet()
        .toList();

    if (missingIds.isNotEmpty) {
      EmergencyService.getResponderNames(missingIds).then((names) {
        if (mounted) {
          setState(() {
            _responderNames.addAll(names);
          });
        }
      });
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> rawList) {
    final query = _searchController.text.trim().toLowerCase();

    return rawList.where((item) {
      final category = item['category']?.toString().toLowerCase() ?? '';
      final status = item['status']?.toString().toLowerCase() ?? '';
      final notes = item['notes']?.toString().toLowerCase() ?? '';
      final reason = item['cancelled_reason']?.toString().toLowerCase() ?? '';

      // 1. Status Filter
      if (_selectedStatusFilter == 'RESOLVED' && status != 'resolved') {
        return false;
      }
      if (_selectedStatusFilter == 'CANCELLED' && status != 'cancelled') {
        return false;
      }

      // 2. Category Filter
      if (_selectedCategoryFilter != 'ALL' &&
          category != _selectedCategoryFilter.toLowerCase()) {
        return false;
      }

      // 3. Search Query Filter
      if (query.isNotEmpty) {
        final matchesCategory = category.contains(query);
        final matchesNotes = notes.contains(query);
        final matchesReason = reason.contains(query);
        return matchesCategory || matchesNotes || matchesReason;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSlate,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Emergency Logs & History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: EmergencyService.streamEmergencyHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryNavy),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          }

          final allHistory = snapshot.data ?? [];

          // Trigger background fetch for responder names from profiles table
          _resolveResponderNames(allHistory);

          final filteredHistory = _applyFilters(allHistory);
          final totalResolved = allHistory
              .where((e) => e['status'] == 'resolved')
              .length;
          final totalCancelled = allHistory
              .where((e) => e['status'] == 'cancelled')
              .length;

          return Column(
            children: [
              _buildSummaryCards(
                allHistory.length,
                totalResolved,
                totalCancelled,
              ),
              _buildSearchAndFilters(allHistory),
              Expanded(
                child: filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryCard(filteredHistory[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int resolved, int cancelled) {
    return Container(
      color: primaryNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildStatTile(
            'Total Logs',
            total.toString(),
            Colors.blue.shade100,
            Colors.white,
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            'Resolved',
            resolved.toString(),
            Colors.green.shade100,
            const Color(0xFF10B981),
          ),
          const SizedBox(width: 10),
          _buildStatTile(
            'Cancelled',
            cancelled.toString(),
            Colors.amber.shade100,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String title,
    String count,
    Color subtextColor,
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: subtextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(List<Map<String, dynamic>> history) {
    final categories = <String>{'ALL'};
    for (var item in history) {
      if (item['category'] != null) {
        categories.add(item['category'].toString().toUpperCase());
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: surfaceSlate,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: borderSlate),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryNavy, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'All Status',
                  'ALL',
                  _selectedStatusFilter,
                  (val) => setState(() => _selectedStatusFilter = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Resolved',
                  'RESOLVED',
                  _selectedStatusFilter,
                  (val) => setState(() => _selectedStatusFilter = val),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Cancelled',
                  'CANCELLED',
                  _selectedStatusFilter,
                  (val) => setState(() => _selectedStatusFilter = val),
                ),
                const SizedBox(width: 12),
                Container(height: 20, width: 1, color: borderSlate),
                const SizedBox(width: 12),
                ...categories.map((cat) {
                  final isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryFilter = cat),
                      selectedColor: primaryNavy.withValues(alpha: 0.1),
                      backgroundColor: surfaceSlate,
                      side: BorderSide(
                        color: isSelected ? primaryNavy : borderSlate,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? primaryNavy
                            : const Color(0xFF64748B),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelect,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryNavy : surfaceSlate,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryNavy : borderSlate),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final category = item['category']?.toString().toUpperCase() ?? 'EMERGENCY';
    final status = item['status']?.toString().toLowerCase() ?? '';
    final notes = item['notes']?.toString() ?? 'No details provided.';
    final cancelledReason = item['cancelled_reason']?.toString();

    // Extract responder_id and map it to full_name from cache
    final responderId = item['responder_id']?.toString();
    final responderName =
        responderId != null && _responderNames.containsKey(responderId)
        ? _responderNames[responderId]!
        : 'Assigned Responder';

    final isResolved = status == 'resolved';
    final badgeColor = isResolved
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),

          // Display Resolved By Banner with full_name
          if (isResolved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESOLVED BY',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          responderName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (cancelledReason != null && cancelledReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                'Reason: $cancelledReason',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],

          const SizedBox(height: 14),

          _buildTimeline(
            createdAt: item['created_at']?.toString(),
            acknowledgedAt: item['acknowledged_at']?.toString(),
            resolvedAt:
                item['resolved_at']?.toString() ??
                item['updated_at']?.toString(),
            isResolved: isResolved,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline({
    required String? createdAt,
    required String? acknowledgedAt,
    required String? resolvedAt,
    required bool isResolved,
  }) {
    final dateFormat = DateFormat('hh:mm a');
    
    String formatTime(String? dateStr) {
      if (dateStr == null) return '--:--';
      final dt = DateTime.tryParse(dateStr)?.toLocal();
      return dt != null ? dateFormat.format(dt) : '--:--';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStep('Pending', formatTime(createdAt), true),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
          _buildStep('Acknowledged', formatTime(acknowledgedAt), acknowledgedAt != null),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
          _buildStep(isResolved ? 'Resolved' : 'Cancelled', formatTime(resolvedAt), resolvedAt != null),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String time, bool active) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? primaryNavy : const Color(0xFF94A3B8),
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No emergency logs found.',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }
}
