import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../game/partida_screen.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_list_item.dart';
import '../../widgets/home/partida_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PartidaService _partidaService = PartidaService();

  List<Partida> _partidasDestaque = [];
  List<Partida> _historicoPartidas = [];
  bool _carregandoDados = true;
  bool _verMeus = false;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations = [];
  late List<Animation<Offset>> _slideAnimations = [];

  late final Stream<List<Map<String, dynamic>>> _partidasRealtimeStream;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _partidasRealtimeStream = _supabase
        .from('partidas')
        .stream(primaryKey: ['id']);

    _carregarDadosReais();

    _partidasRealtimeStream.listen((_) {
      _carregarDadosReais(isRefresh: true);
    });
  }

  void _initializeAnimations(int count) {
    _fadeAnimations = List.generate(count, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.5),
            (index * 0.1 + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(count, (index) {
      return Tween<Offset>(
        begin: const Offset(0.3, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.5),
            (index * 0.1 + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosReais({bool isRefresh = false}) async {
    if (!mounted) return;

    if (!isRefresh) setState(() => _carregandoDados = true);

    try {
      final resultados = await Future.wait([
        _partidaService.listarPartidasDestaque(),
        _partidaService.listarHistoricoPartidas(),
      ]);

      if (mounted) {
        setState(() {
          _partidasDestaque = resultados[0];
          _historicoPartidas = resultados[1];

          if (!isRefresh) {
            _initializeAnimations(_partidasDestaque.length);
          }
          _carregandoDados = false;
        });

        if (!isRefresh) _animationController.forward();
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      if (mounted) setState(() => _carregandoDados = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _carregarDadosReais,
              color: const Color(0xFFF22F1D),
              backgroundColor: const Color(0xFF1A0202),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // --- HEADER ANIMADO COM SLIVER APP BAR ---
                  SliverAppBar(
                    expandedHeight: 80.0,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: const Color(
                      0xFF160202,
                    ).withValues(alpha: 0.95),
                    flexibleSpace: const FlexibleSpaceBar(
                      background: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: HomeHeader(),
                      ),
                    ),
                  ),

                  // --- ESTATÍSTICAS (NOVO) ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                      child: _buildStatsRow(),
                    ),
                  ),

                  // --- PARTIDAS AO VIVO ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF22F1D),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "PARTIDAS AO VIVO",
                            style: GoogleFonts.teko(
                              fontSize: 26,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCardsSection()),

                  const SliverToBoxAdapter(child: SizedBox(height: 30)),

                  // --- LISTA DE HISTÓRICO FLUIDA ---
                  SliverToBoxAdapter(child: _buildMainGamesSection()),

                  // Espaço para o Bottom Nav
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(currentRoute: '/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "AO VIVO",
            _partidasDestaque.length.toString(),
            Icons.sensors,
            const Color(0xFFF22F1D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "FINALIZADAS",
            _historicoPartidas.length.toString(),
            Icons.check_circle_outline,
            const Color(0xFFF26B1D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "NOVIDADES",
            "+2", // Exemplo genérico mockado
            Icons.whatshot,
            const Color(0xFFF29422),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF160202),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.teko(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    if (_carregandoDados && _partidasDestaque.isEmpty) {
      return const SizedBox(
        height: 185,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
        ),
      );
    }

    if (_partidasDestaque.isEmpty) {
      // Estilização muito mais premium e disruptiva para o fallback do AppBar vazio
      return Container(
        height: 185,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF160202),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF22F1D).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.sports_soccer,
                size: 150,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF22F1D),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "QUADRAS VAZIAS NO MOMENTO",
                  style: GoogleFonts.teko(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Siga acompanhando o app para novidades.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _partidasDestaque.length,
        itemBuilder: (context, index) {
          final partida = _partidasDestaque[index];
          return PartidaCard(
            partida: partida,
            fadeAnimation: _fadeAnimations.length > index
                ? _fadeAnimations[index]
                : const AlwaysStoppedAnimation(1.0),
            slideAnimation: _slideAnimations.length > index
                ? _slideAnimations[index]
                : const AlwaysStoppedAnimation(Offset.zero),
            onTap: () => _navegarParaPartida(context, partida),
          );
        },
      ),
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF110101),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2561D),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "HISTÓRICO",
                      style: GoogleFonts.teko(
                        fontSize: 24,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: Text(
                    _verMeus ? 'Ver Tudo' : 'Meus Favoritos',
                    style: TextStyle(
                      color: _verMeus
                          ? const Color(0xFFF22F1D)
                          : Colors.white60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_carregandoDados && _historicoPartidas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
            )
          else if (_historicoPartidas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "Nenhuma partida finalizada recentemente.",
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ..._historicoPartidas.map(
              (partida) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 8,
                ),
                child: PartidaListItem(
                  partida: partida,
                  onTap: () => _navegarParaPartida(context, partida),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navegarParaPartida(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          partidaId: partida.id,
          iniciadaEm: partida.iniciadaEm,
          modalidadeId: partida.modalidadeId,
          timeA: partida.equipeA?.nome ?? "Time A",
          timeB: partida.equipeB?.nome ?? "Time B",
          EscudoTimeA: partida.equipeA?.atletica?.escudoUrl ?? "",
          EscudoTimeB: partida.equipeB?.atletica?.escudoUrl ?? "",
          status: partida.status.toUpperCase(),
          placarA: partida.placarA.toString(),
          placarB: partida.placarB.toString(),
        ),
      ),
    ).then((_) => _carregarDadosReais(isRefresh: true));
  }
}
