import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// 1. Register Police Device FCM Token for Background Sirens
  static Future<void> registerResponderToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot register FCM token: No logged-in user found.');
        return;
      }

      // Request notification permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await _fcm.getToken();
        debugPrint('🔑 FCM Token retrieved: $token');

        if (token != null) {
          // Upsert device token into responder_tokens table
          final response = await _supabase.from('responder_tokens').upsert({
            'user_id': user.id,
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id').select();

          debugPrint(
            '✅ Responder token successfully saved to Supabase: $response',
          );
        }
      } else {
        debugPrint('❌ FCM Permission denied by user.');
      }
    } catch (e) {
      debugPrint('❌ Error registering responder FCM token: $e');
    }
  }

  /// 2. Stream Active Emergencies (Realtime feed of pending, acknowledged, en_route)
  static Stream<List<Map<String, dynamic>>> streamActiveEmergencies() {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (records) => records
              .where(
                (item) =>
                    item['status'] == 'pending' ||
                    item['status'] == 'acknowledged' ||
                    item['status'] == 'en_route',
              )
              .toList(),
        );
  }

  /// 3. Update Incident Status ('acknowledged', 'en_route', 'resolved')
  static Future<void> updateStatus(String alertId, String newStatus) async {
    final user = _supabase.auth.currentUser;
    await _supabase
        .from('emergencies')
        .update({'status': newStatus, 'responder_id': user?.id})
        .eq('id', alertId);
  }

  /// 4. Open External Google Maps / Waze Navigation
  static Future<void> openMapDirections(
    double latitude,
    double longitude,
  ) async {
    // Universal Google Maps navigation URL (driving mode)
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );

    // Alternative fallback geo scheme
    final Uri geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else {
        debugPrint('Could not open map application.');
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }
}
