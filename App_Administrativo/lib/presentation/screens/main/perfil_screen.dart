import 'package:flutter/material.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  String _userRole = 'aluno';

  bool get _isAdminRole =>
      _userRole == 'admin' ||
      _userRole == 'super_admin' ||
      _userRole == 'delegado';

  bool get _isPresidenteAtletica => _userRole == 'presidente_atletica';
  bool get _isArbitro => _userRole == 'arbitro';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final profile = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userRole = profile['role'] as String? ?? 'aluno';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com Gradiente
          const GradientBackground(),

          // Conteúdo Principal
          const SafeArea(
            child: Center(
              child: Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // Barra de Navegação
          BottomNavigationWidget(
            currentRoute: '/perfil',
            isAdmin: _isAdminRole,
            isPresidenteAtletica: _isPresidenteAtletica,
            isArbitro: _isArbitro,
          ),
        ],
      ),
    );
  }
}