import 'package:asin_alert/widgets/app_version_display/app_version_display.dart';
import 'package:asin_alert/widgets/police/settings_tab/about_app_page.dart';
import 'package:asin_alert/widgets/police/settings_tab/coming_soon_dialog.dart';
import 'package:asin_alert/widgets/police/settings_tab/developer_info_page.dart';
import 'package:asin_alert/widgets/police/settings_tab/privacy_policy_page.dart';
import 'package:asin_alert/widgets/police/settings_tab/terms_condition_page.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../logout_confirmation_dialog.dart';
import 'police_profile_screen.dart';

class PoliceSettingsScreen extends StatelessWidget {
  const PoliceSettingsScreen({super.key});

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);
  static const Color surfaceSlate = Color(0xFFF8FAFC);
  static const Color borderSlate = Color(0xFFE2E8F0);


  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: surfaceSlate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Profile Quick Entry Card
            // Dynamically fetch fresh profile data including verified server email
            FutureBuilder<Map<String, dynamic>?>(
              future: authService.getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProfileCard(context, 'Loading...');
                }

                final profile = snapshot.data;
                final fullName =
                    profile?['full_name'] as String? ?? 'Responder Account';

                return _buildProfileCard(context, fullName);
              },
            ),

            const SizedBox(height: 24),

            // Section: Account & Profile
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Officer Profile',
                subtitle: 'View badge, precinct, and contact information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: primaryNavy,
                          elevation: 0,
                          iconTheme: const IconThemeData(color: Colors.white),
                          title: const Text(
                            'Officer Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        body: const PoliceProfileScreen(),
                      ),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // Section: Support & Feedback
            _buildSectionHeader('SUPPORT & CONCERNS'),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.headset_mic_outlined,
                title: 'Chat Support & Hotline',
                subtitle: 'Get direct dispatch or tech support assistance',
                onTap: () => ComingSoonDialog.show(
                  context,
                  title: 'Chat Support & Hotline',
                  description:
                      'Direct in-app chat support and emergency hotlines are currently under development and will be available in the upcoming system update.',
                ),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.report_problem_outlined,
                title: 'Report an Issue / Concern',
                subtitle: 'Submit system bugs or alert telemetry errors',
                onTap: () => ComingSoonDialog.show(
                  context,
                  title: 'Report an Issue / Concern',
                  description:
                      'Automated bug reporting and telemetry error logs submission will be enabled in a future release.',
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Section: Legal & Policies
            _buildSectionHeader('LEGAL & PRIVACY'),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Data protection and incident telemetry policies',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Responder usage rules and operational protocols',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsConditionsPage(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // Section: About Application
            _buildSectionHeader('ABOUT SYSTEM'),
            const SizedBox(height: 8),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About ASIN Alert',
                subtitle: 'Municipal Emergency Alert & Response System',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutAppPage(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.code_rounded,
                title: 'Developer Information',
                subtitle: 'Built for municipal emergency service operations',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeveloperInfoPage(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 28),

            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => LogoutConfirmationDialog.show(
                  context,
                  accountType: 'police responder',
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('LOG OUT ACCOUNT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const AppVersionDisplay(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String email) {
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
            // Background Faded Police Mobile Graphic (Right Side)
            Positioned(
              right: -12,
              bottom: -10,
              child: Opacity(
                opacity: 0.12, // Subtle background watermark effect
                child: Transform.rotate(
                  angle: -0.1, // Sleek dynamic angle tilt
                  child: const Icon(
                    Icons
                        .local_police_rounded, // Replace with Image.asset('assets/police_car.png') if using custom asset
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Main Profile Information
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Shield Avatar Container with Outer Glow Accent
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_police,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Account Details & Active Status Pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'POLICE RESPONDER',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Active Duty Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade500.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green.shade400.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.green.shade300,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryNavy.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: primaryNavy),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
  }
}
