import 'dart:async';
import 'package:asin_alert/services/emergency_service.dart';
import 'package:asin_alert/services/notification_service.dart';
import 'package:asin_alert/widgets/establishment/cancel_alert_sheet.dart';
import 'package:asin_alert/widgets/establishment/panic_trigger_view.dart';
import 'package:asin_alert/widgets/logout_confirmation_dialog.dart';
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

  // Branded Color Palette
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

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
            (updatedRecord['category'] ?? 'POLICE').toString().toUpperCase();
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
        category: category,
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

  /// 4-Tap Discrete Gesture Handler on App Bar Logo/Header
  Future<void> _handleHeaderTap() async {
    _headerTapCount++;

    // Tactile haptic per discrete tap
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 30);
      }
    } catch (_) {}

    _headerTapTimer?.cancel();
    _headerTapTimer = Timer(const Duration(milliseconds: 2500), () {
      _headerTapCount = 0;
    });

    if (_headerTapCount >= 4) {
      _headerTapCount = 0;
      _headerTapTimer?.cancel();

      try {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(pattern: [0, 80, 40, 120]);
        }
      } catch (_) {}

      await _triggerSilentPanicAlert('crime');
    }
  }

  void _clearActiveAlert() {
    if (mounted) {
      _statusSubscription?.unsubscribe();
      setState(() => _activeAlert = null);
    }
  }

  /// 🛑 Cancel Sheet Handler in Parent Screen
  Future<void> _showCancelBottomSheet(String alertId) async {
    await showModalBottomSheet(
      context: context, // Uses the State's BuildContext directly
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => CancelAlertSheet(
        alertId: alertId,
        onConfirmCancel: (reason) async {
          try {
            // 1. Call database cancel method
            await EmergencyService.cancelEmergency(
              emergencyId: alertId,
              reason: reason,
              currentStatus: _activeAlert?['status']?.toString(),
            );

            // 2. Dismiss bottom sheet safely using modalContext
            if (modalContext.mounted) {
              Navigator.pop(modalContext);
            }

            // 3. Reset parent state & notify user using parent context
            if (mounted) {
              _clearActiveAlert();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert was successfully cancelled.'),
                  backgroundColor: Colors.black87,
                ),
              );
            }
          } catch (e) {
            if (modalContext.mounted) {
              Navigator.pop(modalContext);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to cancel alert: ${e.toString()}'),
                  backgroundColor: Colors.red.shade800,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Clean slate background
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque, // Full title width hit detection
          onTap: _handleHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                // 🖼️ ASIN Logo Integration
                Image.asset(
                  'assets/asinLogo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.security, color: accentGold, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ASIN Alert',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accentGold, width: 0.8),
                  ),
                  child: const Text(
                    'ESTABLISHMENT',
                    style: TextStyle(
                      color: accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => LogoutConfirmationDialog.show(
              context,
              accountType: 'establishment',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryNavy))
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