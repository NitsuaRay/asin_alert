import 'package:flutter/material.dart';

class CancelAlertSheet extends StatefulWidget {
  final String alertId;
  final Future<void> Function(String reason) onConfirmCancel;

  const CancelAlertSheet({
    super.key,
    required this.alertId,
    required this.onConfirmCancel,
  });

  @override
  State<CancelAlertSheet> createState() => _CancelAlertSheetState();
}

class _CancelAlertSheetState extends State<CancelAlertSheet> {
  final List<String> _quickReasons = [
    'Accidental Press',
    'False Alarm',
    'Situation Resolved',
    'System Test',
    'Other',
  ];

  String _selectedReason = 'Accidental Press';
  final TextEditingController _customReasonController =
      TextEditingController();
  bool _isSubmitting = false;

  static const Color primaryNavy = Color(0xFF0F172A);

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    setState(() => _isSubmitting = true);

    final finalReason = _selectedReason == 'Other'
        ? (_customReasonController.text.trim().isNotEmpty
            ? _customReasonController.text.trim()
            : 'Other reason')
        : _selectedReason;

    await widget.onConfirmCancel(finalReason);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancel Emergency Alert?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select a reason to notify dispatch personnel.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Selection Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                selectedColor: primaryNavy.withOpacity(0.08),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(
                  color: isSelected ? primaryNavy : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? primaryNavy : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedReason = reason);
                  }
                },
              );
            }).toList(),
          ),

          // Custom Input Field
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customReasonController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type cancellation reason...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Keep Active',
                    style: TextStyle(
                      color: primaryNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}