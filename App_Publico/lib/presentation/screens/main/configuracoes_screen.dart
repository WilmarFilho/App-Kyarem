import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

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

  const ConfiguracoesScreen({super.key, this.isMainScreenChild = false});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  // Notification toggles
  bool _notificacoesGerais = true;
  bool _notificacoesPartidas = true;
  bool _notificacoesResultados = true;

  // Mockadas
  bool _modoEscuro = false;

  bool _loading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  late ScrollController _scrollController;
  double _headerCollapseProgress = 0.0;
  String _userName = 'Usuário';

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

    _loadPreferences();
    _fetchUserName();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('nome_exibicao')
            .eq('id', user.id)
            .single();

        if (profile['nome_exibicao'] != null && mounted) {
          setState(() {
            _userName = profile['nome_exibicao'];
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar nome: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificacoesGerais = prefs.getBool('notif_gerais') ?? true;
        _notificacoesPartidas = prefs.getBool('notif_partidas') ?? true;
        _notificacoesResultados = prefs.getBool('notif_resultados') ?? true;
        _modoEscuro = prefs.getBool('modo_escuro') ?? false;
        _loading = false;
      });
      _animController.forward();
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleNotificacoesGerais(bool value) async {
    setState(() => _notificacoesGerais = value);
    await _savePreference('notif_gerais', value);

    // Se desligar as gerais, desliga as sub-notificações
    if (!value) {
      setState(() {
        _notificacoesPartidas = false;
        _notificacoesResultados = false;
      });
      await _savePreference('notif_partidas', false);
      await _savePreference('notif_resultados', false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF110101),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sair da Conta',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFF85C39),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showAlterarSenha() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF110101),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Alterar Senha',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu e-mail para receber o link de redefinição de senha.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white30,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF22F1D),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                try {
                  await Supabase.instance.client.auth.resetPasswordForEmail(
                    emailController.text.trim().toLowerCase(),
                    redirectTo: 'apppublico://reset-password',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('E-mail de redefinição enviado!'),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Erro ao enviar e-mail'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Enviar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFF85C39),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          // REMOVIDO o SafeArea daqui para o header encostar no topo
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                )
              : FadeTransition(
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

                      // As demais seções
                      SliverToBoxAdapter(child: _buildNotificacoesSection()),
                      SliverToBoxAdapter(child: _buildAparenciaSection()),
                      SliverToBoxAdapter(child: _buildContaSection()),
                      SliverToBoxAdapter(child: _buildSobreSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
          if (!widget.isMainScreenChild)
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationWidget(currentRoute: '/configuracoes'),
            ),

          if (!_loading)
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // 1. Interpolação de Cores
    final backgroundColor = Color.lerp(
      Colors.white,
      Colors.black,
      _headerCollapseProgress,
    );

    // 2. Cálculos de layout e opacidade
    final contentOpacity = (1.0 - _headerCollapseProgress * 2.5).clamp(
      0.0,
      1.0,
    );
    final searchOpacity = ((_headerCollapseProgress - 0.6) / 0.4).clamp(
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

                // BARRA DE BUSCA (Aparece no Header Preto)
                if (searchOpacity > 0)
                  Opacity(
                    opacity: searchOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen())),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
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
  // ── Seção Notificações ──────────────────────────────────────────────

  Widget _buildNotificacoesSection() {
    return _buildSection(
      title: 'Notificações',
      icon: Icons.notifications_outlined,
      children: [
        _buildSwitchTile(
          icon: Icons.notifications_active_outlined,
          title: 'Receber Notificações',
          subtitle: 'Ativar ou desativar todas as notificações',
          value: _notificacoesGerais,
          onChanged: _toggleNotificacoesGerais,
        ),
        _buildDivider(),
        _buildSwitchTile(
          icon: Icons.sports_soccer,
          title: 'Notificações de Partidas',
          subtitle: 'Alertas sobre início e atualizações de partidas',
          value: _notificacoesPartidas,
          enabled: _notificacoesGerais,
          onChanged: (val) async {
            setState(() => _notificacoesPartidas = val);
            await _savePreference('notif_partidas', val);
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          icon: Icons.emoji_events_outlined,
          title: 'Notificações de Resultados',
          subtitle: 'Receber resultados finais das partidas',
          value: _notificacoesResultados,
          enabled: _notificacoesGerais,
          onChanged: (val) async {
            setState(() => _notificacoesResultados = val);
            await _savePreference('notif_resultados', val);
          },
        ),
      ],
    );
  }

  // ── Seção Aparência ─────────────────────────────────────────────────

  Widget _buildAparenciaSection() {
    return _buildSection(
      title: 'Aparência',
      icon: Icons.palette_outlined,
      children: [
        _buildSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Modo Escuro',
          subtitle: 'Em breve',
          value: _modoEscuro,
          enabled: false,
          onChanged: (val) async {
            setState(() => _modoEscuro = val);
            await _savePreference('modo_escuro', val);
          },
        ),
      ],
    );
  }

  // ── Seção Conta ─────────────────────────────────────────────────────

  Widget _buildContaSection() {
    return _buildSection(
      title: 'Conta',
      icon: Icons.person_outline,
      children: [
        _buildActionTile(
          icon: Icons.lock_outline,
          title: 'Alterar Senha',
          subtitle: 'Enviar e-mail de redefinição',
          onTap: _showAlterarSenha,
        ),
        _buildDivider(),
        _buildActionTile(
          icon: Icons.logout,
          title: 'Sair da Conta',
          subtitle: 'Encerrar sessão atual',
          onTap: _logout,
          isDestructive: true,
        ),
      ],
    );
  }

  // ── Seção Sobre ─────────────────────────────────────────────────────

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
        _buildDivider(),
        _buildActionTile(
          icon: Icons.description_outlined,
          title: 'Termos de Uso',
          subtitle: 'Em breve',
          enabled: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Em breve!'),
                backgroundColor: const Color(0xFF252525),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de Privacidade',
          subtitle: 'Em breve',
          enabled: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Em breve!'),
                backgroundColor: const Color(0xFF252525),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Componentes Reutilizáveis
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF110101),
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
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFF22F1D), size: 20),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF22F1D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFF22F1D), size: 20),
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
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: const Color(0xFFF22F1D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
    bool isDestructive = false,
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
                  color: isDestructive
                      ? Colors.red.withOpacity(0.08)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red[600] : Colors.white70,
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? Colors.red[600] : Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white30, size: 22),
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
              color: const Color(0xFF1A0202),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0202),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
    );
  }
}
