import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String currentRoute;

  const BottomNavigationWidget({
    super.key,
    required this.currentRoute,
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
        // Overlay Escuro quando o menu está aberto
        if (_menuAdicionarAberto)
          GestureDetector(
            onTap: () => setState(() => _menuAdicionarAberto = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withOpacity(0.4),
            ),
          ),

        // Menu de Adição Animado
        _buildAddMenuOverlay(),

        // Barra de Navegação
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildAddMenuOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      bottom: _menuAdicionarAberto ? 110 : -200,
      left: 22,
      right: 22,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _menuAdicionarAberto ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O QUE DESEJA ADICIONAR?',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAddOptionItem(Icons.sports_soccer, 'Jogo'),
                  _buildAddOptionItem(Icons.emoji_events, 'Campeonato'),
                  _buildAddOptionItem(Icons.gavel, 'Árbitro'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOptionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: const Color(0xFFF85C39), size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: widget.currentRoute != '/home' 
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false)
                  : null,
              child: Icon(
                Icons.home_filled,
                color: widget.currentRoute == '/home' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: widget.currentRoute != '/arbitros'
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/arbitros', (route) => false)
                  : null,
              child: Icon(
                Icons.gavel,
                color: widget.currentRoute == '/arbitros' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
            
            // Botão central com animação
            GestureDetector(
              onTap: () => setState(() => _menuAdicionarAberto = !_menuAdicionarAberto),
              child: Transform.translate(
                offset: const Offset(0, -5),
                child: AnimatedRotation(
                  turns: _menuAdicionarAberto ? 0.375 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _menuAdicionarAberto ? const Color(0xFFF85C39) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add, 
                      color: _menuAdicionarAberto ? Colors.white : Colors.black, 
                      size: 32
                    ),
                  ),
                ),
              ),
            ),
            
            GestureDetector(
              onTap: widget.currentRoute != '/campeonatos'
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/campeonatos', (route) => false)
                  : null,
              child: Icon(
                Icons.emoji_events,
                color: widget.currentRoute == '/campeonatos' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: widget.currentRoute != '/configuracoes'
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/configuracoes', (route) => false)
                  : null,
              child: Icon(
                Icons.settings,
                color: widget.currentRoute == '/configuracoes' ? const Color(0xFFF85C39) : Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}