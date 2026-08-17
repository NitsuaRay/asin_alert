import 'package:asin_alert/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Incident Broadcast: Captures GPS location & inserts row into 'emergencies' table
  static Future<Map<String, dynamic>> triggerEmergency({
    required String category,
    String? notes,
    bool isSilent = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final position = await LocationService.getCurrentLocation();

    final response = await _supabase.from('emergencies').insert({
      'establishment_id': user.id,
      'category': category,
      'status': 'pending',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'is_silent': isSilent,
      'notes': isSilent ? 'SILENT ALARM TRIGGERED' : notes,
    }).select().single();

    return response;
  }

  /// Live Status Tracker: Listens to real-time status changes for a specific alert ID
  static Stream<Map<String, dynamic>> streamAlertStatus(String emergencyId) {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('id', emergencyId)
        .map((records) => records.first);
  }

  /// Fetches current active alert for the establishment (if any)
  static Future<Map<String, dynamic>?> getActiveAlert() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('emergencies')
        .select()
        .eq('establishment_id', user.id)
        .inFilter('status', ['pending', 'acknowledged', 'en_route'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data;
  }

  /// 🛑 Cancel Active Emergency & Record Incident Audit Log
  static Future<void> cancelEmergency({
    required String emergencyId,
    required String reason,
    String? currentStatus,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User is not authenticated.');

    // 1. Fetch current status if not provided for log history
    String prevStatus = currentStatus ?? 'pending';
    if (currentStatus == null) {
      final currentAlert = await _supabase
          .from('emergencies')
          .select('status')
          .eq('id', emergencyId)
          .maybeSingle();
      if (currentAlert != null && currentAlert['status'] != null) {
        prevStatus = currentAlert['status'].toString();
      }
    }

    // 2. Update 'emergencies' status and record reason
    await _supabase.from('emergencies').update({
      'status': 'cancelled',
      'cancelled_reason': reason,
    }).eq('id', emergencyId);

    // 3. Write record into 'incident_logs' for complete history tracking
    await _supabase.from('incident_logs').insert({
      'emergency_id': emergencyId,
      'action_by': user.id,
      'previous_status': prevStatus,
      'new_status': 'cancelled',
      'remarks': reason,
    });
  }
}