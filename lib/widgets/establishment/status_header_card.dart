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

  static const Color accentGold = Color(0xFFD97706);

  Map<String, dynamic> _getCategoryDetails() {
    switch (category.toLowerCase()) {
      case 'fire':
        return {
          'label': 'FIRE DEPARTMENT',
          'icon': Icons.local_fire_department_rounded,
        };
      case 'medical':
        return {
          'label': 'MEDICAL EMERGENCY',
          'icon': Icons.medical_services_rounded,
        };
      case 'crime':
      case 'security_hostage':
        return {
          'label': isSilent ? 'SILENT THREAT / CRIME' : 'CRIME / THREAT',
          'icon': Icons.security_rounded,
        };
      case 'police':
      default:
        return {
          'label': 'POLICE DISPATCH',
          'icon': Icons.local_police_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final catInfo = _getCategoryDetails();
    final String catLabel = catInfo['label'];
    final IconData catIcon = catInfo['icon'];

    List<Color> gradientColors;
    String statusTitle;
    String statusDescription;

    switch (status) {
      case 'acknowledged':
        gradientColors = [const Color(0xFFD97706), const Color(0xFFB45309)];
        statusTitle = 'ALERT ACKNOWLEDGED';
        statusDescription =
            'Response team has received and confirmed your signal!';
        break;
      case 'en_route':
        gradientColors = [const Color(0xFF1E40AF), const Color(0xFF1E3A8A)];
        statusTitle = 'RESPONDERS EN ROUTE 🚔';
        statusDescription =
            'Units are actively dispatched and heading to your location.';
        break;
      case 'pending':
      default:
        gradientColors = [const Color(0xFFDC2626), const Color(0xFF991B1B)];
        statusTitle = 'ALERT BROADCASTED 🚨';
        statusDescription =
            'Broadcasting signal. Waiting for responders to connect...';
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: .35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ASIN Logo Watermark
          Positioned(
            right: -15,
            bottom: -15,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/asinLogo.png',
                height: 140,
                width: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield_outlined,
                  size: 140,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🏷️ Category & Silent Mode Badges
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .3),
                          width: 1,
                        ),
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
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSilent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentGold.withValues(alpha: .6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.volume_off_rounded,
                                color: accentGold, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'SILENT ALARM',
                              style: TextStyle(
                                color: accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Status Title
                Text(
                  statusTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                // Description Text
                Text(
                  statusDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}