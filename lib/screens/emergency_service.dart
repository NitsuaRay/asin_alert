import 'package:asin_alert/services/location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Incident Broadcast: Captures GPS location & inserts row into 'emergencies' table
  static Future<Map<String, dynamic>> triggerEmergency({
    required String category, // e.g. 'police', 'medical', 'fire'
    String? notes,
    bool isSilent = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    // 1. Grab current coordinates via geolocator
    final position = await LocationService.getCurrentLocation();

    // 2. Insert into 'emergencies' table (Fires database webhook to Edge Function)
    final response = await _supabase.from('emergencies').insert({
      'establishment_id': user.id,
      'category': category,
      'status': 'pending',
      'latitude': position.latitude,
      'longitude': position.longitude,
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

  /// Fetches the current active alert for the establishment (if any)
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

  /// Cancel active emergency
  static Future<void> cancelEmergency(String emergencyId, String reason) async {
    await _supabase.from('emergencies').update({
      'status': 'cancelled',
      'cancelled_reason': reason,
    }).eq('id', emergencyId);
  }
}