import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_input_label.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../../services/auth_service.dart';
import '../../widgets/auth/auth_feedback_message.dart';

class LoginScreen extends StatefulWidget {
  /// [authService] é opcional — usado apenas em testes.
  final AuthService? authService;
  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _success;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _loadSavedCredentials();
  }

  void _checkInitialSession() {
    if (_authService.currentSession != null) {
      Future.microtask(_redirectIfAuthorized);
    }
  }

  Future<void> _redirectIfAuthorized() async {
    final profile = await _authService.getUserProfile();
    if (!mounted) return;

    if (_authService.canAccessAdminApp(profile)) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _error = 'Este app é exclusivo para admins e árbitros.';
    });
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await _authService.getSavedCredentials();
    if (creds['remember']) {
      setState(() {
        _emailController.text = creds['email'];
        _passwordController.text = creds['password'];
        _remember = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // CAPTURANDO AS DIMENSÕES DA TELA PARA RESPONSIVIDADE
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 393;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Fundo com Gradiente
            const GradientBackground(),
            // Conteúdo Principal
            Column(
              children: [
                // --- TOPO (DINÂMICO) ---
                AuthHeader(isSmall: isSmallScreen),

                // --- CORPO (DINÂMICO) ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      // Redução gradual de padding lateral
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 24 : 32,
                        isSmallScreen ? 30 : 45,
                        isSmallScreen ? 24 : 32,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 28 : 34,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 25 : 35),

                          const AuthInputLabel(label: 'Seu e-mail:'),
                          AuthInputField(
                            controller: _emailController,
                            placeholder: 'exemplo@email.com',
                            svgAsset: 'assets/images/envelope.svg',
                            keyboardType: TextInputType.emailAddress,
                            isSmall: isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 15 : 25),

                          const AuthInputLabel(label: 'Sua senha:'),
                          AuthInputField(
                            controller: _passwordController,
                            placeholder: '••••••••',
                            svgAsset: 'assets/images/key.svg',
                            obscureText: true,
                            isSmall: isSmallScreen,
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _remember,
                                      onChanged: (val) => setState(
                                        () => _remember = val ?? false,
                                      ),
                                      activeColor: const Color(0xFFF85C39),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lembrar',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _resetPassword,
                                child: Text(
                                  'Esqueci a senha',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: isSmallScreen ? 12 : 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Mensagens de Feedback
                          AuthFeedbackMessage(
                            errorMessage: _error,
                            successMessage: _success,
                          ),

                          SizedBox(height: isSmallScreen ? 25 : 35),

                          AuthButton(
                            text: 'Entrar',
                            onPressed: _login,
                            isLoading: _loading,
                            isSmall: isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 25),

                          Center(
                            child: SizedBox(
                              width: 260,
                              child: Text(
                                'Não tem conta ainda? Solicite ao administrador',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: isSmallScreen ? 11 : 12,
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withValues(alpha: 0.5),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = "Preencha todos os campos");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
        rememberMe: _remember,
      );

      if (user != null && mounted) {
        final profile = await _authService.getUserProfile();
        if (!mounted) return;

        if (_authService.canAccessAdminApp(profile)) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          await _authService.logout();
          if (!mounted) return;
          setState(() {
            _error =
                'Acesso restrito. Este app é exclusivo para administradores e árbitros.';
          });
        }
      }
    } on AuthException catch (e) {
      setState(
        () => _error = e.message.contains("network")
            ? "Sem conexão"
            : "E-mail ou senha incorretos",
      );
    } catch (e) {
      setState(() => _error = "Erro inesperado.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Digite seu e-mail primeiro");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      // 1º — Verifica se o email é de um usuário com acesso ao app admin
      final permitido = await _authService.verificarEmailPermitido(email);
      if (!mounted) return;

      if (!permitido) {
        setState(() {
          _error = 'E-mail não encontrado ou sem permissão de acesso.';
          _loading = false;
        });
        return;
      }

      // 2º — Email autorizado: dispara o reset
      await _authService.resetPassword(email);
      if (!mounted) return;
      setState(() {
        _success = "E-mail de recuperação enviado!";
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = "Erro ao enviar e-mail. Tente novamente.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
