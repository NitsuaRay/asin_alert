import 'package:flutter/material.dart';

class StatusHeaderCard extends StatelessWidget {
  final String status;
  final String category;
  final bool isSilent;

  const StatusHeaderCard({
    super.key,
    required this.status,
    required this.category,
    this.isSilent = false,
  });

  /// Helper to get Category Display Info (Icon, Label, Color)
  Map<String, dynamic> _getCategoryDetails() {
    switch (category.toLowerCase()) {
      case 'fire':
        return {
          'label': 'FIRE DEPARTMENT',
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.deepOrange.shade600,
        };
      case 'medical':
        return {
          'label': 'MEDICAL EMERGENCY',
          'icon': Icons.medical_services_rounded,
          'color': Colors.red.shade600,
        };
      case 'crime':
      case 'security_hostage':
        return {
          'label': isSilent ? 'SILENT THREAT / CRIME' : 'CRIME / THREAT',
          'icon': Icons.security_rounded,
          'color': Colors.purple.shade700,
        };
      case 'police':
      default:
        return {
          'label': 'POLICE DISPATCH',
          'icon': Icons.local_police_rounded,
          'color': Colors.blue.shade700,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final catInfo = _getCategoryDetails();
    final String catLabel = catInfo['label'];
    final IconData catIcon = catInfo['icon'];

    Color cardColor;
    String statusTitle;
    String statusDescription;

    switch (status) {
      case 'acknowledged':
        cardColor = Colors.orange.shade800;
        statusTitle = '$catLabel ACKNOWLEDGED';
        statusDescription = 'Response team has received and confirmed your alert!';
        break;
      case 'en_route':
        cardColor = Colors.blue.shade800;
        statusTitle = '$catLabel EN ROUTE 🚨';
        statusDescription = 'Responders are actively heading to your location.';
        break;
      case 'pending':
      default:
        cardColor = Colors.red.shade800;
        statusTitle = 'ALERT BROADCASTED 🚨';
        statusDescription = 'Waiting for emergency responders to accept...';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🏷️ Category & Silent Mode Pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      catLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSilent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.volume_off, color: Colors.amber, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SILENT ALARM',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Status Title
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Description Text
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}