import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Verifica se existe sessão ativa
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  // --- LOGIN ---
  Future<User?> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );

    if (response.user != null) {
      await _handleCredentialsPreference(email, password, rememberMe);
    }
    return response.user;
  }

  // --- RECUPERAÇÃO DE SENHA ---
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'apppublico://reset-password',
    );
  }

  // --- REGISTRO DE USUÁRIO ---
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  // --- TROCAR SENHA ---
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // --- PERSISTÊNCIA LOCAL (SharedPreferences) ---
  Future<void> _handleCredentialsPreference(
    String email,
    String password,
    bool remember,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('saved_email') ?? '',
      'password': prefs.getString('saved_password') ?? '',
      'remember': prefs.getBool('remember_me') ?? false,
    };
  }
}
