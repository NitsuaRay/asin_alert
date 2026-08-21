import 'package:flutter/material.dart';
import 'package:asin_alert/services/chat_support_service.dart';
import 'package:intl/intl.dart';

class TicketChatScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket['status']?.toString() ?? 'OPEN';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _status == 'CLOSED') return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ChatSupportService.sendMessage(
        ticketId: widget.ticket['id'].toString(),
        message: text,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _resolveTicket() async {
    try {
      await ChatSupportService.updateTicketStatus(widget.ticket['id'].toString(), 'RESOLVED');
      setState(() => _status = 'RESOLVED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket marked as resolved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ticket: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ChatSupportService.currentUserId;
    final subject = widget.ticket['subject']?.toString() ?? 'Support Inquiry';
    final category = widget.ticket['category']?.toString() ?? 'GENERAL';
    final isClosed = _status == 'RESOLVED' || _status == 'CLOSED';

    return Scaffold(
      backgroundColor: surfaceSlate,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Category: $category',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ],
        ),
        actions: [
          if (!isClosed)
            TextButton.icon(
              onPressed: _resolveTicket,
              icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
              label: const Text('Resolve', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (isClosed)
            Container(
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'This ticket is $_status. Re-open by sending a new inquiry.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatSupportService.streamTicketMessages(widget.ticket['id'].toString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryNavy));
                }

                final messages = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id']?.toString() == currentUserId;
                    return _buildChatBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          if (!isClosed) _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['message']?.toString() ?? '';
    final createdAtStr = msg['created_at']?.toString();

    String timeStr = '';
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr)?.toLocal();
      if (dt != null) timeStr = DateFormat('hh:mm a').format(dt);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryNavy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: borderSlate),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 13, color: isMe ? Colors.white : const Color(0xFF334155), height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderSlate)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: surfaceSlate,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: borderSlate),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: primaryNavy),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: primaryNavy,
                child: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}