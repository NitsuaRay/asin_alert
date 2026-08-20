import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// 1. Register Police Device FCM Token for Background Sirens
  static Future<void> registerResponderToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Request notification permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await _fcm.getToken();

        if (token != null) {
          // Get device info safely depending on the platform
          String deviceIdentifier = 'Unknown Device';
          final deviceInfoPlugin = DeviceInfoPlugin();

          if (Platform.isAndroid) {
            final androidInfo = await deviceInfoPlugin.androidInfo;
            deviceIdentifier =
                '${androidInfo.brand} ${androidInfo.model}'; // e.g., "samsung SM-S918B"
          } else if (Platform.isIOS) {
            final iosInfo = await deviceInfoPlugin.iosInfo;
            deviceIdentifier =
                '${iosInfo.name} (${iosInfo.model})'; // e.g., "iPhone (iPhone 14 Pro)"
          }

          // Upsert device token and device info into responder_tokens table
          await _supabase.from('responder_tokens').upsert({
            'user_id': user.id,
            'fcm_token': token,
            'device_info': deviceIdentifier, // Matches your table column name
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');
        }
      }
    } catch (_) {
      // Fallback safely if token registration fails
    }
  }

  /// 1. Atomic Claim Method to prevent two officers from claiming the same emergency
  static Future<bool> claimEmergency(String alertId, String s) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      // Attempt update ONLY if responder_id is currently null
      final response = await _supabase
          .from('emergencies')
          .update({
            'status': 'acknowledged',
            'responder_id': currentUserId,
            'acknowledged_at': now,
            'updated_at': now,
          })
          .eq('id', alertId)
          .isFilter(
            'responder_id',
            null,
          ) // Ensures no one else claimed it first
          .select();

      // If update returned a row, current officer won the claim
      if (response.isNotEmpty) {
        await _supabase.from('incident_logs').insert({
          'emergency_id': alertId,
          'action_by': currentUserId,
          'previous_status': 'pending',
          'new_status': 'acknowledged',
          'remarks': 'Emergency claimed by officer',
          'created_at': now,
        });
        return true;
      }
      return false; // Already claimed by another officer
    } catch (e) {
      return false;
    }
  }

  /// 2. Stream ALL active emergencies enriched with Establishment & Responder details
  static Stream<List<Map<String, dynamic>>> streamActiveEmergencies() {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((records) async {
          final activeEmergencies = records.where((item) {
            final status = item['status'];
            return status == 'pending' ||
                status == 'acknowledged' ||
                status == 'en_route';
          }).toList();

          if (activeEmergencies.isEmpty) return [];

          return await Future.wait(
            activeEmergencies.map((emergency) async {
              final establishmentId = emergency['establishment_id'];
              final responderId = emergency['responder_id'];

              String establishmentName = 'Unknown Establishment';
              String address = 'No address provided';
              String barangay = 'No barangay provided';
              String responderName = 'Unassigned';

              // Fetch Establishment Details
              if (establishmentId != null) {
                try {
                  final profile = await _supabase
                      .from('profiles')
                      .select('full_name, address, barangay')
                      .eq('id', establishmentId)
                      .maybeSingle();

                  if (profile != null) {
                    establishmentName =
                        profile['full_name'] ?? establishmentName;
                    address = profile['address'] ?? address;
                    barangay = profile['barangay'] ?? barangay;
                  }
                } catch (_) {}
              }

              // Fetch Assigned Responder Details
              if (responderId != null) {
                try {
                  final responder = await _supabase
                      .from('profiles')
                      .select('full_name')
                      .eq('id', responderId)
                      .maybeSingle();

                  if (responder != null) {
                    responderName = responder['full_name'] ?? responderName;
                  }
                } catch (_) {}
              }

              return {
                ...emergency,
                'establishment_name': establishmentName,
                'address': address,
                'barangay': barangay,
                'responder_name': responderName,
                'is_my_dispatch': responderId == _supabase.auth.currentUser?.id,
              };
            }),
          );
        });
  }

  static Future<bool> releaseEmergency(String alertId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase
          .from('emergencies')
          .update({
            'status': 'pending',
            'responder_id': null,
            'updated_at': now,
          })
          .eq('id', alertId)
          .eq('responder_id', currentUserId);

      await _supabase.from('incident_logs').insert({
        'emergency_id': alertId,
        'action_by': currentUserId,
        'previous_status': 'acknowledged',
        'new_status': 'pending',
        'remarks': 'Responder released the emergency back to pending queue',
        'created_at': now,
      });

      return true; // Success
    } catch (e) {
      debugPrint('Error releasing emergency: $e');
      return false; // Failed
    }
  }

  /// 3. Update Incident Status ('acknowledged', 'en_route', 'resolved') + Audit Log & Timestamps
  static Future<void> updateStatus({
    required String alertId,
    required String newStatus,
    String? previousStatus,
    String? remarks,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final now = DateTime.now().toUtc().toIso8601String();

      // Base fields to update in emergencies table
      final Map<String, dynamic> emergencyUpdates = {
        'status': newStatus,
        'responder_id': user?.id,
        'updated_at': now,
      };

      // Conditionally attach specific lifecycle timestamps
      if (newStatus == 'acknowledged') {
        emergencyUpdates['acknowledged_at'] = now;
      } else if (newStatus == 'resolved') {
        emergencyUpdates['resolved_at'] = now;
      }

      // Update emergency record
      await _supabase
          .from('emergencies')
          .update(emergencyUpdates)
          .eq('id', alertId);

      // Audit log insertion
      await _supabase.from('incident_logs').insert({
        'emergency_id': alertId,
        'action_by': user?.id,
        'previous_status': previousStatus,
        'new_status': newStatus,
        'remarks':
            remarks ?? 'Status updated to ${newStatus.replaceAll('_', ' ')}',
        'created_at': now,
      });
    } catch (_) {
      rethrow;
    }
  }

  /// 1. Stream single Emergency with profile enrichment
  static Stream<Map<String, dynamic>> streamEmergency(String emergencyId) {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('id', emergencyId)
        .asyncMap((records) async {
          if (records.isEmpty) return {};

          final emergency = records.first;
          final establishmentId = emergency['establishment_id'];

          String establishmentName = 'Unknown Establishment';
          String address = 'No address provided';
          String barangay = 'No barangay provided';
          String phoneNumber = '';

          if (establishmentId != null) {
            try {
              final profile = await _supabase
                  .from('profiles')
                  .select('full_name, address, barangay, phone_number')
                  .eq('id', establishmentId)
                  .maybeSingle();

              if (profile != null) {
                establishmentName = profile['full_name'] ?? establishmentName;
                address = profile['address'] ?? address;
                barangay = profile['barangay'] ?? barangay;
                phoneNumber = profile['phone_number'] ?? phoneNumber;
              }
            } catch (_) {
              // Fallback safely on query errors
            }
          }

          return {
            ...emergency,
            'establishment_name': establishmentName,
            'address': address,
            'barangay': barangay,
            'phone_number': phoneNumber,
          };
        });
  }

  /// 5. Stream timeline / incident logs for a specific emergency
  static Stream<List<Map<String, dynamic>>> streamIncidentLogs(
    String emergencyId,
  ) {
    return _supabase
        .from('incident_logs')
        .stream(primaryKey: ['id'])
        .eq('emergency_id', emergencyId)
        .order('created_at', ascending: true)
        .asyncMap((logs) async {
          if (logs.isEmpty) return [];

          final enrichedLogs = await Future.wait(
            logs.map((log) async {
              final actionById = log['action_by'];

              String actionByName = '';
              String actionByRole = '';

              if (actionById != null && actionById.toString().isNotEmpty) {
                try {
                  final profile = await _supabase
                      .from('profiles')
                      .select('full_name, role')
                      .eq('id', actionById)
                      .maybeSingle();

                  if (profile != null) {
                    actionByName = profile['full_name'] ?? '';
                    actionByRole = profile['role'] ?? '';
                  }
                } catch (_) {
                  // Fallback safely on query errors
                }
              }

              return {
                ...log,
                'action_by_name': actionByName,
                'action_by_role': actionByRole,
              };
            }),
          );

          return enrichedLogs;
        });
  }

  /// 6. Open External Google Maps / Waze Navigation
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
      }
    } catch (_) {
      // Fallback safely if map application fails to launch
    }
  }

  /// Stream Resolved Emergency History enriched with Establishment Profiles
  static Stream<List<Map<String, dynamic>>> streamEmergencyHistory() {
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((records) async {
          // 1. Filter resolved emergencies assigned to the responder
          final resolvedEmergencies = records.where((item) {
            return item['status'] == 'resolved' &&
                item['responder_id'] == currentUserId;
          }).toList();

          if (resolvedEmergencies.isEmpty) return [];

          // 2. Fetch profile info for each establishment_id
          final enrichedEmergencies = await Future.wait(
            resolvedEmergencies.map((emergency) async {
              final establishmentId = emergency['establishment_id'];

              String establishmentName = 'Unknown Establishment';
              String address = 'No address provided';
              String barangay = 'No barangay provided';

              if (establishmentId != null) {
                try {
                  final profile = await _supabase
                      .from('profiles')
                      .select('full_name, address, barangay')
                      .eq('id', establishmentId)
                      .maybeSingle();

                  if (profile != null) {
                    establishmentName =
                        profile['full_name'] ?? establishmentName;
                    address = profile['address'] ?? address;
                    barangay = profile['barangay'] ?? barangay;
                  }
                } catch (_) {
                  // Fallback safely on query errors
                }
              }

              return {
                ...emergency,
                'establishment_name': establishmentName,
                'address': address,
                'barangay': barangay,
              };
            }),
          );

          return enrichedEmergencies;
        });
  }

  /// Fetches distinct emergency categories from Supabase
  static Future<List<String>> fetchCategories() async {
    try {
      final response = await _supabase.from('emergencies').select('category');

      final set = <String>{};
      for (final item in response as List) {
        if (item['category'] != null) {
          set.add(item['category'].toString().toUpperCase());
        }
      }

      final categories = set.toList()..sort();
      return ['ALL', ...categories];
    } catch (e) {
      // Fallback default categories in case of error
      return ['ALL', 'POLICE', 'MEDICAL', 'FIRE'];
    }
  }
}
