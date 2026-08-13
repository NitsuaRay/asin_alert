import 'package:flutter/material.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final steps = ['pending', 'acknowledged', 'en_route', 'resolved'];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: [
        TimelineTile(
          label: 'Alert Sent to Police',
          isDone: true,
          isActive: currentIndex >= 0,
        ),
        TimelineTile(
          label: 'Police Acknowledged',
          isDone: currentIndex >= 1,
          isActive: currentIndex >= 1,
        ),
        TimelineTile(
          label: 'Responders En Route',
          isDone: currentIndex >= 2,
          isActive: currentIndex >= 2,
        ),
        TimelineTile(
          label: 'Incident Resolved',
          isDone: currentIndex >= 3,
          isActive: currentIndex >= 3,
        ),
      ],
    );
  }
}

class TimelineTile extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;

  const TimelineTile({
    super.key,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isDone ? Colors.green : Colors.grey.shade300,
        child: Icon(
          isDone ? Icons.check : Icons.circle,
          size: 16,
          color: isDone ? Colors.white : Colors.grey.shade600,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}