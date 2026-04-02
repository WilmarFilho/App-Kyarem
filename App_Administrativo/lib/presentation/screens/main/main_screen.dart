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
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              HomeScreen(isMainScreenChild: true),
              ConfiguracoesScreen(isMainScreenChild: true),
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
