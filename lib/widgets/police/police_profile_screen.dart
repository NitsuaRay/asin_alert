import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'edit_profile_modal.dart';
import 'change_password_modal.dart'; // Import Change Password Modal

class PoliceProfileScreen extends StatefulWidget {
  const PoliceProfileScreen({super.key});

  @override
  State<PoliceProfileScreen> createState() => _PoliceProfileScreenState();
}

class _PoliceProfileScreenState extends State<PoliceProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>?> _profileFuture;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);

  static const String stationName = 'PNP Asingan Station';

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

  void _openEditProfileModal(Map<String, dynamic> profile) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        currentProfile: profile,
        onSave: (updatedData) async {
          return await _authService.updateUserProfile(updatedData);
        },
      ),
    );

    if (result == true) {
      _fetchProfile();
    }
  }

  void _openChangePasswordModal() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangePasswordModal(
        onChangePassword: (newPassword) async {
          return await _authService.changePassword(newPassword);
        },
      ),
    );
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
            final fullName =
                profile['full_name'] as String? ?? 'Police Officer';
            final badgeNumber = profile['badge_number'] as String? ?? 'N/A';
            final email = profile['email'] as String? ?? 'N/A';
            final phone = profile['phone_number'] as String? ?? 'N/A';
            final address =
                profile['address'] as String? ??
                'Cerezo St. Poblacion West, Asingan, Pangasinan';
            final role = (profile['role'] as String? ?? 'police').toUpperCase();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Profile Header Card
                  _buildHeaderCard(
                    fullName: fullName,
                    badgeNumber: badgeNumber,
                    role: role,
                    onEditPressed: () => _openEditProfileModal(profile),
                  ),

                  const SizedBox(height: 20),

                  // Officer Information
                  _buildSectionHeader('OFFICER INFORMATION'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildInfoTile(
                      icon: Icons.badge_rounded,
                      label: 'Badge Number',
                      value: badgeNumber,
                      isMonospace: true,
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

                  // Assignment & Location
                  _buildSectionHeader('ASSIGNMENT & LOCATION'),
                  const SizedBox(height: 10),
                  _buildInfoCard([
                    _buildInfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: address,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.local_police_rounded,
                      label: 'Station',
                      value: stationName,
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
    required String badgeNumber,
    required String role,
    required VoidCallback onEditPressed,
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
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.25),
          width: 1,
        ),
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
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.10,
                child: Transform.rotate(
                  angle: -0.15,
                  child: const Icon(
                    Icons.local_police_sharp,
                    size: 160,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: onEditPressed,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade300.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_police_rounded,
                            size: 28,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.shade400.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$role RESPONDER',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      if (badgeNumber != 'N/A') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'BADGE #$badgeNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
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
    bool isMonospace = false,
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
                  style: TextStyle(
                    fontFamily: isMonospace ? 'monospace' : null,
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
