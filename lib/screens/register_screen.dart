import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _badgeIdController = TextEditingController();

  String _selectedRole = 'establishment';
  String _selectedBarangay = 'Poblacion West';
  bool _isLoading = false;

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
    // Validate essential inputs
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (_selectedRole == 'establishment' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter street address / landmark for your establishment.')),
      );
      return;
    }

    if (_selectedRole == 'police' && _badgeIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Police Badge Number / ID.')),
      );
      return;
    }

    // Auto-fill police address and barangay defaults
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
        badgeNumber: _selectedRole == 'police' ? _badgeIdController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! You can now log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPolice = _selectedRole == 'police';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Account'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'establishment',
                  label: Text('Establishment'),
                  icon: Icon(Icons.storefront),
                ),
                ButtonSegment(
                  value: 'police',
                  label: Text('PNP Police'),
                  icon: Icon(Icons.local_police),
                ),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedRole = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // Name Field
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: isPolice ? 'Officer Rank & Full Name *' : 'Business / Store Name *',
                hintText: isPolice ? 'e.g. PCpl Juan Dela Cruz' : 'e.g. Asingan Mart',
                prefixIcon: Icon(isPolice ? Icons.badge_outlined : Icons.business),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Badge ID (Police Only)
            if (isPolice) ...[
              TextField(
                controller: _badgeIdController,
                decoration: const InputDecoration(
                  labelText: 'PNP Badge / ID Number *',
                  hintText: 'e.g. PNP-2024-9981',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password *',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Number Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Mobile Number *',
                hintText: '09171234567',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Establishment Specific Fields
            if (!isPolice) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedBarangay,
                decoration: const InputDecoration(
                  labelText: 'Barangay (Asingan) *',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                items: _barangays
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBarangay = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address / Zone / Landmark *',
                  hintText: 'e.g. Zone 2, Near Public Plaza',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Police Info Card
            if (isPolice) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Police accounts default location: PNP Asingan Station Headquarters, Poblacion West.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'REGISTER ACCOUNT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}