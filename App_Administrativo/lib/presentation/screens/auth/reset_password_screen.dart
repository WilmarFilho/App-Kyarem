import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/auth/auth_input_label.dart';
import '../../widgets/auth/auth_input_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_feedback_message.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AuthService? authService;
  const ResetPasswordScreen({super.key, this.authService});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Validações de Interface
    if (password.isEmpty || password.length < 6) {
      setState(() => _error = "A senha deve ter pelo menos 6 caracteres");
      return;
    }
    if (password != confirm) {
      setState(() => _error = "As senhas não coincidem");
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // Chamada ao Service
      await _authService.updatePassword(password);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha atualizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        // Retorna para o login após sucesso
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = "Erro inesperado ao salvar senha.");
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
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 30 : 50),
                    child: const Text(
                      'NOVA SENHA', 
                      style: TextStyle(
                        fontFamily: 'Bebas Neue', 
                        fontSize: 40, 
                        letterSpacing: 2,
                        color: Colors.white,
                      )
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40), 
                        topRight: Radius.circular(40)
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crie uma nova senha segura para o seu acesso.', 
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.black54)
                          ),
                          const SizedBox(height: 30),
                          
                          const AuthInputLabel(label: 'Nova Senha:'),
                          AuthInputField(
                            controller: _passwordController,
                            placeholder: '••••••••',
                            obscureText: true,
                            isSmall: isSmallScreen,
                            svgAsset: 'assets/images/key.svg', // Adicionado para manter padrão
                          ),
                          
                          const SizedBox(height: 20),
                          
                          const AuthInputLabel(label: 'Confirmar Senha:'),
                          AuthInputField(
                            controller: _confirmPasswordController,
                            placeholder: '••••••••',
                            obscureText: true,
                            isSmall: isSmallScreen,
                            svgAsset: 'assets/images/key.svg', // Adicionado para manter padrão
                          ),
                          
                          AuthFeedbackMessage(errorMessage: _error),
                          
                          const SizedBox(height: 40),
                          
                          AuthButton(
                            text: 'SALVAR NOVA SENHA',
                            onPressed: _updatePassword,
                            isLoading: _loading,
                            isSmall: isSmallScreen,
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