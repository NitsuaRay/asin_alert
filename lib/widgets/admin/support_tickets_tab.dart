import 'package:asin_alert/constants/tabs/ticket_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:asin_alert/services/chat_support_service.dart';
import 'package:intl/intl.dart';

class SupportTicketsTab extends StatefulWidget {
  const SupportTicketsTab({super.key});

  @override
  State<SupportTicketsTab> createState() => _SupportTicketsTabState();
}

class _SupportTicketsTabState extends State<SupportTicketsTab> {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color borderSlate = Color(0xFFE2E8F0);

  String _filterStatus = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Filter Status:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'ALL',
                          'OPEN',
                          'IN_PROGRESS',
                          'RESOLVED',
                          'CLOSED',
                        ].map((status) {
                          final isSelected = _filterStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : primaryNavy,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primaryNavy,
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (val) {
                                if (val) setState(() => _filterStatus = status);
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: borderSlate),

        // Tickets Stream List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ChatSupportService.streamAllTickets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryNavy),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading tickets: ${snapshot.error}'),
                );
              }

              var tickets = snapshot.data ?? [];

              if (_filterStatus != 'ALL') {
                tickets = tickets.where((t) {
                  final status = (t['status'] ?? '')
                      .toString()
                      .trim()
                      .toUpperCase();
                  return status == _filterStatus;
                }).toList();
              }
              if (tickets.isEmpty) {
                return const Center(
                  child: Text(
                    'No support tickets found.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return _buildAdminTicketCard(ticket);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminTicketCard(Map<String, dynamic> ticket) {
    final subject = ticket['subject']?.toString() ?? 'No Subject';
    final category = ticket['category']?.toString() ?? 'GENERAL';
    final status = ticket['status']?.toString().toUpperCase() ?? 'OPEN';
    final userId = ticket['user_id']?.toString() ?? 'Unknown User';
    final updatedAtStr = ticket['updated_at']?.toString();

    Color statusColor;
    switch (status) {
      case 'RESOLVED':
        statusColor = const Color(0xFF10B981);
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'CLOSED':
        statusColor = const Color(0xFF64748B);
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
    }

    String timeStr = '';
    if (updatedAtStr != null) {
      final dt = DateTime.tryParse(updatedAtStr)?.toLocal();
      if (dt != null) timeStr = DateFormat('MMM dd, hh:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketChatScreen(ticket: ticket),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Category: $category',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 2),
            Text(
              'User ID: ${userId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.mark_chat_unread_rounded,
          size: 18,
          color: Color(0xFF38BDF8),
        ),
      ),
    );
  }
}
