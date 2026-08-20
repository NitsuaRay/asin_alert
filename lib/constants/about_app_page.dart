import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'About ASIN Alert',
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
              // --- APP LOGO & HEADER ---
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
                      'A.S.I.N. Alert',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Asingan Security & Incident Notifier',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentGold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Municipal Emergency Dispatch & Response System',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // --- MISSION & OVERVIEW ---
              _buildSectionTitle('System Overview & Mandate'),
              const SizedBox(height: 8),
              const Text(
                'A.S.I.N. Alert (Advanced System for Incident Notification) is an institutional-grade public safety platform developed in strategic partnership with the Philippine National Police (PNP) Asingan Police Station. The platform bridges the gap between commercial establishments, local barangay monitoring posts, and frontline police dispatchers to drastically cut down emergency response latency.',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // --- OPERATIONAL WORKFLOW ---
              _buildSectionTitle('Emergency Response Workflow'),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.touch_app_rounded,
                '1. Immediate Panic Trigger',
                'Verified users can instantly broadcast priority distress signals from their registered establishments, bypassing traditional communication bottlenecks.',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.location_on_rounded,
                '2. Precise Telemetry & Mapping',
                'Active alerts automatically package real-time geographical coordinates, establishment profiles, and caller contact info directly to the police desk.',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.local_police_rounded,
                '3. Coordinated Dispatch',
                'Duty officers receive immediate audio-visual alerts on the dispatch dashboard, enabling rapid tactical deployment and incident resolution tracking.',
              ),
              const SizedBox(height: 20),

              // --- SECURITY & COMPLIANCE ---
              _buildSectionTitle('Security & Statutory Compliance'),
              const SizedBox(height: 8),
              const Text(
                'Designed with strict adherence to the Data Privacy Act of 2012 (RA 10173). All user data, device tokens, and incident logs are safeguarded using Supabase Row Level Security (RLS) policies and encrypted via TLS/SSL infrastructure to ensure absolute confidentiality and legal accountability.',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // --- TARGET AUDIENCE ---
              _buildSectionTitle('Platform Access & Stakeholders'),
              const SizedBox(height: 12),
              _buildInfoRow('Primary Responders', 'PNP Asingan Active Duty Officers'),
              _buildDivider(),
              _buildInfoRow('Reporting Partners', 'Verified Local Business Establishments'),
              _buildDivider(),
              _buildInfoRow('Territorial Scope', 'Municipality of Asingan, Pangasinan'),
              _buildDivider(),
              _buildInfoRow('Administrative Control', 'PNP Asingan Police Station Command Desk'),
              const SizedBox(height: 24),

              // --- FOOTER MOTTO ---
              Center(
                child: Text(
                  'Protecting Asingan, One Response at a Time.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
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

  Widget _buildFeatureItem(IconData icon, String title, String description) {
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