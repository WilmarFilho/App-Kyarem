import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String? currentRoute;
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;

  const BottomNavigationWidget({
    super.key, 
    this.currentRoute,
    this.currentIndex,
    this.onTabSelected,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  bool _menuAdicionarAberto = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_menuAdicionarAberto)
          GestureDetector(
            onTap: () => setState(() => _menuAdicionarAberto = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    // Verifica se estamos na tela de perfil
    final isPerfil = widget.currentRoute == '/perfil';

    return Positioned(
      bottom:
          0, // Subi um pouco para não colar na borda do sistema (estilo flutuante)
      left: 0,
      right: 0,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFFF22F1D),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF22F1D).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: isPerfil ? _buildBackButton() : _buildStandardNav(),
      ),
    );
  }

  // Widget para quando estiver no Perfil
  Widget _buildBackButton() {
    return InkWell(
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
      borderRadius: BorderRadius.circular(40),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text(
            'VOLTAR PARA O INÍCIO',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(Icons.home_filled, '/home', 0),
        _buildNavItem(Icons.emoji_events, '/modalidades', 1),
        _buildNavItem(Icons.settings, '/configuracoes', 2),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String route, int index) {
    final isSelected = widget.currentIndex != null
        ? widget.currentIndex == index
        : widget.currentRoute == route;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(index);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (route) => false,
            );
          }
        }
      },
      child: Icon(
        icon,
        color: isSelected
            ? Colors.white
            : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
        size: 28,
      ),
    );
  }
}
