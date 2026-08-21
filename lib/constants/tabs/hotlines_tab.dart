import 'package:flutter/material.dart';
import 'package:asin_alert/constants/hotline_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class HotlinesTab extends StatelessWidget {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color borderSlate = Color(0xFFE2E8F0);

  const HotlinesTab({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanedNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place call to $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap any hotline below to dial directly in case of an immediate emergency.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...HotlineConstants.emergencyHotlines.map((item) => _buildHotlineCard(context, item)),
      ],
    );
  }

  Widget _buildHotlineCard(BuildContext context, HotlineItem item) {
    IconData icon;
    Color iconBg;

    switch (item.iconType) {
      case 'fire':
        icon = Icons.local_fire_department_rounded;
        iconBg = const Color(0xFFEF4444);
        break;
      case 'medical':
        icon = Icons.medical_services_rounded;
        iconBg = const Color(0xFF10B981);
        break;
      case 'radio':
        icon = Icons.cell_tower_rounded;
        iconBg = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.shield_rounded;
        iconBg = const Color(0xFF3B82F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconBg, size: 22),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryNavy)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(item.phoneNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: iconBg)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _makePhoneCall(context, item.phoneNumber),
          style: ElevatedButton.styleFrom(
            backgroundColor: iconBg,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            elevation: 0,
          ),
          child: const Icon(Icons.call_rounded, size: 18),
        ),
      ),
    );
  }
}