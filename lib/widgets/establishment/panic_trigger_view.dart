import 'dart:async';
import 'package:flutter/material.dart';
import 'panic_button.dart';

class PanicTriggerView extends StatefulWidget {
  final Future<void> Function(String category) onTriggerPanic;
  final Future<void> Function(String category)? onTriggerSilentPanic;

  const PanicTriggerView({
    super.key,
    required this.onTriggerPanic,
    this.onTriggerSilentPanic,
  });

  @override
  State<PanicTriggerView> createState() => _PanicTriggerViewState();
}

class _PanicTriggerViewState extends State<PanicTriggerView> {
  String _selectedCategory = 'police';
  bool _isSilentLoading = false;

  // 4-Tap Counter State for Silent Button
  int _silentTapCount = 0;
  Timer? _silentTapTimer;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'police',
      'label': 'Police',
      'icon': Icons.local_police_rounded,
      'color': Colors.blue.shade800,
    },
    {
      'id': 'fire',
      'label': 'Fire Dept',
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.deepOrange.shade700,
    },
    {
      'id': 'medical',
      'label': 'Medical',
      'icon': Icons.medical_services_rounded,
      'color': Colors.red.shade700,
    },
  ];

  @override
  void dispose() {
    _silentTapTimer?.cancel();
    super.dispose();
  }

  /// Handles 4-Tap logic for Silent Alert Button
  void _handleSilentButtonTap() {
    if (_isSilentLoading || widget.onTriggerSilentPanic == null) return;

    setState(() {
      _silentTapCount++;
    });

    _silentTapTimer?.cancel();
    _silentTapTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _silentTapCount = 0);
      }
    });

    if (_silentTapCount >= 4) {
      _silentTapTimer?.cancel();
      setState(() => _silentTapCount = 0);
      _executeSilentPanic();
    }
  }

  Future<void> _executeSilentPanic() async {
  setState(() => _isSilentLoading = true);
  try {
    // 🤫 Uses existing ENUM value 'crime' for silent hostage/threat alerts
    await widget.onTriggerSilentPanic!('crime');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silent Alert Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
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
              'Select standard emergency type or tap 4 times for Silent Alert.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // 🏷️ Category Selection Chips for Loud Alarm
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _categories.map((cat) {
                final bool isSelected = _selectedCategory == cat['id'];
                final Color catColor = cat['color'] as Color;

                return ChoiceChip(
                  showCheckmark: false,
                  avatar: Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  label: Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : catColor,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: catColor,
                  backgroundColor: catColor.withValues(alpha:0.08),
                  side: BorderSide(
                    color: isSelected ? catColor : catColor.withValues(alpha:0.3),
                    width: 1.5,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat['id'] as String);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // 🚨 Standard Loud Alarm Button
            PanicButton(
              onTrigger: () => widget.onTriggerPanic(_selectedCategory),
              holdDuration: const Duration(seconds: 2),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // 🤫 4-Tap Silent Alarm Button (Hostage / Kidnap / Security Threat)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSilentLoading ? null : _handleSilentButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _silentTapCount > 0
                      ? Colors.amber.shade900
                      : Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isSilentLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.security,
                        color: _silentTapCount > 0 ? Colors.white : Colors.amber,
                      ),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSilentLoading
                          ? 'SENDING SILENT ALERT...'
                          : _silentTapCount > 0
                              ? 'TAP ${4 - _silentTapCount} MORE TIMES'
                              : 'SILENT ALERT (TAP 4 TIMES)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!_isSilentLoading && _silentTapCount == 0)
                      const Text(
                        'Hostage & Threat Discrete Emergency Dispatch',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
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
                      Icons.lock_clock,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Alternatively, tap 4 times on the app title at the top to send a silent threat dispatch quietly.',
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