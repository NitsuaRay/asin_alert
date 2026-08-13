import 'dart:async';
import 'package:asin_alert/services/emergency_service.dart';
import 'package:asin_alert/services/auth_service.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:asin_alert/widgets/establishment/cancel_alert_sheet.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../widgets/establishment/live_status_tracker.dart';
import '../services/panic_trigger_view.dart';

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

  // Realtime Channel for listening to police updates on the active alert
  RealtimeChannel? _statusSubscription;

  // Silent Alarm Gesture Tracking (Multi-tap detector)
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveAlert();
    _saveFcmToken(); // Save token so webhook can notify this store
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

  /// Start listening for status changes on a specific emergency alert
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
            final isSilent =
                updatedRecord['is_silent'] == true ||
                updatedRecord['is_silent'] == 'true';

            String title = 'ASIN Alert Update';
            String body = 'Your alert status has been updated to $status.';

            if (status == 'acknowledged') {
              title = isSilent
                  ? '🤫 Alert Acknowledged'
                  : '👮 Alert Acknowledged';
              body = 'PNP Responders have acknowledged your panic alert!';
            } else if (status == 'en_route') {
              title = isSilent
                  ? '🤫 Responders En Route'
                  : '🚔 Responders En Route!';
              body = 'Police officers are currently heading to your location!';
            } else if (status == 'resolved') {
              title = '✅ Emergency Resolved';
              body = 'The incident has been marked as resolved.';
            }

            final message = RemoteMessage(
              notification: RemoteNotification(title: title, body: body),
              data: {
                'title': title,
                'body': body,
                'is_silent': isSilent.toString(), // Fixed here
              },
            );

            // Routely trigger soundless banner if silent, else play siren
            if (isSilent) {
              await NotificationService.showSilentNotification(message);
            } else {
              await NotificationService.showSirenNotification(message);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _statusSubscription?.unsubscribe(); // Prevent channel memory leak
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
  Future<void> _triggerPanicAlert() async {
    final alert = await EmergencyService.triggerEmergency(
      category: 'police',
      isSilent: false,
    );
    if (mounted) {
      setState(() => _activeAlert = alert);
      _listenForPoliceResponse(alert['id']);
    }
  }

  /// Silent Alarm Trigger: Activated by secret multi-tap gesture (4 fast taps anywhere on app header)
  Future<void> _handleHeaderTap() async {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1500), () {
      _tapCount = 0;
    });

    if (_tapCount >= 4) {
      _tapCount = 0;
      // Ultra discrete single haptic buzz to confirm trigger without lighting up screen visually
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 80);
      }

      final alert = await EmergencyService.triggerEmergency(
        category: 'police',
        isSilent: true,
      );

      if (mounted) {
        setState(() => _activeAlert = alert);
        _listenForPoliceResponse(alert['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silent emergency broadcast sent quietly.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
      }
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
      isScrollControlled: true, // Smooth keyboard displacement
      backgroundColor: Colors.transparent,
      builder: (context) => CancelAlertSheet(
        alertId: alertId,
        onConfirmCancel: (reason) async {
          await EmergencyService.cancelEmergency(alertId, reason);
          if (context.mounted) {
            Navigator.pop(context); // Close bottom sheet
            _clearActiveAlert(); // Reset dashboard state

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
          onTap: _handleHeaderTap, // Secret multi-tap silent alarm trigger
          child: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 10),
              Text('ASIN Alert - Establishment'),
            ],
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
              onTriggerSilentPanic:
                  _handleHeaderTap, // 👈 Triggers silent alarm when 4-tapping title in view
            ),
    );
  }
}
