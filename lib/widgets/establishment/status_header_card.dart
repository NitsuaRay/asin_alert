import 'package:flutter/material.dart';

class StatusHeaderCard extends StatelessWidget {
  final String status;

  const StatusHeaderCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    String statusTitle;
    String statusDescription;

    switch (status) {
      case 'acknowledged':
        cardColor = Colors.orange.shade700;
        statusTitle = 'POLICE ACKNOWLEDGED';
        statusDescription = 'Police station received your alert!';
        break;
      case 'en_route':
        cardColor = Colors.blue.shade700;
        statusTitle = 'POLICE EN ROUTE 🚨';
        statusDescription = 'Responders are actively heading to your location.';
        break;
      case 'pending':
      default:
        cardColor = Colors.red.shade700;
        statusTitle = 'ALERT BROADCASTED 🚨';
        statusDescription = 'Waiting for police response team to accept...';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            statusTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}