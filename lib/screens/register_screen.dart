import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants/legal_contents.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _badgeIdController = TextEditingController();

  String _selectedRole = 'establishment';
  String _selectedBarangay = 'Poblacion West';
  bool _isLoading = false;
  bool _obscurePassword = true;

  // PNP Asingan Theme Colors
  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color accentGold = Color(0xFFC5A059);

  final List<String> _barangays = [
    'Poblacion West',
    'Poblacion East',
    'Bantog',
    'Baro',
    'Bolo',
    'Cabalitian',
    'Calepaan',
    'Carupay',
    'Domanpot',
    'Dupac',
    'Macalong',
    'Palaris',
    'San Jose',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _badgeIdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final String finalAddress = _selectedRole == 'police'
        ? 'PNP Asingan Station, Poblacion West'
        : _addressController.text.trim();

    final String finalBarangay = _selectedRole == 'police'
        ? 'Poblacion West'
        : _selectedBarangay;

    setState(() => _isLoading = true);

    try {
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim(),
        address: finalAddress,
        barangay: finalBarangay,
        badgeNumber: _selectedRole == 'police'
            ? _badgeIdController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You can now log in.'),
            backgroundColor: primaryNavy,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLegalModal(String title, String content, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primaryNavy, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'I UNDERSTAND & AGREE',
                    style: TextStyle(
                      color: accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryNavy),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryNavy, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPolice = _selectedRole == 'police';
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Registration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
              ),
            ),
          ),

          // Ambient Decorative Glow
          Positioned(
            top: -screenSize.height * 0.05,
            right: -screenSize.width * 0.2,
            child: Container(
              width: screenSize.width * 0.7,
              height: screenSize.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryNavy.withValues(alpha: 0.06),
                    primaryNavy.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // Header Logo Card
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/asinLogo.png',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shield_rounded,
                                size: 50,
                                color: primaryNavy,
                              ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A.S.I.N. ALERT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'PNP Asingan Official Emergency Network',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Form Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Segmented Role Selector
                          SegmentedButton<String>(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return primaryNavy;
                                    }
                                    return Colors.white;
                                  }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return accentGold;
                                    }
                                    return const Color(0xFF64748B);
                                  }),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: 'establishment',
                                label: Text(
                                  'Establishment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                icon: Icon(Icons.storefront_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: 'police',
                                label: Text(
                                  'PNP Police',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.local_police_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                            selected: {_selectedRole},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(
                                () => _selectedRole = newSelection.first,
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Full Name / Business Name Field
                          TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? (isPolice
                                      ? 'Enter rank and full name'
                                      : 'Enter establishment name')
                                : null,
                            decoration: _buildInputDecoration(
                              labelText: isPolice
                                  ? 'Officer Rank & Full Name *'
                                  : 'Business / Store Name *',
                              hintText: isPolice
                                  ? 'e.g. PCpl Juan Dela Cruz'
                                  : 'e.g. Asingan Mart',
                              prefixIcon: isPolice
                                  ? Icons.badge_outlined
                                  : Icons.business_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Badge ID Field (Police Only)
                          if (isPolice) ...[
                            TextFormField(
                              controller: _badgeIdController,
                              textInputAction: TextInputAction.next,
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                  ? 'Badge Number is required for police personnel'
                                  : null,
                              decoration: _buildInputDecoration(
                                labelText: 'PNP Badge / ID Number *',
                                hintText: 'e.g. PNP-2024-9981',
                                prefixIcon: Icons.verified_user_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(val.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              labelText: 'Email Address *',
                              prefixIcon: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Password is required';
                              }
                              if (val.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              labelText: 'Password *',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Contact Number Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: isPolice
                                ? TextInputAction.done
                                : TextInputAction.next,
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? 'Contact number is required'
                                : null,
                            decoration: _buildInputDecoration(
                              labelText: 'Contact Mobile Number *',
                              hintText: '09171234567',
                              prefixIcon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Establishment Fields
                          if (!isPolice) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBarangay,
                              decoration: _buildInputDecoration(
                                labelText: 'Barangay (Asingan) *',
                                prefixIcon: Icons.location_city_outlined,
                              ),
                              items: _barangays
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedBarangay = val!),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressController,
                              textInputAction: TextInputAction.done,
                              validator: (val) =>
                                  (!isPolice &&
                                      (val == null || val.trim().isEmpty))
                                  ? 'Street address/landmark is required'
                                  : null,
                              decoration: _buildInputDecoration(
                                labelText: 'Street Address / Zone / Landmark *',
                                hintText: 'e.g. Zone 2, Near Public Plaza',
                                prefixIcon: Icons.place_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Police Headquarter Details Card
                          if (isPolice) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    color: primaryNavy,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Default Station: PNP Asingan Headquarters, Poblacion West.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryNavy,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Terms and Privacy Legal Notice Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'By registering, you acknowledge compliance with PNP policies, the ',
                                  ),
                                  TextSpan(
                                    text: LegalContents.termsOfServiceTitle,
                                    style: const TextStyle(
                                      color: primaryNavy,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _showLegalModal(
                                        LegalContents.termsOfServiceTitle,
                                        LegalContents.termsOfServiceText,
                                        Icons.gavel_rounded,
                                      ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: LegalContents.privacyPolicyTitle,
                                    style: const TextStyle(
                                      color: primaryNavy,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _showLegalModal(
                                        LegalContents.privacyPolicyTitle,
                                        LegalContents.privacyPolicyText,
                                        Icons.verified_user_rounded,
                                      ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Submit Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy,
                                foregroundColor: accentGold,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: accentGold,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
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
          ),
        ],
      ),
    );
  }
}
