import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream active or past emergency records ordered by creation date
  Stream<List<Map<String, dynamic>>> getEmergenciesStream() {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Stream incident log records ordered by creation date
  Stream<List<Map<String, dynamic>>> getIncidentsStream() {
    return _supabase
        .from('incident_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Mark an emergency alert as resolved
  Future<void> resolveEmergency(dynamic id) async {
    await _supabase
        .from('emergencies')
        .update({'status': 'resolved'})
        .eq('id', id);
  }

  // ===========================================================================
  // USER MANAGEMENT METHODS
  // ===========================================================================

  /// Stream user profiles ordered by creation date
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Approve pending user verification
  Future<void> approveUser(String userId) async {
    await _supabase
        .from('profiles')
        .update({'is_verified': true})
        .eq('id', userId);
  }

  /// Deny / Reject pending user
  Future<void> denyUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }

  /// Create a new user profile record
  Future<void> addUser(Map<String, dynamic> userData) async {
    await _supabase.from('profiles').insert(userData);
  }

  /// Update user profile details
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await _supabase.from('profiles').update(userData).eq('id', userId);
  }

  /// Delete user profile record
  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }
}