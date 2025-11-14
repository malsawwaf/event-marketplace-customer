import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Check if user is logged in
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if customer profile exists
  Future<bool> hasCustomerProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final response = await _supabase
          .from('customers')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking customer profile: $e');
      return false;
    }
  }

  /// Create customer profile
  Future<void> createCustomerProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? profileImageUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('No user logged in');

      print('🔵 Creating customer profile for user: $userId');

      final data = {
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'profile_image_url': profileImageUrl,
      };

      print('🔵 Profile data: $data');

      await _supabase.from('customers').insert(data);

      print('✅ Customer profile created successfully');
    } catch (e) {
      print('❌ Error creating customer profile: $e');
      rethrow;
    }
  }

  /// Get customer profile
  Future<Map<String, dynamic>?> getCustomerProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('customers')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting customer profile: $e');
      return null;
    }
  }

  /// Update customer profile
  Future<void> updateCustomerProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('customers').update(updates).eq('id', userId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('No user logged in');

      // Delete customer profile (cascades will handle related data)
      await _supabase.from('customers').delete().eq('id', userId);

      // Sign out
      await signOut();
    } catch (e) {
      rethrow;
    }
  }
}
