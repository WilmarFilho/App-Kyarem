import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() => _remember = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CAPTURANDO AS DIMENSÕES DA TELA PARA RESPONSIVIDADE
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 393;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6),
            radius: 1.3,
            colors: [
              Color.fromARGB(255, 160, 255, 228),
              Color.fromARGB(255, 232, 255, 209),
              Color.fromARGB(255, 204, 255, 240),
            ],
            stops: [0.0, 0.54, 1.0],
          ),
        ),
        child: Column(
          children: [
            // --- TOPO (DINÂMICO) ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 25 : 40),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/meteor.svg',
                      width: isSmallScreen ? 60 : 80,
                      height: isSmallScreen ? 60 : 80,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 16),
                    Text(
                      'KYAREM EVENTOS',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontWeight: FontWeight.w400,
                        fontSize: isSmallScreen ? 42 : 52,
                        color: Colors.black,
                        height: 1.0,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Área Administrativa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Color.fromRGBO(0, 0, 0, 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

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
                    20
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
                      
                      _buildInputLabel('Seu e-mail:'),
                      _buildFigmaInput(
                        controller: _emailController,
                        placeholder: 'exemplo@email.com',
                        svgAsset: 'assets/images/envelope.svg',
                        keyboardType: TextInputType.emailAddress,
                        isSmall: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 15 : 25),
                      
                      _buildInputLabel('Sua senha:'),
                      _buildFigmaInput(
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
                                height: 20, width: 20,
                                child: Checkbox(
                                  value: _remember,
                                  onChanged: (val) => setState(() => _remember = val ?? false),
                                  activeColor: const Color(0xFFF85C39),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lembrar',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: isSmallScreen ? 12 : 13, color: Colors.black54),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Esqueci a senha',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: isSmallScreen ? 12 : 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      
                      // Mensagens de Feedback
                      if (_error != null) _buildFeedbackText(_error!, Colors.redAccent),
                      if (_success != null) _buildFeedbackText(_success!, Colors.green),
                      
                      SizedBox(height: isSmallScreen ? 25 : 35),
                      
                      _buildFigmaLoginButton(isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 20 : 25),
                      
                      Center(
                        child: SizedBox(
                          width: 260,
                          child: Text(
                            'Não tem conta ainda? Solicite ao administrador',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.black.withOpacity(0.5),
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
      ),
    );
  }

  // --- COMPONENTES AUXILIARES ---

  Widget _buildFeedbackText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _buildFigmaInput({
    required TextEditingController controller,
    required String placeholder,
    required String svgAsset,
    bool obscureText = false,
    TextInputType? keyboardType,
    required bool isSmall,
  }) {
    return Container(
      height: isSmall ? 48 : 56,
      decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SvgPicture.asset(
              svgAsset, width: 18, height: 18,
              colorFilter: ColorFilter.mode(const Color(0xFFF85C39).withOpacity(0.6), BlendMode.srcIn),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              // IMPORTANTE: Remove autocorreção e primeira letra maiúscula para evitar erros de login
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              cursorColor: const Color(0xFFF85C39),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.2), fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(right: 16),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaLoginButton(bool isSmall) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 50 : 58,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF85C39),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Entrar', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: isSmall ? 16 : 18)),
      ),
    );
  }

  // --- LÓGICA CORRIGIDA ---

  Future<void> _login() async {
    // Normalização dos dados para evitar erros de teclado no celular físico
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Preencha todos os campos");
      return;
    }
    
    setState(() { _loading = true; _error = null; });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (_remember) {
          await prefs.setString('saved_email', email);
          await prefs.setString('saved_password', password);
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.clear();
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      // Diferencia erro de rede de erro de credencial
      setState(() => _error = e.message.contains("network") ? "Sem conexão com a internet" : "E-mail ou senha incorretos");
    } catch (e) {
      setState(() => _error = "Erro de conexão. Verifique sua internet.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = "Digite seu e-mail primeiro");
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: 'apparbitro://reset-password');
      setState(() { _success = "E-mail de recuperação enviado!"; _error = null; });
    } catch (e) {
      setState(() { _error = "Erro ao enviar e-mail"; _success = null; });
    }
  }
}