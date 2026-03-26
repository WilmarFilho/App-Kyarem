import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_input_label.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_feedback_message.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthService _authService = widget.authService ?? AuthService(); // Instância do Service
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // 1. Validações de UI/Negócio
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = "Preencha todos os campos");
      return;
    }

    if (password.length < 6) {
      setState(() => _error = "A senha deve ter pelo menos 6 caracteres");
      return;
    }

    if (password != confirm) {
      setState(() => _error = "As senhas não coincidem");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      // 2. Chamada ao Service
      await _authService.signUp(
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() {
          _success = "Conta criada! Verifique seu e-mail para confirmar.";
        });
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = "Ocorreu um erro inesperado.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 393;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            const GradientBackground(),
            Column(
              children: [
                AuthHeader(isSmall: isSmallScreen),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 24 : 32,
                        isSmallScreen ? 30 : 40,
                        isSmallScreen ? 24 : 32,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova Conta',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 28 : 34,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Crie seu acesso para participar dos eventos.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.white54,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 25 : 30),
                          
                          const AuthInputLabel(label: 'E-mail:'),
                          AuthInputField(
                            controller: _emailController,
                            placeholder: 'exemplo@email.com',
                            svgAsset: 'assets/images/envelope.svg',
                            keyboardType: TextInputType.emailAddress,
                            isSmall: isSmallScreen,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 15 : 20),
                          
                          const AuthInputLabel(label: 'Senha:'),
                          AuthInputField(
                            controller: _passwordController,
                            placeholder: '••••••••',
                            svgAsset: 'assets/images/key.svg',
                            obscureText: true,
                            isSmall: isSmallScreen,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 15 : 20),
                          
                          const AuthInputLabel(label: 'Confirmar Senha:'),
                          AuthInputField(
                            controller: _confirmPasswordController,
                            placeholder: '••••••••',
                            svgAsset: 'assets/images/key.svg',
                            obscureText: true,
                            isSmall: isSmallScreen,
                          ),
                          
                          AuthFeedbackMessage(
                            errorMessage: _error,
                            successMessage: _success,
                          ),
                          
                          SizedBox(height: isSmallScreen ? 30 : 35),
                          
                          AuthButton(
                            text: 'CADASTRAR',
                            onPressed: _signUp,
                            isLoading: _loading,
                            isSmall: isSmallScreen,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Já tem uma conta? '),
                                    TextSpan(
                                      text: 'Entrar agora',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
}