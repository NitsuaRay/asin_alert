import 'package:asin_alert/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:asin_alert/services/auth_service.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  /// Custom account type label displayed in the confirmation message
  /// e.g. "establishment", "police responder", "admin"
  final String accountType;

  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  const LogoutConfirmationDialog({super.key, this.accountType = 'account'});

  /// Helper static method to trigger the dialog & handle sign-out workflow seamlessly
  static Future<void> show(
    BuildContext context, {
    String accountType = 'account',
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          LogoutConfirmationDialog(accountType: accountType),
    );

    if (confirm == true && context.mounted) {
      try {
        // 1. Show loading feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentGold,
                  ),
                ),
                SizedBox(width: 12),
                Text('Signing out...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: primaryNavy,
          ),
        );

        // 2. Perform sign out
        await AuthService().signOut();

        // 3. Show success message if context is still active
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AuthGate(),
            ), // Point to your AuthGate or LoginScreen
            (route) => false,
          );
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: accentGold, size: 20),
                  SizedBox(width: 12),
                  Text('Signed out successfully.'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: primaryNavy,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branded Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryNavy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentGold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: accentGold,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to log out of your ASIN Alert $accountType account?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Sign Out Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
