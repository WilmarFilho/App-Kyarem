import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String currentRoute;

  const BottomNavigationWidget({super.key, required this.currentRoute});

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

  // Widget padrão com os ícones
  Widget _buildStandardNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(Icons.home_filled, '/home'),
        _buildNavItem(Icons.emoji_events, '/modalidades'),
        _buildNavItem(Icons.settings, '/configuracoes'),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String route) {
    final isSelected = widget.currentRoute == route;
    return GestureDetector(
      onTap: !isSelected
          ? () => Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (route) => false,
            )
          : null,
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
