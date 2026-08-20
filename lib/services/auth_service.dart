import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up User with Badge Number support
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String phoneNumber,
    required String address,
    required String barangay,
    String? badgeNumber,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'address': address,
        'barangay': barangay,
        if (badgeNumber != null && badgeNumber.isNotEmpty)
          'badge_number': badgeNumber,
      },
    );
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Fetch User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    // Re-fetch fresh user object directly from Supabase Auth server
    final authResponse = await _supabase.auth.getUser();
    final user = authResponse.user;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final profileData = Map<String, dynamic>.from(response);
    profileData['email'] = user.email;

    return profileData;
  }

  // Update User Profile
  Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final profileData = Map<String, dynamic>.from(updatedData);

      // Extract 'email' so it NEVER touches the 'profiles' table directly
      final rawEmail = profileData.remove('email') as String?;
      final newEmail = rawEmail?.trim().toLowerCase();
      final currentEmail = user.email?.trim().toLowerCase();

      // 1. Invoke Edge Function for instant email update if changed
      if (newEmail != null && newEmail.isNotEmpty && newEmail != currentEmail) {
        final response = await _supabase.functions.invoke(
          'update-email',
          body: {'new_email': newEmail},
        );

        if (response.status != 200) {
          debugPrint('Edge Function error: ${response.data}');
          return false;
        }

        // Force Supabase client to re-fetch user and update local session cache
        await _supabase.auth.getUser();

        debugPrint('Email updated instantly via Edge Function to: $newEmail');
      }

      // 2. Update remaining fields in the 'profiles' table
      if (profileData.isNotEmpty) {
        await _supabase.from('profiles').update(profileData).eq('id', user.id);
      }

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Change Password via Edge Function
  Future<bool> changePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        debugPrint('Change password error: User is not authenticated.');
        return false;
      }

      final response = await _supabase.functions.invoke(
        'update-password',
        body: {'new_password': newPassword},
      );

      if (response.status != 200) {
        final errorMsg =
            response.data?['error'] ?? 'Failed to update password.';
        debugPrint('Edge Function error: $errorMsg');
        return false;
      }

      // Re-fetch user to refresh session metadata
      await _supabase.auth.getUser();

      debugPrint('Password updated successfully via Edge Function.');
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }
}
