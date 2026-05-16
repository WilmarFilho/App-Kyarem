import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Session? get currentSession => client.auth.currentSession;
  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  Future<AuthResponse> signUp({
    required String nomeCompleto,
    required String nomeExibicao,
    required String email,
    required String cpf,
    required String password,
  }) {
    return client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password.trim(),
      data: {
        'nome_completo': nomeCompleto.trim(),
        'nome_exibicao': nomeExibicao.trim(),
        'cpf': cpf,
        'role': 'USER',
      },
      emailRedirectTo: 'kyarem-esportes://login-callback',
    );
  }

  Future<void> sendPasswordReset(String email) {
    return client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'kyarem-esportes://reset-password',
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return client.auth.updateUser(UserAttributes(password: password.trim()));
  }

  Future<void> signOut() => client.auth.signOut();
}
