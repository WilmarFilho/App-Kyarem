import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../../../services/admin_api_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_card.dart';
import '../../widgets/home/option_button.dart';
import '../../widgets/home/home_list.dart';
import '../game/partida_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/campeonatos_admin_screen.dart';
import '../admin/atleticas_admin_screen.dart';
import '../admin/equipes_admin_screen.dart';
import '../admin/partidas_admin_screen.dart';
import '../../../services/auth_service.dart';
import 'arbitros_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaService _partidaService = PartidaService();
  final AuthService _authService = AuthService();
  final AdminApiService _adminApiService = AdminApiService();

  List<Partida> _partidasDestaque = [];
  List<dynamic> _itensListaInferior = [];
  bool _carregandoDestaques = false;
  bool _carregandoListaAba = false;

  // Perfil do usuário carregado via getUserProfile()
  String _userRole = 'aluno';
  String? _atleticaId; // Disponível apenas para presidente_atletica

  // ---- Getters de role ----
  bool get _isAdminRole =>
      _userRole == 'admin' ||
      _userRole == 'super_admin' ||
      _userRole == 'delegado';

  bool get _isPresidenteAtletica => _userRole == 'presidente_atletica';
  bool get _isArbitro => _userRole == 'arbitro';

  // Qualquer acesso ao painel (admin, delegado, presidente, árbitro)
  bool get _hasAdminAccess =>
      _isAdminRole || _isPresidenteAtletica || _isArbitro;

  late AnimationController _mainController;
  late AnimationController _listController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _listController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _initializeAnimations();
    _carregarTudo();
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(index * 0.2, (index * 0.2) + 0.8,
            curve: Curves.easeOutCubic),
      )),
    );
    _slideAnimations = List.generate(
      3,
      (index) =>
          Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero)
              .animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(index * 0.2, (index * 0.2) + 0.8,
            curve: Curves.easeOutCubic),
      )),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    final profile = await _authService.getUserProfile();
    final role = profile['role'] as String? ?? 'aluno';
    String? atleticaId;

    debugPrint('🔑 [HOME] role="$role"');

    // atleticaId é sempre resolvido via API do backend (nunca vem do Supabase)
    if (role == 'presidente_atletica') {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        atleticaId = await _adminApiService.buscarAtleticaDoPresidente(userId);
        debugPrint('🔑 [HOME] atleticaId via API: "$atleticaId"');
      }
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _atleticaId = atleticaId;
      });
    }
    debugPrint('🔑 [HOME] isAdmin=$_isAdminRole | isPresidente=$_isPresidenteAtletica | isArbitro=$_isArbitro');



    await Future.wait([
      _buscarPartidasDestaque(),
      _buscarDadosAba(isFirstLoad: true),
    ]);
    _mainController.forward();
    _listController.forward();
  }

  Future<void> _buscarPartidasDestaque() async {
    if (mounted) setState(() => _carregandoDestaques = true);
    try {
      final partidas = await _partidaService.listarPartidasMinhas();
      if (mounted) {
        setState(() {
          _partidasDestaque = partidas;
          _carregandoDestaques = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoDestaques = false);
    }
  }

  Future<void> _buscarDadosAba({bool isFirstLoad = false}) async {
    if (mounted) setState(() => _carregandoListaAba = true);
    try {
      final dados = await _partidaService.buscarDadosPorAba(_abaSelecionada);
      if (mounted) {
        setState(() {
          _itensListaInferior = dados;
          _carregandoListaAba = false;
        });
        if (!isFirstLoad) {
          _listController.reset();
          _listController.forward();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoListaAba = false);
    }
  }

  void _mudarAba(String novaAba) {
    if (_abaSelecionada == novaAba) return;
    setState(() {
      _abaSelecionada = novaAba;
      _itensListaInferior = [];
    });
    _buscarDadosAba();
  }

  void _navegarAdmin(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _carregarTudo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(heightFactor: 0.8),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const HomeHeader(),
                _buildCardsSection(),
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(),
                Expanded(child: _buildMainGamesSection()),
              ],
            ),
          ),
          BottomNavigationWidget(
            currentRoute: '/home',
            isAdmin: _isAdminRole,
            isPresidenteAtletica: _isPresidenteAtletica,
            isArbitro: _isArbitro,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 155,
      child: _carregandoDestaques && _partidasDestaque.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
          : _partidasDestaque.isEmpty
              ? const Center(
                  child: Text("Nenhuma partida em destaque",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _partidasDestaque.length,
                  itemBuilder: (context, index) {
                    final partida = _partidasDestaque[index];
                    final animIdx = index.clamp(0, 2);
                    return PartidaCard(
                      partida: partida,
                      fadeAnimation: _fadeAnimations[animIdx],
                      slideAnimation: _slideAnimations[animIdx],
                      onTap: () => _navegarParaPartida(partida),
                    );
                  },
                ),
    );
  }

  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text('O QUE VOCÊ QUER VER?',
            style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28)),
        const SizedBox(height: 15),

        // ── Linha 1: Jogos + Árbitros + (Painel Admin se tiver acesso) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OptionButton(
              icon: Icons.sports_soccer,
              label: 'Jogos',
              isSelected: _abaSelecionada == 'Jogos',
              onTap: () => _mudarAba('Jogos'),
            ),
            OptionButton(
              icon: Icons.gavel,
              label: 'Árbitros',
              isSelected: false,
              onTap: () => _navegarAdmin(
                ArbitrosScreen(canEdit: _isAdminRole),
              ),
            ),
            if (_hasAdminAccess)
              OptionButton(
                icon: Icons.admin_panel_settings,
                label: 'Painel Admin',
                isSelected: false,
                onTap: () => _navegarAdmin(const AdminDashboardScreen()),
              ),
          ],
        ),

        // ── Linha 2: Atalhos de gerenciamento (condicional por role) ──
        if (_hasAdminAccess) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Admin/delegado: CRUD completo de Campeonatos
                if (_isAdminRole) ...[
                  _buildAdminShortcut(
                    icon: Icons.emoji_events,
                    label: 'Campeonatos',
                    color: const Color(0xFFE6A817),
                    onTap: () =>
                        _navegarAdmin(const CampeonatosAdminScreen()),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.sports_soccer,
                    label: 'Partidas',
                    color: const Color(0xFF2E9E56),
                    onTap: () => _navegarAdmin(
                        const PartidasAdminScreen(canEdit: true)),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.shield,
                    label: 'Atléticas',
                    color: const Color(0xFF2563EB),
                    onTap: () =>
                        _navegarAdmin(const AtleticasAdminScreen()),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.groups,
                    label: 'Times',
                    color: const Color(0xFF7C3AED),
                    onTap: () => _navegarAdmin(const EquipesAdminScreen()),
                  ),
                ],

                // Árbitro: ver partidas (somente leitura)
                if (_isArbitro) ...[
                  _buildAdminShortcut(
                    icon: Icons.sports_soccer,
                    label: 'Partidas',
                    color: const Color(0xFF2E9E56),
                    badge: 'Leitura',
                    onTap: () => _navegarAdmin(
                        const PartidasAdminScreen(canEdit: false)),
                  ),
                ],

                // Presidente: CRUD de Times + ver Partidas (somente leitura) + Minha Atlética
                if (_isPresidenteAtletica) ...[
                  _buildAdminShortcut(
                    icon: Icons.sports_soccer,
                    label: 'Partidas',
                    color: const Color(0xFF2E9E56),
                    badge: 'Leitura',
                    onTap: () => _navegarAdmin(PartidasAdminScreen(
                      canEdit: false,
                      atleticaId: _atleticaId,
                    )),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.shield,
                    label: 'Minha Atlética',
                    color: const Color(0xFF2563EB),
                    onTap: () => _atleticaId != null
                        ? _navegarAdmin(AtleticasAdminScreen(
                            minhaAtleticaId: _atleticaId))
                        : ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Perfil não vinculado a uma atlética.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.groups,
                    label: 'Times',
                    color: const Color(0xFF7C3AED),
                    onTap: () => _navegarAdmin(const EquipesAdminScreen()),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildAdminShortcut({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_abaSelecionada,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                if (_abaSelecionada == 'Jogos')
                  GestureDetector(
                    onTap: () => setState(() => _verMeus = !_verMeus),
                    child: Text(
                      _verMeus ? 'Ver Tudo' : 'Ver Meus',
                      style: TextStyle(
                        color: _verMeus
                            ? const Color(0xFFF85C39)
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _carregandoListaAba && _itensListaInferior.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _listController,
                    child: SlideTransition(
                      position: _listController.drive(
                          Tween<Offset>(
                              begin: const Offset(0.0, 0.05),
                              end: Offset.zero)),
                      child: Builder(builder: (context) {
                        final bool mostrarMeus =
                            _abaSelecionada == 'Jogos' && _verMeus;
                        final lista = mostrarMeus
                            ? _partidasDestaque
                            : _itensListaInferior;

                        if (lista.isEmpty) {
                          return Center(
                            child: Text("Nenhum registro encontrado",
                                style:
                                    TextStyle(color: Colors.grey[400])),
                          );
                        }
                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(22, 0, 22, 120),
                          physics: const BouncingScrollPhysics(),
                          itemCount: lista.length,
                          itemBuilder: (context, index) => HomeListItem(
                              item: lista[index], type: _abaSelecionada),
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _navegarParaPartida(Partida partida) {
    Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => PartidaRunningScreen(partida: partida)))
        .then((_) => _carregarTudo());
  }
}
