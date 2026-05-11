import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;

  const BottomNavigationWidget({
    super.key,
    this.currentIndex,
    this.onTabSelected,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  // Cor principal extraída do seu card para manter a harmonia
  static const Color brandRed = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 75 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding * 0.5),
        decoration: BoxDecoration(
          color: Colors.white, // Fundo limpo
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: _buildStandardNav(),
      ),
    );
  }

  Widget _buildStandardNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(Icons.home_max_rounded, 'Início', 0),
        _buildNavItem(Icons.sports_soccer_rounded, 'Jogos', 1),
        _buildNavItem(Icons.settings_rounded, 'Ajustes', 2),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = widget.currentIndex != null && widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(index);
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container da pílula de destaque
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                // Se selecionado, fundo vermelho clarinho (opaco)
                color: isSelected
                    ? brandRed.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 26,
                // Ícone vermelho se selecionado, cinza se inativo
                color: isSelected ? brandRed : Colors.black38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(

                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? brandRed : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
