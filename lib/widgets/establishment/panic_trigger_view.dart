import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
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
      'color': const Color(0xFF1E3A8A), // Police Blue
    },
    {
      'id': 'fire',
      'label': 'Fire Dept',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFC2410C), // Fire Orange
    },
    {
      'id': 'medical',
      'label': 'Medical',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFFB91C1C), // Emergency Red
    },
  ];

  @override
  void dispose() {
    _silentTapTimer?.cancel();
    super.dispose();
  }

  /// Single tap visual/haptic feedback for discrete multi-tap sequence
  Future<void> _provideDiscreteFeedback() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 30);
      }
    } catch (_) {}
  }

  /// Handles 4-Tap logic for Silent Alert Button
  void _handleSilentButtonTap() {
    if (_isSilentLoading || widget.onTriggerSilentPanic == null) return;

    _provideDiscreteFeedback();

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
      await widget.onTriggerSilentPanic!('crime');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silent Alert Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
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
    final activeCategory = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EMERGENCY PANIC SYSTEM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select emergency type or tap 4 times for Silent Alert',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 28),

            // 🏷️ Category Chips
            Wrap(
              spacing: 12,
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
                  backgroundColor: catColor.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: isSelected ? catColor : catColor.withValues(alpha: 0.3),
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

            const SizedBox(height: 36),

            // 🚨 Category-based Loud Panic Button
            PanicButton(
              baseColor: activeCategory['color'] as Color,
              onTrigger: () => widget.onTriggerPanic(_selectedCategory),
              holdDuration: const Duration(seconds: 2),
            ),

            const SizedBox(height: 36),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // 🤫 Silent Alert Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSilentLoading ? null : _handleSilentButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _silentTapCount > 0
                      ? const Color(0xFF78350F) // Active tap warning shade
                      : const Color(0xFF0F172A), // Slate 900
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                        Icons.security_rounded,
                        color: _silentTapCount > 0
                            ? Colors.amber
                            : Colors.amber.shade400,
                      ),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSilentLoading
                          ? 'DISPATCHING SILENT ALERT...'
                          : _silentTapCount > 0
                              ? 'TAP ${4 - _silentTapCount} MORE TIME${(4 - _silentTapCount) > 1 ? 'S' : ''}'
                              : 'SILENT ALERT (TAP 4 TIMES)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!_isSilentLoading && _silentTapCount == 0)
                      Text(
                        'Hostage & Discrete Threat Dispatch',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Hint Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: Colors.grey.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shortcut: Tap 4 times on the title header at the top to send a silent alert discretely.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}