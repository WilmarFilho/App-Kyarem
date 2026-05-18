import 'package:flutter/material.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import 'home_screen.dart';
import 'configuracoes_screen.dart';
import '../../../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isNavigatingFromTab = false;

  final AuthService _authService = AuthService();
  bool _isAdminRole = false;
  final bool _isPresidenteAtletica = false;
  bool _isArbitro = false;
  bool _perfilCarregado = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final profile = await _authService.getUserProfile();

    debugPrint('MainScreen perfil → isAdmin=${profile['isAdmin']} isArbitro=${profile['isArbitro']} role=${profile['role']} allowed=${profile['allowedAdminApp']}');

    if (!_authService.canAccessAdminApp(profile)) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    if (mounted) {
      setState(() {
        _isAdminRole = profile['isAdmin'] == true ||
            _authService.isAdminRole(profile['role'] as String? ?? '');
        _isArbitro = profile['isArbitro'] == true ||
            _authService.isArbitroRole(profile['role'] as String? ?? '');
        _perfilCarregado = true;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _isNavigatingFromTab = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) _isNavigatingFromTab = false;
        });
  }

  void _onPageChanged(int index) {
    if (!_isNavigatingFromTab) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aguarda o perfil ser carregado antes de renderizar o app
    // para evitar flickering/tela branca ao inicializar.
    if (!_perfilCarregado) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B2B4B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Carregando...',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              // Passa as flags de permissão diretamente ao HomeScreen
              // para evitar duplicação de chamadas HTTP e inconsistência de estado.
              HomeScreen(
                isMainScreenChild: true,
                isAdminOverride: _isAdminRole,
                isArbitroOverride: _isArbitro,
                perfilJaCarregado: _perfilCarregado,
              ),
              const ConfiguracoesScreen(isMainScreenChild: true),
            ],
          ),
          BottomNavigationWidget(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
            isAdmin: _isAdminRole,
            isPresidenteAtletica: _isPresidenteAtletica,
            isArbitro: _isArbitro,
          ),
        ],
      ),
    );
  }
}
