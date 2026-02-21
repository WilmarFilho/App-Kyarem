import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_card.dart';
import '../../widgets/home/option_button.dart';
import '../../widgets/home/home_list.dart';
import '../game/partida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaService _partidaService = PartidaService();

  List<Partida> _partidasDestaque = [];
  List<dynamic> _itensListaInferior = [];

  bool _carregandoDestaques = false;
  bool _carregandoListaAba = false;

  // Controladores separados para evitar que o topo reanime ao trocar de aba
  late AnimationController _mainController; // Controla Header e Cards
  late AnimationController
  _listController; // Controla apenas a lista dinâmica inferior

  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  @override
  void initState() {
    super.initState();

    // Inicializa o controller principal (topo)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Inicializa o controller da lista (abas)
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeAnimations();
    _carregarTudo();
  }

  void _initializeAnimations() {
    // As animações de entrada do topo agora são vinculadas ao _mainController
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
    await Future.wait([
      _buscarPartidasDestaque(),
      _buscarDadosAba(
        isFirstLoad: true,
      ), // Passamos flag para não resetar animação agora
    ]);
    // Dispara a animação do topo apenas na carga inicial
    _mainController.forward();
    _listController.forward();
  }

  Future<void> _buscarPartidasDestaque() async {
    if (mounted) setState(() => _carregandoDestaques = true);
    try {
      final partidas = await _partidaService.listarPartidasDoDia();
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

        // Se não for a carga inicial da tela, resetamos apenas o controller da lista
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
                // HomeHeader agora está fixo ou pode ser envolvido em FadeTransition se desejar
                const HomeHeader(),
                _buildCardsSection(),
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(),
                Expanded(child: _buildMainGamesSection()),
              ],
            ),
          ),
          const BottomNavigationWidget(currentRoute: '/home'),
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
                final animationIndex = index.clamp(0, 2);

                return PartidaCard(
                  partida: partida,
                  fadeAnimation: _fadeAnimations[animationIndex],
                  slideAnimation: _slideAnimations[animationIndex],
                  onTap: () => _navegarParaPartida(partida),
                );
              },
            ),
    );
  }

  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text(
          'O QUE VOCÊ QUER VER?',
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28),
        ),
        const SizedBox(height: 15),
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
              isSelected: _abaSelecionada == 'Árbitros',
              onTap: () => _mudarAba('Árbitros'),
            ),
            OptionButton(
              icon: Icons.emoji_events,
              label: 'Campeonatos',
              isSelected: _abaSelecionada == 'Campeonatos',
              onTap: () => _mudarAba('Campeonatos'),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
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
                  _abaSelecionada,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                          end: Offset.zero,
                        ),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _itensListaInferior.length,
                        itemBuilder: (context, index) {
                          return HomeListItem(
                            item: _itensListaInferior[index],
                            type: _abaSelecionada,
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
