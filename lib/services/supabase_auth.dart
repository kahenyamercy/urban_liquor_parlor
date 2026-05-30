import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_liquor_parlor/config/supabase_config.dart';

class AuthService {
  /// Signs up a new user, validates legal drinking age, and creates a user profile.
  Future<void> signUp({
    required String email,
    required String password,
    required DateTime dateOfBirth,
    required String fullName,
  }) async {
    try {
      // 1. Precise Age Validation (Accounts for leap years)
      final now = DateTime.now();
      int age = now.year - dateOfBirth.year;
      if (now.month < dateOfBirth.month ||
          (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
        age--;
      }

      if (age < 18) {
        throw const AuthException('You must be 18 or older to register.');
      }

      // 2. Execute Supabase Auth Signup
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName, // Stores temporary metadata inside Auth schema
        },
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw const AuthException('Signup failed. Please try again.');
      }

      
      await supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        'role': 'customer',
      });
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during signup: $e');
    }
  }

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in. Please check your connection.');
    }
  }

  /// Logs the current user out of the application.
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  /// Retrieves the current authenticated user's custom profile data.
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Safer than .single(), returns null if not found instead of throwing an error

      return data;
    } catch (e) {
      // Log error internally if you have a logging system
      return null;
    }
  }
}
