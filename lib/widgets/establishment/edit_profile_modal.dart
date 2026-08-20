import 'package:flutter/material.dart';

class EditProfileModal extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  final Future<bool> Function(Map<String, dynamic> updatedData) onSave;

  const EditProfileModal({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedBarangay;
  bool _isSaving = false;
  String? _errorMessage;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color borderSlate = Color(0xFFE2E8F0);

  // List of all 21 Barangays in Asingan, Pangasinan
  static const List<String> asinganBarangays = [
    'Ariston East',
    'Ariston West',
    'Baro',
    'Bobonan',
    'Cabalitian',
    'Calepaan',
    'Carosucan Norte',
    'Carosucan Sur',
    'Coldit',
    'Domanpot',
    'Dupac',
    'Macalong',
    'Palaris',
    'Poblacion East',
    'Poblacion West',
    'San Vicente East',
    'San Vicente West',
    'Sanchez',
    'Sobol',
    'Toboy',
    'Tomana East',
    'Tomana West',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentProfile['full_name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.currentProfile['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.currentProfile['phone_number'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.currentProfile['address'] ?? '',
    );

    // Matching current profile barangay against the list
    final initialBarangay = widget.currentProfile['barangay'] as String?;
    if (initialBarangay != null && initialBarangay.isNotEmpty) {
      final cleaned = initialBarangay.replaceAll('Brgy.', '').trim();
      if (asinganBarangays.contains(cleaned)) {
        _selectedBarangay = cleaned;
      } else {
        _selectedBarangay = asinganBarangays.firstWhere(
          (b) => b.toLowerCase() == cleaned.toLowerCase(),
          orElse: () => asinganBarangays.first,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final updatedData = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'barangay': _selectedBarangay,
    };

    final success = await widget.onSave(updatedData);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'Failed to update profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryNavy,
                      letterSpacing: 0.6,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: primaryNavy),
                  ),
                ],
              ),
              const Divider(color: borderSlate, height: 1),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Establishment / Full Name
              _buildTextField(
                controller: _nameController,
                label: 'Establishment Name',
                icon: Icons.storefront_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter establishment name'
                    : null,
              ),
              const SizedBox(height: 14),

              // Email Address Input
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter email address';
                  }
                  if (!val.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone Number Input
              _buildTextField(
                controller: _phoneController,
                label: 'Contact Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter contact number'
                    : null,
              ),
              const SizedBox(height: 14),

              // Barangay Dropdown Input
              DropdownButtonFormField<String>(
                initialValue: _selectedBarangay,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: primaryNavy),
                decoration: _buildInputDecoration(
                  label: 'Barangay (Asingan)',
                  icon: Icons.map_rounded,
                ),
                items: asinganBarangays.map((String barangay) {
                  return DropdownMenuItem<String>(
                    value: barangay,
                    child: Text(
                      barangay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryNavy,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedBarangay = newValue);
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'Please select a barangay'
                    : null,
              ),
              const SizedBox(height: 14),

              // Street Address / Building / Landmark Input
              _buildTextField(
                controller: _addressController,
                label: 'Street / Building / Landmark',
                icon: Icons.location_on_rounded,
                maxLines: 2,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter street, building, or landmark'
                    : null,
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
      prefixIcon: Icon(icon, color: primaryNavy, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderSlate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryNavy,
      ),
      decoration: _buildInputDecoration(label: label, icon: icon),
    );
  }
}