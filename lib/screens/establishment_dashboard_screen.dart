import 'dart:async';
import 'package:asin_alert/screens/emergency_service.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../widgets/panic_button.dart';

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

  // Silent Alarm Gesture Tracking (Multi-tap detector)
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveAlert();
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeAlert != null
              ? _buildLiveStatusTracker(_activeAlert!['id'])
              : _buildPanicTriggerView(),
    );
  }

  /// View when no active emergency exists
  Widget _buildPanicTriggerView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EMERGENCY PANIC SYSTEM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press & hold the red button for 2 seconds to alert police responders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 40),
            PanicButton(
              onTrigger: _triggerPanicAlert,
              holdDuration: const Duration(seconds: 2),
            ),
            const SizedBox(height: 40),
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Tap the app title bar 4 times quickly for a Silent Alarm trigger.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live Status Tracker View listening to Realtime updates on active emergency ID
  Widget _buildLiveStatusTracker(String alertId) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: EmergencyService.streamAlertStatus(alertId),
      builder: (context, snapshot) {
        final alert = snapshot.data ?? _activeAlert!;
        final status = alert['status'] as String;

        if (status == 'resolved' || status == 'cancelled') {
          Future.microtask(() {
            if (mounted) setState(() => _activeAlert = null);
          });
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildStatusHeaderCard(status),
              const SizedBox(height: 30),
              _buildStatusTimeline(status),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCancelDialog(alert['id']),
                icon: const Icon(Icons.cancel, color: Colors.white),
                label: const Text('CANCEL EMERGENCY ALERT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeaderCard(String status) {
    Color cardColor;
    String statusTitle;
    String statusDescription;

    switch (status) {
      case 'acknowledged':
        cardColor = Colors.orange.shade700;
        statusTitle = 'POLICE ACKNOWLEDGED';
        statusDescription = 'Police station received your alert!';
        break;
      case 'en_route':
        cardColor = Colors.blue.shade700;
        statusTitle = 'POLICE EN ROUTE 🚨';
        statusDescription = 'Responders are actively heading to your location.';
        break;
      case 'pending':
      default:
        cardColor = Colors.red.shade700;
        statusTitle = 'ALERT BROADCASTED 🚨';
        statusDescription = 'Waiting for police response team to accept...';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            statusTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['pending', 'acknowledged', 'en_route', 'resolved'];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: [
        _buildTimelineTile('Alert Sent to Police', true, currentIndex >= 0),
        _buildTimelineTile('Police Acknowledged', currentIndex >= 1, currentIndex >= 1),
        _buildTimelineTile('Responders En Route', currentIndex >= 2, currentIndex >= 2),
        _buildTimelineTile('Incident Resolved', currentIndex >= 3, currentIndex >= 3),
      ],
    );
  }

  Widget _buildTimelineTile(String label, bool isDone, bool isActive) {
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isDone ? Colors.green : Colors.grey.shade300,
        child: Icon(
          isDone ? Icons.check : Icons.circle,
          size: 16,
          color: isDone ? Colors.white : Colors.grey.shade600,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(String alertId) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency Alert?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason (e.g., Accidental press)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BACK'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EmergencyService.cancelEmergency(
                alertId,
                controller.text.isNotEmpty ? controller.text : 'User cancelled',
              );
              if (context.mounted) {
                Navigator.pop(context);
                setState(() => _activeAlert = null);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CANCEL ALERT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}