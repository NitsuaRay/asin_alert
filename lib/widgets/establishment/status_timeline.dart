import 'package:flutter/material.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
  });

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'key': 'pending',
        'title': 'Alert Dispatched',
        'subtitle': 'Signal sent to emergency response center'
      },
      {
        'key': 'acknowledged',
        'title': 'Responders Acknowledged',
        'subtitle': 'Dispatch team is reviewing coordinates'
      },
      {
        'key': 'en_route',
        'title': 'Units En Route',
        'subtitle': 'Tactical squad is moving to site'
      },
      {
        'key': 'resolved',
        'title': 'Incident Resolved',
        'subtitle': 'Situation secured by emergency personnel'
      },
    ];

    final stepKeys = ['pending', 'acknowledged', 'en_route', 'resolved'];
    final currentIndex = stepKeys.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final isDone = currentIndex > index;
        final isCurrent = currentIndex == index;
        final isLast = index == steps.length - 1;

        return TimelineItem(
          title: steps[index]['title']!,
          subtitle: steps[index]['subtitle']!,
          isDone: isDone,
          isCurrent: isCurrent,
          isLast: isLast,
        );
      }),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator Column
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? Colors.green.shade600
                      : isCurrent
                          ? accentGold
                          : Colors.grey.shade200,
                  border: isCurrent
                      ? Border.all(color: primaryNavy, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: accentGold.withValues(alpha: .4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : isCurrent
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? Colors.green.shade600 : Colors.grey.shade200,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Text Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent || isDone ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? primaryNavy
                          : isDone
                              ? Colors.black87
                              : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent
                          ? primaryNavy.withValues(alpha: .7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}