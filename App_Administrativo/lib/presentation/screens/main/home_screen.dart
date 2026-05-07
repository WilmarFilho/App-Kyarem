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
import '../admin/partidas_admin_screen.dart';
import '../admin/campeonatos_admin_screen.dart';
import '../admin/arbitros_screen.dart';
import '../admin/atleticas_admin_screen.dart';
import '../admin/modalidades_admin_screen.dart';
import '../../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isMainScreenChild;
  final PartidaService? partidaService;
  final AuthService? authService;
  final AdminApiService? adminApiService;

  // Flags passadas pelo MainScreen para evitar duplicação de chamadas HTTP.
  // Quando fornecidas, o HomeScreen usa esses valores diretamente.
  final bool? isAdminOverride;
  final bool? isArbitroOverride;
  final bool perfilJaCarregado;

  const HomeScreen({
    super.key,
    this.isMainScreenChild = false,
    this.partidaService,
    this.authService,
    this.adminApiService,
    this.isAdminOverride,
    this.isArbitroOverride,
    this.perfilJaCarregado = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final PartidaService _partidaService =
      widget.partidaService ?? PartidaService();
  late final AuthService _authService = widget.authService ?? AuthService();

  List<Partida> _partidasDestaque = [];
  List<dynamic> _itensListaInferior = [];
  bool _carregandoDestaques = false;
  bool _carregandoListaAba = false;

  // Flags de permissão carregadas via getUserProfile()
  bool _isAdminRole = false;
  bool _isPresidenteAtletica = false;
  bool _isArbitro = false;

  bool get _hasAdminAccess => _isAdminRole || _isArbitro;

  late AnimationController _mainController;
  late AnimationController _listController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;
  bool _loadingMeus = false;

  List<_HomeTabOption> get _tabOptions {
    if (_isArbitro && !_isAdminRole) {
      return const [
        _HomeTabOption(
          value: 'Jogos',
          label: 'Partidas',
          icon: Icons.sports_soccer,
        ),
      ];
    }

    return const [
      _HomeTabOption(
        value: 'Jogos',
        label: 'Partidas',
        icon: Icons.sports_soccer,
      ),
      _HomeTabOption(value: 'Árbitros', label: 'Árbitros', icon: Icons.gavel),
      _HomeTabOption(
        value: 'Campeonatos',
        label: 'Campeonatos',
        icon: Icons.emoji_events,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Se o MainScreen já resolveu as flags, usa diretamente.
    if (widget.isAdminOverride != null) {
      _isAdminRole = widget.isAdminOverride!;
    }
    if (widget.isArbitroOverride != null) {
      _isArbitro = widget.isArbitroOverride!;
    }
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeAnimations();
    _carregarTudo();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza as flags quando o MainScreen termina de carregar o perfil.
    bool changed = false;
    if (widget.isAdminOverride != null &&
        widget.isAdminOverride != _isAdminRole) {
      _isAdminRole = widget.isAdminOverride!;
      changed = true;
    }
    if (widget.isArbitroOverride != null &&
        widget.isArbitroOverride != _isArbitro) {
      _isArbitro = widget.isArbitroOverride!;
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(
      3,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.8,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    _slideAnimations = List.generate(
      3,
      (index) => Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _mainController,
              curve: Interval(
                index * 0.2,
                (index * 0.2) + 0.8,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    // Se o MainScreen já carregou e passou as flags via override,
    // pula a chamada HTTP duplicada e vai direto para os dados.
    if (!widget.perfilJaCarregado) {
      final profile = await _authService.getUserProfile();
      debugPrint(
        'HomeScreen perfil → isAdmin=${profile['isAdmin']} role=${profile['role']} allowed=${profile['allowedAdminApp']}',
      );
      if (!_authService.canAccessAdminApp(profile)) {
        await _authService.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          // Só atualiza se não há override vindo do pai.
          if (widget.isAdminOverride == null) {
            _isAdminRole =
                profile['isAdmin'] == true ||
                _authService.isAdminRole(profile['role'] as String? ?? '');
          }
          if (widget.isArbitroOverride == null) {
            _isArbitro =
                profile['isArbitro'] == true ||
                _authService.isArbitroRole(profile['role'] as String? ?? '');
          }
          if (!_tabOptions.any((tab) => tab.value == _abaSelecionada)) {
            _abaSelecionada = _tabOptions.first.value;
          }
        });
      }
    }

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
          _partidasDestaque = _filtrarPartidasHome(partidas);
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
      var dados = await _partidaService.buscarDadosPorAba(_abaSelecionada);
      if (_abaSelecionada == 'Jogos') {
        dados = _filtrarPartidasHome(List<Partida>.from(dados));
      }
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

  List<Partida> _filtrarPartidasHome(List<Partida> partidas) {
    return partidas
        .where((partida) => partida.status.trim().toLowerCase() != 'fechada')
        .toList();
  }

  void _navegarAdmin(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _carregarTudo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(heightFactor: 0.8),
          SafeArea(
            bottom: false,
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const HomeHeader(),
                        _buildCardsSection(),
                        const SizedBox(height: 20),
                        _buildWhatDoYouWantSection(),
                      ],
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildMainGamesSection(),
              ),
            ),
          ),
          if (!widget.isMainScreenChild)
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _partidasDestaque.isEmpty
          ? const Center(
              child: Text(
                "Nenhuma partida em destaque",
                style: TextStyle(color: Colors.white),
              ),
            )
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
    // Árbitro puro: não exibe esta seção (ele só pode ver partidas mesmo)
    if (_isArbitro && !_isAdminRole) return const SizedBox.shrink();

    return Column(
      children: [
        const Text(
          'Selecione o que você quer ver:',
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28),
        ),
        const SizedBox(height: 15),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 44,
          runSpacing: 14,
          children: _tabOptions
              .map(
                (tab) => OptionButton(
                  icon: tab.icon,
                  label: tab.label,
                  isSelected: _abaSelecionada == tab.value,
                  onTap: () => _mudarAba(tab.value),
                ),
              )
              .toList(),
        ),

        if (_hasAdminAccess) ...[
          const SizedBox(height: 28),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Admin: CRUD completo de Campeonatos
                if (_isAdminRole) ...[
                  _buildAdminShortcut(
                    icon: Icons.emoji_events,
                    label: 'Campeonatos',
                    color: const Color(0xFFF85C39),
                    onTap: () => _navegarAdmin(const CampeonatosAdminScreen()),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.sports_soccer,
                    label: 'Partidas',
                    color: const Color(0xFFF85C39),
                    onTap: () => _navegarAdmin(
                      PartidasAdminScreen(canEdit: _isAdminRole),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.gavel,
                    label: 'Árbitros',
                    color: const Color(0xFFF85C39),
                    onTap: () => _navegarAdmin(
                      ArbitrosAdminScreen(canEdit: _isAdminRole),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.shield,
                    label: 'Atléticas',
                    color: const Color(0xFFF85C39),
                    onTap: () => _navegarAdmin(const AtleticasAdminScreen()),
                  ),
                  const SizedBox(width: 10),
                  _buildAdminShortcut(
                    icon: Icons.sports,
                    label: 'Modalidades',
                    color: const Color(0xFFF85C39),
                    onTap: () => _navegarAdmin(const ModalidadesAdminScreen()),
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
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _abaSelecionada == 'Jogos' ? 'Partidas' : _abaSelecionada,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_abaSelecionada == 'Jogos')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Ver Meus / Ver Tudo
                      GestureDetector(
                        onTap: () async {
                          final novoValor = !_verMeus;
                          setState(() {
                            _verMeus = novoValor;
                            if (novoValor) _loadingMeus = true;
                          });
                          if (novoValor) {
                            final minhas =
                                await _partidaService.listarPartidasMinhas();
                            if (mounted) {
                              setState(() {
                                _partidasDestaque = _filtrarPartidasHome(
                                  minhas,
                                );
                                _loadingMeus = false;
                              });
                            }
                          }
                        },
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
                      // Botão "Ver detalhes" exclusivo para árbitros
                      if (_isArbitro && !_isAdminRole) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _navegarAdmin(
                            PartidasAdminScreen(canEdit: _isArbitro),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2E9E56,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF2E9E56,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 13,
                                  color: Color(0xFF2E9E56),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ver detalhes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E9E56),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: _carregandoListaAba && _itensListaInferior.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(50.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : FadeTransition(
                    opacity: _listController,
                    child: SlideTransition(
                      position: _listController.drive(
                        Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final bool mostrarMeus =
                              _abaSelecionada == 'Jogos' && _verMeus;

                          if (mostrarMeus && _loadingMeus) {
                            return const Padding(
                              padding: EdgeInsets.all(50.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final lista = mostrarMeus
                              ? _partidasDestaque
                              : _itensListaInferior;

                          if (lista.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Text(
                                  "Nenhum registro encontrado",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                            itemCount: lista.length,
                            itemBuilder: (context, index) => HomeListItem(
                              item: lista[index],
                              type: _abaSelecionada,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _navegarParaPartida(Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartidaRunningScreen(partida: partida)),
    ).then((_) => _carregarTudo());
  }
}

class _HomeTabOption {
  final String value;
  final String label;
  final IconData icon;

  const _HomeTabOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
