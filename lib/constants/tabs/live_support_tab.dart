import 'dart:async';
import 'package:asin_alert/constants/tabs/ticket_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:asin_alert/services/chat_support_service.dart';
import 'package:intl/intl.dart';

class LiveSupportTab extends StatefulWidget {
  const LiveSupportTab({super.key});

  @override
  State<LiveSupportTab> createState() => _LiveSupportTabState();
}

class _LiveSupportTabState extends State<LiveSupportTab> {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);

  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  int _previousMessageCount = -1;

  @override
  void initState() {
    super.initState();
    _listenForResponderReplies();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Listen for real-time support message updates across user tickets
  void _listenForResponderReplies() {
    final currentUserId = ChatSupportService.currentUserId;

    _messageSubscription = ChatSupportService.streamSupportMessages().listen((messages) {
      if (_previousMessageCount != -1 && messages.length > _previousMessageCount) {
        final latestMsg = messages.last;
        final senderId = latestMsg['sender_id']?.toString();

        // If the latest message is from a responder/admin (not the user)
        if (senderId != currentUserId) {
          _triggerResponderNotification(
            latestMsg['message']?.toString() ?? 'New reply received from support',
          );
        }
      }
      _previousMessageCount = messages.length;
    });
  }

  /// Display floating notification bar on top of the current screen
  void _triggerResponderNotification(String messageText) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: primaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Responder Replied',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    messageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewTicketSheet() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'GENERAL';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Support Inquiry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GENERAL', child: Text('General Question')),
                      DropdownMenuItem(value: 'EMERGENCY_APP', child: Text('Emergency App Issue')),
                      DropdownMenuItem(value: 'ACCOUNT', child: Text('Account & Profile')),
                      DropdownMenuItem(value: 'BUG', child: Text('Report a Bug')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject / Summary',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Describe your issue...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final subject = subjectController.text.trim();
                              final message = messageController.text.trim();
                              if (subject.isEmpty || message.isEmpty) return;

                              setModalState(() => isSubmitting = true);

                              try {
                                final ticketId = await ChatSupportService.createTicket(
                                  subject: subject,
                                  category: selectedCategory,
                                  initialMessage: message,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TicketChatScreen(ticket: {
                                        'id': ticketId,
                                        'subject': subject,
                                        'category': selectedCategory,
                                        'status': 'OPEN',
                                      }),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit ticket: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Start Support Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSlate,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTicketSheet,
        backgroundColor: primaryNavy,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatSupportService.streamUserTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryNavy));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _buildTicketCard(ticket);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final subject = ticket['subject']?.toString() ?? 'Inquiry';
    final category = ticket['category']?.toString() ?? 'GENERAL';
    final status = ticket['status']?.toString().toUpperCase() ?? 'OPEN';
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryNavy),
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
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Category: $category', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, size: 40, color: primaryNavy),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Support Tickets Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "+ New Ticket" below to start a conversation with system support.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}