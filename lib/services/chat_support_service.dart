import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSupportService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Create a new support ticket and send the initial inquiry message
  static Future<String> createTicket({
    required String subject,
    required String category,
    required String initialMessage,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Insert new support ticket
    final ticketResponse = await _supabase
        .from('support_tickets')
        .insert({
          'user_id': userId,
          'subject': subject.trim(),
          'category': category,
          'status': 'OPEN',
        })
        .select('id')
        .single();

    final ticketId = ticketResponse['id'].toString();

    // 2. Insert initial message into thread
    await sendMessage(ticketId: ticketId, message: initialMessage);

    return ticketId;
  }

  /// Send a message within a specific ticket thread
  static Future<void> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('support_messages').insert({
      'ticket_id': ticketId,
      'sender_id': userId,
      'message': message.trim(),
      'is_read': false,
    });

    // Update ticket's updated_at timestamp
    await _supabase
        .from('support_tickets')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  static Stream<List<Map<String, dynamic>>> streamSupportMessages() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  /// Realtime Stream of all tickets for current user
  static Stream<List<Map<String, dynamic>>> streamUserTickets() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
  }

  /// Stream messages for a specific ticket ID
  static Stream<List<Map<String, dynamic>>> streamTicketMessages(
    String ticketId,
  ) {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
  }

  /// Close or Resolve a ticket
  static Future<void> updateTicketStatus(String ticketId, String status) async {
    await _supabase
        .from('support_tickets')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  /// Stream all support tickets across all users (For Admin Dashboard)
  static Stream<List<Map<String, dynamic>>> streamAllTickets() {
    return _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false);
  }

  /// Admin reply to a specific ticket
  static Future<void> sendAdminReply({
    required String ticketId,
    required String message,
  }) async {
    final adminId = currentUserId;
    if (adminId == null) throw Exception('Admin not authenticated');

    await _supabase.from('support_messages').insert({
      'ticket_id': ticketId,
      'sender_id': adminId,
      'message': message.trim(),
      'is_read': false,
    });

    // Automatically update ticket status to IN_PROGRESS on reply
    await _supabase
        .from('support_tickets')
        .update({
          'status': 'IN_PROGRESS',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }
}
