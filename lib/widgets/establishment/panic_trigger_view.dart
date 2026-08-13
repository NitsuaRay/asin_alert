import 'package:flutter/material.dart';

import 'panic_button.dart';

class PanicTriggerView extends StatefulWidget {
  final Future<void> Function() onTriggerPanic;
  final Future<void> Function()? onTriggerSilentPanic; // 👈 Callback for silent panic

  const PanicTriggerView({
    super.key,
    required this.onTriggerPanic,
    this.onTriggerSilentPanic,
  });

  @override
  State<PanicTriggerView> createState() => _PanicTriggerViewState();
}

class _PanicTriggerViewState extends State<PanicTriggerView> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTitleTap() {
    final now = DateTime.now();

    // Reset tap count if taps are spaced more than 1.5 seconds apart
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(milliseconds: 1500)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Trigger silent alarm on 4th tap
    if (_tapCount >= 4) {
      _tapCount = 0;
      _lastTapTime = null;

      if (widget.onTriggerSilentPanic != null) {
        widget.onTriggerSilentPanic!();
      } else {
        // Fallback to standard trigger if no silent callback provided
        widget.onTriggerPanic();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silent emergency alert sent!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 👈 Wrapped Title in GestureDetector to capture rapid taps
            GestureDetector(
              onTap: _handleTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: const Text(
                  'EMERGENCY PANIC SYSTEM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
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
              onTrigger: widget.onTriggerPanic,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
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
}