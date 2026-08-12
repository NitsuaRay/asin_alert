import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // 1. Sign Up User (Metadata automatically triggers profile creation in Postgres)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'establishment' or 'police'
    required String phoneNumber,
    required String address,
    required String barangay,
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
      },
    );
  }

  // 2. Sign In User
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 4. Fetch User Profile & Role
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