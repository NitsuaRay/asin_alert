import 'package:flutter/material.dart';

class DeveloperInfoPage extends StatelessWidget {
  const DeveloperInfoPage({super.key});

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Developer Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LOGO & HEADER ---
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/asinLogo.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A.S.I.N. Alert Network Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Engineering & Technical Maintenance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // --- DEVELOPMENT TEAM ---
              _buildSectionTitle('Development Team'),
              const SizedBox(height: 12),
              _buildDeveloperCard(
                'Wenna De Leon Honrado',
                'Lead Full-Stack Developer & System Architect',
                'Spearheaded the overall system design, frontend architecture, and core emergency dispatch workflows.',
              ),
              const SizedBox(height: 10),
              _buildDeveloperCard(
                'Ma Jo Ann Ventura',
                'Co-Developer & Database Security Specialist',
                'Managed backend database integration, Row Level Security (RLS) policies, and real-time telemetry syncing.',
              ),
              const SizedBox(height: 20),

              // --- INSTITUTIONAL PURPOSE ---
              _buildSectionTitle('Project Context & Stakeholders'),
              const SizedBox(height: 8),
              const Text(
                'This application is engineered specifically to support municipal public safety operations under the administrative purview of the PNP Asingan Police Station. It bridges digital panic button dispatching with active law enforcement command frameworks to reduce emergency response latency.',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // --- TECHNICAL ARCHITECTURE ---
              _buildSectionTitle('Technical Architecture'),
              const SizedBox(height: 12),
              _buildTechDetailItem(
                Icons.phone_android_rounded,
                'Cross-Platform Frontend',
                'Built using Google’s Flutter framework, ensuring high performance, responsive layout consistency, and seamless native capability integration across mobile operating systems.',
              ),
              const SizedBox(height: 12),
              _buildTechDetailItem(
                Icons.cloud_sync_rounded,
                'Cloud & Realtime Backend',
                'Powered by Supabase infrastructure, utilizing PostgreSQL for robust relational data handling and WebSockets for sub-second emergency notification delivery.',
              ),
              const SizedBox(height: 12),
              _buildTechDetailItem(
                Icons.security_rounded,
                'Security & Compliance',
                'Implements strict token-based user authentication, TLS/SSL transport security, and database policies aligned with Republic Act No. 10173 (Data Privacy Act of 2012).',
              ),
              const SizedBox(height: 20),

              // --- SYSTEM SPECIFICATIONS ---
              _buildSectionTitle('System Specifications'),
              const SizedBox(height: 12),
              _buildInfoRow('Application Name', 'A.S.I.N. Alert'),
              _buildDivider(),
              _buildInfoRow(
                'System Codename',
                'Asingan Security & Incident Notifier',
              ),
              _buildDivider(),
              _buildInfoRow('Release Version', '1.0.0 (Production Build)'),
              _buildDivider(),
              _buildInfoRow('Deployment Year', '2026'),
              _buildDivider(),
              _buildInfoRow(
                'Primary Ecosystem',
                'Flutter SDK & Supabase Cloud',
              ),
              _buildDivider(),
              _buildInfoRow(
                'Target Infrastructure',
                'PNP Asingan Station Dispatch Desk',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryNavy,
      ),
    );
  }

  Widget _buildDeveloperCard(String name, String role, String description) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryNavy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: accentGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechDetailItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: primaryNavy,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFF1F5F9), height: 12);
  }
}
