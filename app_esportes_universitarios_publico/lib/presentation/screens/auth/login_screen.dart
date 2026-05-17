import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';
import '../../widgets/auth/auth_feedback.dart';
import '../../widgets/auth/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Preencha e-mail e senha para continuar.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e));
    } catch (_) {
      setState(
        () => _error = 'Nao foi possivel entrar agora. Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _translateAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('email not confirmed') ||
        message.contains('invalid email or password')) {
      return 'E-mail ou senha invalidos.';
    }

    if (message.contains('network') || message.contains('socket')) {
      return 'Sem conexao no momento. Verifique sua internet e tente novamente.';
    }

    if (message.contains('too many requests')) {
      return 'Muitas tentativas seguidas. Aguarde um pouco e tente novamente.';
    }

    return 'Nao foi possivel entrar com esses dados. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Acesse o app geral',
      subtitle:
          'Acompanhe campeonatos, estatisticas, torça para as atleticas e etc.',
      child: ListView(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          AuthFeedback(error: _error),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Entrar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text('Criar conta'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: const Text('Recuperar senha'),
          ),
        ],
      ),
    );
  }
}
