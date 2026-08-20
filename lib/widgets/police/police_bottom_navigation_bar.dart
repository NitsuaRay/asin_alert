import 'package:flutter/material.dart';

class PoliceBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PoliceBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Branded Palette matched directly to the A.S.I.N. ALERT Badge Logo
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color darkNavy = Color(0xFF0B132B);
  static const Color accentGold = Color(0xFFD97706);
  static const Color lightGold = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: accentGold,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield_rounded,
                label: 'Dashboard',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentGold.withValues(alpha: .15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: accentGold.withValues(alpha: .4), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? lightGold : const Color(0xFF94A3B8),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}