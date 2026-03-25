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
        // Overlay Escuro quando o menu está aberto
        if (_menuAdicionarAberto)
          GestureDetector(
            onTap: () => setState(() => _menuAdicionarAberto = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.4),
            ),
          ),

        // Barra de Navegação
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: const Color(
            0xFFF22F1D,
          ), // Pure black to contrast with background
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFF22F1D).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF22F1D).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: widget.currentRoute != '/home'
                  ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    )
                  : null,
              child: Icon(
                Icons.home_filled,
                color: widget.currentRoute == '/home'
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(137, 11, 6, 6),
                size: 28,
              ),
            ),

            GestureDetector(
              onTap: widget.currentRoute != '/modalidades'
                  ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/modalidades',
                      (route) => false,
                    )
                  : null,
              child: Icon(
                Icons.emoji_events,
                color: widget.currentRoute == '/modalidades'
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(136, 6, 0, 0),
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: widget.currentRoute != '/configuracoes'
                  ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/configuracoes',
                      (route) => false,
                    )
                  : null,
              child: Icon(
                Icons.settings,
                color: widget.currentRoute == '/configuracoes'
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(136, 6, 0, 0),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
