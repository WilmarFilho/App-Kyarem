import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';
import '../../widgets/auth/auth_feedback.dart';
import '../../widgets/auth/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  final _nomeCompletoController = TextEditingController();
  final _nomeExibicaoController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nomeCompletoController.dispose();
    _nomeExibicaoController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _normalizeCpf(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _submit() async {
    final cpf = _normalizeCpf(_cpfController.text);

    if (_nomeCompletoController.text.trim().isEmpty ||
        _nomeExibicaoController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        cpf.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _error = 'Preencha todos os campos obrigatorios.');
      return;
    }

    if (cpf.length != 11) {
      setState(() => _error = 'Informe um CPF valido com 11 digitos.');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _error = 'A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'As senhas nao coincidem.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final response = await _authService.signUp(
        nomeCompleto: _nomeCompletoController.text,
        nomeExibicao: _nomeExibicaoController.text,
        email: _emailController.text,
        cpf: cpf,
        password: _passwordController.text,
      );

      final needsConfirmation = response.session == null;
      setState(() {
        _success = needsConfirmation
            ? 'Conta criada. Verifique seu e-mail para confirmar o cadastro.'
            : 'Conta criada com sucesso. Voce ja pode acessar o app.';
      });

      if (!needsConfirmation && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() {
        _error =
            'Nao foi possivel concluir o cadastro. Se o CPF ja existir, use outra conta ou revise os dados.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '',
      subtitle: '',
      child: ListView(
        children: [
          TextField(
            controller: _nomeCompletoController,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeExibicaoController,
            decoration: const InputDecoration(
              labelText: 'Nome de exibicao',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
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
            controller: _cpfController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'CPF',
              prefixIcon: Icon(Icons.credit_card_rounded),
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
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          AuthFeedback(error: _error, success: _success),
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
                : const Text('Cadastrar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ja tenho conta'),
          ),
        ],
      ),
    );
  }
}
