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
  
  String _selectedRole = 'establishment';
  String _selectedBarangay = 'Poblacion West';
  bool _isLoading = false;

  final List<String> _barangays = [
    'Poblacion West', 'Poblacion East', 'Bantog', 'Baro', 'Bolo', 'Cabalitian',
    'Calepaan', 'Carupay', 'Domanpot', 'Dupac', 'Macalong', 'Palaris', 'San Jose'
  ];

  Future<void> _handleRegister() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        barangay: _selectedBarangay,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Logging in...'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Selection Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'establishment', label: Text('Establishment'), icon: Icon(Icons.store)),
                ButtonSegment(value: 'police', label: Text('PNP Police'), icon: Icon(Icons.local_police)),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedRole = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: _selectedRole == 'establishment' ? 'Business / Store Name' : 'Officer Full Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBarangay,
              decoration: const InputDecoration(labelText: 'Barangay (Asingan)', border: OutlineInputBorder()),
              items: _barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBarangay = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Street Address / Zone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}