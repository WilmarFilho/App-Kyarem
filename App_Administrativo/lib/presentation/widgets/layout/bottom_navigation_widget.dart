import 'package:flutter/material.dart';
import '../../screens/admin/campeonato_form_screen.dart';
import '../../screens/admin/atletica_form_screen.dart';
import '../../screens/admin/equipe_form_screen.dart';
import '../../screens/admin/partida_form_screen.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String currentRoute;
  final bool isAdmin;
  final bool isPresidenteAtletica;
  final bool isArbitro;

  const BottomNavigationWidget({
    super.key,
    required this.currentRoute,
    this.isAdmin = false,
    this.isPresidenteAtletica = false,
    this.isArbitro = false,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  bool _menuAdicionarAberto = false;

  void _navegar(Widget screen) {
    setState(() => _menuAdicionarAberto = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_menuAdicionarAberto)
          GestureDetector(
            onTap: () => setState(() => _menuAdicionarAberto = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),

        _buildAddMenuOverlay(),
        _buildBottomNavigation(),
      ],
    );
  }

  Widget _buildAddMenuOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: _menuAdicionarAberto ? 110 : -300,
      left: 22,
      right: 22,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _menuAdicionarAberto ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 20),
                child: Text(
                  'O QUE DESEJA ADICIONAR?',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Árbitro: não pode criar nada
              if (widget.isArbitro)
                _buildReadOnlyMessage()
              // Admin/Delegado: criação completa
              else if (widget.isAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAddOptionItem(
                      Icons.sports_soccer,
                      'Jogo',
                      const Color(0xFF2E9E56),
                      onTap: () => _navegar(const PartidaFormScreen()),
                    ),
                    _buildAddOptionItem(
                      Icons.emoji_events,
                      'Campeonato',
                      const Color(0xFFE6A817),
                      onTap: () => _navegar(const CampeonatoFormScreen()),
                    ),
                    _buildAddOptionItem(
                      Icons.shield,
                      'Atlética',
                      const Color(0xFF2563EB),
                      onTap: () => _navegar(const AtleticaFormScreen()),
                    ),
                    _buildAddOptionItem(
                      Icons.groups,
                      'Time',
                      const Color(0xFF7C3AED),
                      onTap: () => _navegar(const EquipeFormScreen()),
                    ),
                  ],
                )
              // Presidente: apenas Times
              else if (widget.isPresidenteAtletica)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAddOptionItem(
                      Icons.groups,
                      'Time',
                      const Color(0xFF7C3AED),
                      onTap: () => _navegar(const EquipeFormScreen()),
                    ),
                  ],
                )
              // Usuário comum: sem permissão
              else
                _buildReadOnlyMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 10),
          Text(
            'Você tem acesso somente\nleitura ao sistema.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptionItem(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: onTap != null
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
              border: onTap != null
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              color: onTap != null ? color : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onTap != null ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
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
                  ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    )
                  : null,
              child: Icon(
                Icons.home_filled,
                color: widget.currentRoute == '/home'
                    ? const Color(0xFFF85C39)
                    : Colors.white,
                size: 28,
              ),
            ),

            // Botão + central
            GestureDetector(
              onTap: () =>
                  setState(() => _menuAdicionarAberto = !_menuAdicionarAberto),
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: AnimatedRotation(
                  turns: _menuAdicionarAberto ? 0.375 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _menuAdicionarAberto
                          ? const Color(0xFFF85C39)
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: _menuAdicionarAberto ? Colors.white : Colors.black,
                      size: 32,
                    ),
                  ),
                ),
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
                    ? const Color(0xFFF85C39)
                    : Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
