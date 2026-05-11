import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/main/search_screen.dart';

class _WaveClipper extends CustomClipper<Path> {
  final double waveHeight;
  _WaveClipper({this.waveHeight = 30});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - waveHeight);
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - waveHeight);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint = Offset(
      size.width * 0.75,
      size.height - waveHeight * 2,
    );
    final secondEndPoint = Offset(size.width, size.height - waveHeight);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) =>
      oldClipper.waveHeight != waveHeight;
}

class HomeHeader extends StatelessWidget {
  final double collapseProgress;

  const HomeHeader({super.key, this.collapseProgress = 0.0});

  @override
  Widget build(BuildContext context) {
    // 1. Interpolação de Cores
    final backgroundColor = Color.lerp(
      Colors.white,
      Colors.black,
      collapseProgress,
    );

    final iconBadgeColor = Color.lerp(
      AppColors.primary.withValues(alpha: 0.08),
      Colors.white.withValues(alpha: 0.1),
      collapseProgress,
    );

    // 2. Cálculos de layout e opacidade
    final contentOpacity = (1.0 - collapseProgress * 2.5).clamp(0.0, 1.0);
    final searchOpacity = ((collapseProgress - 0.6) / 0.4).clamp(0.0, 1.0);
    final waveHeight = 30.0 * (1.0 - collapseProgress);
    final headerHeight = 150.0 + (waveHeight) - (collapseProgress * 50);

    return ClipPath(
      clipper: _WaveClipper(waveHeight: waveHeight),
      child: AnimatedContainer(
        // Usando AnimatedContainer para suavizar trocas bruscas se houver
        duration: const Duration(milliseconds: 100),
        height: headerHeight.clamp(80.0, 200.0),
        padding: EdgeInsets.only(bottom: 30.0 * (1.0 - collapseProgress)),
        decoration: BoxDecoration(color: backgroundColor),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // CONTEÚDO ORIGINAL
                Opacity(
                  opacity: contentOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acompanhe tudo aqui!',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF555555),
                            ),
                          ),
                          Text(
                            'BEM-VINDO!',
                            style: GoogleFonts.oswald(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bgDark,
                              height: 1.1,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // BARRA DE BUSCA (Aparece no Header Preto)
                if (searchOpacity > 0)
                  Opacity(
                    opacity: searchOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        ),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 15),
                              const Icon(
                                Icons.search,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'O que você procura?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
