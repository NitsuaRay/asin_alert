import 'package:asin_alert/widgets/establishment/change_password_modal.dart';
import 'package:asin_alert/widgets/establishment/edit_profile_modal.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EstablishmentProfileScreen extends StatefulWidget {
  const EstablishmentProfileScreen({super.key});

  @override
  State<EstablishmentProfileScreen> createState() =>
      _EstablishmentProfileScreenState();
}

class _EstablishmentProfileScreenState
    extends State<EstablishmentProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>?> _profileFuture;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);
  static const Color accentGold = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    setState(() {
      _profileFuture = _authService.getUserProfile();
    });
  }

  /// Helper to construct formatted full address
  String _buildFullAddress(String? streetAddress, String? barangay) {
    final List<String> parts = [];

    if (streetAddress != null && streetAddress.trim().isNotEmpty) {
      parts.add(streetAddress.trim());
    }

    if (barangay != null && barangay.trim().isNotEmpty) {
      parts.add(
        barangay.trim().startsWith('Brgy')
            ? barangay.trim()
            : 'Brgy. ${barangay.trim()}',
      );
    }

    parts.add('Asingan, Pangasinan');

    return parts.join(', ');
  }

  void _openEditProfileModal(Map<String, dynamic> currentProfile) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        currentProfile: currentProfile,
        onSave: (updatedData) => _authService.updateUserProfile(updatedData),
      ),
    );

    // If update was successful, refresh the profile info
    if (result == true && mounted) {
      _fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openChangePasswordModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangePasswordModal(
        onChangePassword: ({required currentPassword, required newPassword}) =>
            _authService.changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSlate,
      body: RefreshIndicator(
        onRefresh: () async => _fetchProfile(),
        color: primaryNavy,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryNavy),
              );
            }

            final profile = snapshot.data ?? {};

            // Exact fields from your backend
            final fullName =
                profile['full_name'] as String? ?? 'Establishment Name';
            final email = profile['email'] as String? ?? 'N/A';
            final phone = profile['phone_number'] as String? ?? 'N/A';
            final rawAddress = profile['address'] as String?;
            final barangay = profile['barangay'] as String?;

            // Formatted Full Address
            final fullAddress = _buildFullAddress(rawAddress, barangay);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Header Card
                  // Header Card
                  _buildHeaderCard(fullName: fullName, currentProfile: profile),

                  const SizedBox(height: 20),

                  // Business Information
                  _buildSectionHeader('ESTABLISHMENT DETAILS'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildInfoTile(
                      icon: Icons.storefront_rounded,
                      label: 'Establishment Name',
                      value: fullName.toUpperCase(),
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.email_rounded,
                      label: 'Email Address',
                      value: email,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.phone_rounded,
                      label: 'Contact Number',
                      value: phone,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Location
                  _buildSectionHeader('LOCATION'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildInfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Full Address',
                      value: fullAddress,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Security & Account Section
                  _buildSectionHeader('SECURITY & ACCOUNT'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    InkWell(
                      onTap: _openChangePasswordModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryNavy.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 18,
                                color: primaryNavy,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required String fullName,
    required Map<String, dynamic> currentProfile,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryNavy, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background decorative watermark icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.10,
                child: Transform.rotate(
                  angle: -0.15,
                  child: const Icon(
                    Icons.storefront_sharp,
                    size: 160,
                    color: accentGold,
                  ),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Top Row: Edit Profile Icon Button
                  Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openEditProfileModal(currentProfile),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Avatar / Store Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.store_rounded,
                        size: 40,
                        color: primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Establishment Name
                  Text(
                    fullName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'ESTABLISHMENT',
                      style: TextStyle(
                        color: accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primaryNavy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
  }
}
