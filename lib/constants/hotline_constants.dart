class HotlineItem {
  final String title;
  final String subtitle;
  final String phoneNumber;
  final String category; // 'POLICE', 'FIRE', 'MEDICAL', 'MDRRMO'
  final String iconType;

  const HotlineItem({
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    required this.category,
    required this.iconType,
  });
}

class HotlineConstants {
  static const List<HotlineItem> emergencyHotlines = [
    HotlineItem(
      title: 'National Emergency Hotline',
      subtitle: '24/7 Police & General Emergency Response',
      phoneNumber: '911',
      category: 'GENERAL',
      iconType: 'shield',
    ),
    HotlineItem(
      title: 'Bureau of Fire Protection (BFP)',
      subtitle: 'Fire Hazards & Search and Rescue',
      phoneNumber: '(02) 8426-0219',
      category: 'FIRE',
      iconType: 'fire',
    ),
    HotlineItem(
      title: 'Red Cross Emergency Hotline',
      subtitle: 'Ambulance & Medical Assistance',
      phoneNumber: '143',
      category: 'MEDICAL',
      iconType: 'medical',
    ),
    HotlineItem(
      title: 'Local MDRRMO Operations Center',
      subtitle: 'Disaster Risk & Local Municipal Response',
      phoneNumber: '09123456789',
      category: 'MDRRMO',
      iconType: 'radio',
    ),
  ];
}