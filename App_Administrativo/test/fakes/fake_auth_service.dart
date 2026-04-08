import 'package:kyarem_eventos/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementação fake de [AuthService] para uso exclusivo em testes de widget.
/// Não acessa Supabase, SharedPreferences nem nenhum recurso externo.
class FakeAuthService extends AuthService {
  final String role;
  final bool hasSession;
  String? loginError; // Se não nulo, simula AuthException ao fazer login

  FakeAuthService({
    this.role = 'admin',
    this.hasSession = false,
    this.loginError,
  });

  @override
  Session? get currentSession => null; // Nunca há sessão nos testes

  @override
  User? get currentUser => null;

  @override
  Future<String> getUserRole() async => role;

  @override
  Future<Map<String, dynamic>> getUserProfile() async =>
      {'role': role, 'atleticaId': null};

  @override
  Future<Map<String, dynamic>> getSavedCredentials() async =>
      {'email': '', 'password': '', 'remember': false};

  @override
  Future<User?> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (loginError != null) {
      throw AuthException(loginError!);
    }
    return null; // Login bem-sucedido mas sem usuário (para testes de UI)
  }

  @override
  Future<void> resetPassword(String email) async {
    // No-op em testes
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    throw UnimplementedError('FakeAuthService.updatePassword não implementado');
  }

  @override
  Future<void> logout() async {
    // No-op em testes
  }
}
