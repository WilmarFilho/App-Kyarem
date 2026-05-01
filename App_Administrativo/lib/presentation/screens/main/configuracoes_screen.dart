import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final bool isMainScreenChild;
  final AuthService? authService;

  const ConfiguracoesScreen({
    super.key,
    this.isMainScreenChild = false,
    this.authService,
  });

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService = widget.authService ?? AuthService();

  String _userRole = 'user';
  bool _loading = true;
  bool _notificacoesGerais = true;
  bool _notificacoesPartidas = true;
  bool _notificacoesResultados = true;
  bool _modoCompacto = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  bool get _isAdminRole => _authService.isAdminRole(_userRole);
  bool get _isPresidenteAtletica => false;
  bool get _isArbitro => _authService.isArbitroRole(_userRole);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await _authService.getUserProfile();
    if (!_authService.canAccessAdminApp(profile)) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    if (!mounted) return;

    setState(() {
      _userRole = profile['role'] as String? ?? 'user';
      _notificacoesGerais = prefs.getBool('admin_notif_gerais') ?? true;
      _notificacoesPartidas = prefs.getBool('admin_notif_partidas') ?? true;
      _notificacoesResultados = prefs.getBool('admin_notif_resultados') ?? true;
      _modoCompacto = prefs.getBool('admin_modo_compacto') ?? false;
      _loading = false;
    });

    _animController.forward();
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleNotificacoesGerais(bool value) async {
    setState(() {
      _notificacoesGerais = value;
      if (!value) {
        _notificacoesPartidas = false;
        _notificacoesResultados = false;
      }
    });

    await _savePreference('admin_notif_gerais', value);
    if (!value) {
      await _savePreference('admin_notif_partidas', false);
      await _savePreference('admin_notif_resultados', false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Sair da conta',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Deseja encerrar sua sessão administrativa agora?',
            style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF5E5E5E)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85C39),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(
      text: _authService.currentUser?.email ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Alterar senha',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enviaremos um link de redefinição para o e-mail informado.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF5E5E5E),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'seu@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFF85C39),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                try {
                  await _authService.resetPassword(email);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackBar('Link de redefinição enviado.');
                } catch (_) {
                  _showSnackBar(
                    'Não foi possível enviar o e-mail.',
                    isError: true,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85C39),
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF7F7F7))),
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF85C39)),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        22,
                        18,
                        22,
                        widget.isMainScreenChild ? 120 : 130,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildHeroCard(),
                          const SizedBox(height: 18),
                          _buildSection(
                            title: 'Notificações',
                            subtitle:
                                'Controle os avisos operacionais do painel.',
                            children: [
                              _buildSwitchTile(
                                icon: Icons.notifications_active_outlined,
                                title: 'Notificações gerais',
                                subtitle: 'Liga ou desliga todos os avisos',
                                value: _notificacoesGerais,
                                onChanged: _toggleNotificacoesGerais,
                              ),
                              const SizedBox(height: 12),
                              _buildSwitchTile(
                                icon: Icons.sports_soccer_outlined,
                                title: 'Alertas de partidas',
                                subtitle:
                                    'Mudanças de status e eventos da partida',
                                value: _notificacoesPartidas,
                                enabled: _notificacoesGerais,
                                onChanged: (value) async {
                                  setState(() => _notificacoesPartidas = value);
                                  await _savePreference(
                                    'admin_notif_partidas',
                                    value,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSwitchTile(
                                icon: Icons.emoji_events_outlined,
                                title: 'Resultados e encerramentos',
                                subtitle: 'Resumo de jogos finalizados',
                                value: _notificacoesResultados,
                                enabled: _notificacoesGerais,
                                onChanged: (value) async {
                                  setState(
                                    () => _notificacoesResultados = value,
                                  );
                                  await _savePreference(
                                    'admin_notif_resultados',
                                    value,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSection(
                            title: 'Sobre o App',
                            subtitle: 'Veja informações sobre a versão atual',
                            children: [
                              const SizedBox(height: 12),
                              _buildStaticInfoTile(
                                icon: Icons.verified_outlined,
                                title: 'Versão do app',
                                value: '1.0.0',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildSection(
                            title: 'Conta',
                            subtitle: 'Ações sensíveis da sua sessão.',
                            children: [
                              _buildActionTile(
                                icon: Icons.lock_reset_outlined,
                                title: 'Alterar senha',
                                subtitle: 'Enviar e-mail de redefinição',
                                color: const Color(0xFFF85C39),
                                onTap: _showResetPasswordDialog,
                              ),
                              const SizedBox(height: 12),
                              _buildActionTile(
                                icon: Icons.logout,
                                title: 'Sair da conta',
                                subtitle: 'Encerrar a sessão atual',
                                color: const Color(0xFFB3261E),
                                onTap: _logout,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (!widget.isMainScreenChild)
            BottomNavigationWidget(
              currentRoute: '/configuracoes',
              isAdmin: _isAdminRole,
              isPresidenteAtletica: _isPresidenteAtletica,
              isArbitro: _isArbitro,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (!widget.isMainScreenChild) ...[
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE1D8)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF85C39).withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 14),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferências do painel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              Text(
                'CONFIGURAÇÕES',
                style: TextStyle(
                  fontFamily: 'Bebas Neue',
                  fontSize: 30,
                  letterSpacing: 1,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFE6DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF85C39).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF252525), Color(0xFFF85C39)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Painel sob seu controle',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ajuste notificações, segurança e modo de uso sem sair da área administrativa.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF6E6E6E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFE6DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF85C39).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 24,
              letterSpacing: 1,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
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
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE6DE)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF85C39).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFF85C39)),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: const Color(0xFFF85C39),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE6DE)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE6DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF85C39)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF85C39).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF9A48E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
