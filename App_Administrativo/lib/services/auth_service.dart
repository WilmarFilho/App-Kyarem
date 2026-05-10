import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient? _supabaseOverride;
  final Dio _dio;

  /// Retorna o client injetado ou o singleton global (lazy).
  /// O acesso ao Supabase.instance.client só ocorre durante
  /// uma chamada real — nunca na construção da classe.
  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  AuthService({SupabaseClient? supabase, Dio? dio})
    : _supabaseOverride = supabase,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://kyarem.nkwflow.com/api/v1',
              connectTimeout: const Duration(seconds: 10),
            ),
          );

  // Verifica se existe sessão ativa
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  // --- BUSCA DO ROLE DO USUÁRIO ---
  Future<String> getUserRole() async {
    final profile = await getUserProfile();
    return profile['role'] as String? ?? 'user';
  }

  // --- BUSCA DO PERFIL COMPLETO VIA BACKEND ---
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = currentUser;
    if (user == null) return _defaultProfile();
    try {
      final session = currentSession;
      final token = session?.accessToken;
      if (token == null || token.isEmpty) {
        return _defaultProfile();
      }

      final response = await _dio.get(
        '/profiles/me/access',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      return {
        'id': data['id'],
        'nomeExibicao': data['nomeExibicao'],
        'fotoUrl': data['fotoUrl'],
        'telefone': data['telefone'],
        'email': data['email'] ?? user.email,
        'role': data['role'] ?? 'user',
        'isAdmin': data['isAdmin'] == true,
        'isArbitro': data['isReferee'] == true,
        'allowedAdminApp': data['allowedAdminApp'] == true,
      };
    } catch (e) {
      debugPrint('⚠️ AuthService.getUserProfile ERRO: $e');
      return _defaultProfile();
    }
  }

  bool isAdminRole(String role) => role.toLowerCase() == 'admin';

  bool isArbitroRole(String role) => role.toLowerCase() == 'referee';

  bool canAccessAdminApp(Map<String, dynamic> profile) =>
      profile['allowedAdminApp'] == true;

  Map<String, dynamic> _defaultProfile() {
    return {
      'id': null,
      'nomeExibicao': null,
      'fotoUrl': null,
      'telefone': null,
      'email': currentUser?.email,
      'role': 'user',
      'isAdmin': false,
      'isArbitro': false,
      'allowedAdminApp': false,
    };
  }

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

  /// Verifica via backend se o [email] pertence a um usuário
  /// com acesso ao app administrativo (role admin ou árbitro).
  ///
  /// Chama [GET /profiles/check-admin-access?email=<email>].
  /// Retorna `true` se permitido, `false` se negado.
  /// Em caso de erro de rede ou endpoint inexistente → lança exceção.
  Future<bool> verificarEmailPermitido(String email) async {
    try {
      final res = await _dio.get(
        '/profiles/check-admin-access',
        queryParameters: {'email': email.trim().toLowerCase()},
      );
      final data = res.data;
      if (data is Map) {
        // Novo endpoint retorna { "allowed": true/false }
        // Campos legados mantidos por compatibilidade
        return data['allowed'] == true ||
            data['allowedAdminApp'] == true ||
            data['isAdmin'] == true ||
            data['isReferee'] == true;
      }
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 403) {
        // Endpoint não existe ainda no backend ou acesso negado
        return false;
      }
      // Erro de rede ou outro → deixa passar (fail-open para não bloquear admins)
      debugPrint('verificarEmailPermitido: erro de rede ($e) — permitindo por cautela');
      return true;
    } catch (e) {
      debugPrint('verificarEmailPermitido: erro inesperado ($e) — permitindo por cautela');
      return true;
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'apparbitro://reset-password',
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
