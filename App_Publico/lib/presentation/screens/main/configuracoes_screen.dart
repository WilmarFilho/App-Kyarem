import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/themed_divider.dart';

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

class ConfiguracoesScreen extends StatefulWidget {
  final bool isMainScreenChild;

  const ConfiguracoesScreen({
    super.key,
    this.isMainScreenChild = false,
  });

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  late ScrollController _scrollController;
  double _headerCollapseProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.hasClients) {
          double offset = _scrollController.offset;
          double newProgress = (offset / 100).clamp(0.0, 1.0);
          if (newProgress != _headerCollapseProgress) {
            setState(() {
              _headerCollapseProgress = newProgress;
            });
          }
        }
      });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170 + MediaQuery.of(context).padding.top,
                  ),
                ),
                SliverToBoxAdapter(child: _buildNotificacoesSection()),
                SliverToBoxAdapter(child: _buildSobreSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          if (!widget.isMainScreenChild)
            const BottomNavigationWidget(),
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final backgroundColor = Color.lerp(
      Colors.white,
      Colors.black,
      _headerCollapseProgress,
    );

    final contentOpacity = (1.0 - _headerCollapseProgress * 2.5).clamp(
      0.0,
      1.0,
    );
    
    final waveHeight = 30.0 * (1.0 - _headerCollapseProgress);
    final headerHeight = 150.0 + (waveHeight) - (_headerCollapseProgress * 50);

    return ClipPath(
      clipper: _WaveClipper(waveHeight: waveHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: headerHeight.clamp(80.0, 200.0),
        padding: EdgeInsets.only(
          bottom: 30.0 * (1.0 - _headerCollapseProgress),
        ),
        decoration: BoxDecoration(color: backgroundColor),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: contentOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajuste suas configurações.',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: Color(0xFF555555),
                            ),
                          ),
                          Text(
                            'CONFIGURAÇÕES',
                            style: GoogleFonts.oswald(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF260404),
                              height: 1.1,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificacoesSection() {
    return _buildSection(
      title: 'Notificações',
      icon: Icons.notifications_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Por padrão, você é notificado sobre os principais acontecimentos do campeonato. Para desativar as notificações, altere a permissão de notificação deste aplicativo diretamente nas configurações do seu celular.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSobreSection() {
    return _buildSection(
      title: 'Sobre',
      icon: Icons.info_outline,
      children: [
        _buildInfoTile(
          icon: Icons.verified_outlined,
          title: 'Versão do App',
          value: '1.0.0',
        ),
        buildThemedDivider(),
        _buildActionTile(
          icon: Icons.description_outlined,
          title: 'Termos de Uso',
          subtitle: 'Em breve',
          enabled: false,
          onTap: () {
            showAppSnackBar(context, 'Em breve!', isError: false);
          },
        ),
        buildThemedDivider(),
        _buildActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de Privacidade',
          subtitle: 'Em breve',
          enabled: false,
          onTap: () {
            showAppSnackBar(context, 'Em breve!', isError: false);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 16,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
