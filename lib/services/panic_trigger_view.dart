import 'package:flutter/material.dart';
import '../widgets/establishment/panic_button.dart';

class PanicTriggerView extends StatefulWidget {
  final Future<void> Function() onTriggerPanic;
  final Future<void> Function()? onTriggerSilentPanic;

  const PanicTriggerView({
    super.key,
    required this.onTriggerPanic,
    this.onTriggerSilentPanic,
  });

  @override
  State<PanicTriggerView> createState() => _PanicTriggerViewState();
}

class _PanicTriggerViewState extends State<PanicTriggerView> {
  bool _isSilentLoading = false;

  Future<void> _handleSilentPanic() async {
    if (widget.onTriggerSilentPanic == null) return;

    setState(() => _isSilentLoading = true);
    try {
      await widget.onTriggerSilentPanic!();
    } finally {
      if (mounted) {
        setState(() => _isSilentLoading = false);
      }
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
            const SizedBox(height: 36),

            // Standard Loud Alarm Button
            PanicButton(
              onTrigger: widget.onTriggerPanic,
              holdDuration: const Duration(seconds: 2),
            ),

            const SizedBox(height: 36),

            // Silent Alarm Trigger Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSilentLoading ? null : _handleSilentPanic,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSilentLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_off_rounded, color: Colors.grey),
                label: Text(
                  _isSilentLoading
                      ? 'Sending Silent Alert...'
                      : 'Silent Panic Alert',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Information Card
            Card(
              color: Colors.grey.shade100,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap 4 times to trigger Silent Panic. It dispatches police discretely without activating local sirens or screen flashing.',
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
