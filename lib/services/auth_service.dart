import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up User with Badge Number support
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'establishment' or 'police'
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
    final user = currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }
}