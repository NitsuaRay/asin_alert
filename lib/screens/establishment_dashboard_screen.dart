import 'dart:async';
import 'package:asin_alert/services/emergency_service.dart';
import 'package:asin_alert/services/auth_service.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:asin_alert/widgets/establishment/cancel_alert_sheet.dart';
import 'package:asin_alert/widgets/establishment/panic_trigger_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../widgets/establishment/live_status_tracker.dart';

class EstablishmentDashboardScreen extends StatefulWidget {
  const EstablishmentDashboardScreen({super.key});

  @override
  State<EstablishmentDashboardScreen> createState() =>
      _EstablishmentDashboardScreenState();
}

class _EstablishmentDashboardScreenState
    extends State<EstablishmentDashboardScreen> {
  Map<String, dynamic>? _activeAlert;
  bool _isLoading = true;

  RealtimeChannel? _statusSubscription;

  // Multi-tap detector state for AppBar header
  int _headerTapCount = 0;
  Timer? _headerTapTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveAlert();
    _saveFcmToken();
  }

  Future<void> _saveFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final settings = await FirebaseMessaging.instance.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'fcm_token': token})
              .eq('id', user.id);
        }
      }
    } catch (e) {
      debugPrint('Error saving establishment FCM token: $e');
    }
  }

  void _listenForPoliceResponse(String emergencyId) {
    _statusSubscription?.unsubscribe();

    _statusSubscription = Supabase.instance.client
        .channel('public:emergencies:$emergencyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'emergencies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: emergencyId,
          ),
          callback: (payload) async {
            final updatedRecord = payload.newRecord;
            final status = updatedRecord['status'];
            (updatedRecord['category'] ?? 'POLICE')
                .toString()
                .toUpperCase();
            final isSilent =
                updatedRecord['is_silent'] == true ||
                updatedRecord['is_silent'] == 'true';

            String title = 'ASIN Alert Update';
            String body = 'Your emergency alert status is now: $status.';

            if (status == 'acknowledged') {
              title = isSilent
                  ? '🤫 Alert Acknowledged'
                  : '🚨 Emergency Alert Acknowledged';
              body = 'Tactical Responders have acknowledged your alert.';
            } else if (status == 'en_route') {
              title = isSilent
                  ? '🤫 Responders En Route'
                  : '🚔 Responders En Route!';
              body =
                  'Units are currently dispatched and heading to your location.';
            } else if (status == 'resolved') {
              title = '✅ Incident Resolved';
              body = 'The emergency situation has been marked as resolved.';
            }

            final message = RemoteMessage(
              notification: RemoteNotification(title: title, body: body),
              data: {
                'title': title,
                'body': body,
                'is_silent': isSilent.toString(),
              },
            );

            if (isSilent) {
              await NotificationService.showSilentNotification(message);
            } else {
              await NotificationService.showAlertNotification(message);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _headerTapTimer?.cancel();
    _statusSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _checkActiveAlert() async {
    try {
      final alert = await EmergencyService.getActiveAlert();
      if (mounted) {
        setState(() {
          _activeAlert = alert;
          _isLoading = false;
        });
        if (alert != null) {
          _listenForPoliceResponse(alert['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Trigger Normal Panic Alert
  Future<void> _triggerPanicAlert(String category) async {
    try {
      final alert = await EmergencyService.triggerEmergency(
        category: category,
        isSilent: false,
      );
      if (mounted) {
        setState(() => _activeAlert = alert);
        _listenForPoliceResponse(alert['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger alert: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Trigger Silent Panic Alert (Dedicated for Hostage / Security Threat)
  Future<void> _triggerSilentPanicAlert(String category) async {
    try {
      final alert = await EmergencyService.triggerEmergency(
        category: category, // 'security_hostage'
        isSilent: true,
      );

      if (mounted) {
        setState(() => _activeAlert = alert);
        _listenForPoliceResponse(alert['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silent hostage/security threat alert dispatched successfully.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger silent alert: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// 4-Tap Gesture Handler on App Bar Header
  Future<void> _handleHeaderTap() async {
    _headerTapCount++;
    _headerTapTimer?.cancel();
    _headerTapTimer = Timer(const Duration(milliseconds: 2500), () {
      _headerTapCount = 0;
    });

    if (_headerTapCount >= 4) {
      _headerTapCount = 0;
      _headerTapTimer?.cancel();

      try {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 100);
        }
      } catch (_) {}

      await _triggerSilentPanicAlert('crime'); // 👈 Updated to 'crime'
    }
  }

  void _clearActiveAlert() {
    if (mounted) {
      _statusSubscription?.unsubscribe();
      setState(() => _activeAlert = null);
    }
  }

  Future<void> _showCancelBottomSheet(String alertId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelAlertSheet(
        alertId: alertId,
        onConfirmCancel: (reason) async {
          await EmergencyService.cancelEmergency(alertId, reason);
          if (context.mounted) {
            Navigator.pop(context);
            _clearActiveAlert();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Emergency alert was successfully cancelled.'),
                backgroundColor: Colors.black87,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior
              .opaque, // Ensures tap detection across the full title width
          onTap: _handleHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: const [
                Icon(Icons.security, color: Colors.red),
                SizedBox(width: 10),
                Text('ASIN Alert - Establishment'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeAlert != null
          ? LiveStatusTracker(
              alertId: _activeAlert!['id'],
              initialAlert: _activeAlert!,
              onAlertEnded: _clearActiveAlert,
              onCancelPressed: (id) => _showCancelBottomSheet(id),
            )
          : PanicTriggerView(
              onTriggerPanic: _triggerPanicAlert,
              onTriggerSilentPanic: _triggerSilentPanicAlert,
            ),
    );
  }
}
