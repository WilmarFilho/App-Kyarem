import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/layout/gradient_background.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/game_service.dart';
import 'estatistica_atleta_screen.dart';

class AtletasPartidaScreen extends StatefulWidget {
  final String partidaId;
  final String timeA;
  final String timeB;
  final String? escudoA;
  final String? escudoB;
  final GameService? gameService;

  const AtletasPartidaScreen({
    super.key,
    required this.partidaId,
    required this.timeA,
    required this.timeB,
    this.escudoA,
    this.escudoB,
    this.gameService,
  });

  @override
  State<AtletasPartidaScreen> createState() => _AtletasPartidaScreenState();
}

class _AtletasPartidaScreenState extends State<AtletasPartidaScreen>
    with SingleTickerProviderStateMixin {
  late final GameService _gameService = widget.gameService ?? GameService();
  late TabController _tabController;

  List<Atleta> _titularesA = [];
  List<Atleta> _reservasA = [];
  List<Atleta> _titularesB = [];
  List<Atleta> _reservasB = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final partidaData = await _gameService.getPartidaEquipes(
        widget.partidaId,
      );
      final equipeIdA = partidaData['equipe_a_id']?.toString();
      final equipeIdB = partidaData['equipe_b_id']?.toString();

      final futures = <Future>[];
      if (equipeIdA != null) futures.add(_fetchAtletas(equipeIdA, true));
      if (equipeIdB != null) futures.add(_fetchAtletas(equipeIdB, false));

      await Future.wait(futures);
    } catch (e) {
      debugPrint("Erro ao carregar atletas: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAtletas(String equipeId, bool isTimeA) async {
    final inscritos = await _gameService.getAtletasInscritos(equipeId);
    List<Atleta> t = [];
    List<Atleta> r = [];

    for (var inscrito in inscritos) {
      final atletaMap = inscrito['atletas'];
      if (atletaMap != null) {
        final atleta = Atleta.fromMap(atletaMap);
        inscrito['ativo'] == true ? t.add(atleta) : r.add(atleta);
      }
    }
    t.sort((a, b) => a.nome.compareTo(b.nome));
    r.sort((a, b) => a.nome.compareTo(b.nome));

    if (isTimeA) {
      _titularesA = t;
      _reservasA = r;
    } else {
      _titularesB = t;
      _reservasB = r;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110101),
      body: Stack(
        children: [
          const GradientBackground(),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : CustomScrollView(
                  slivers: [
                    // HEADER ESTÁTICO (IGUAL À OUTRA TELA)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.orange, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: SafeArea(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  padding: const EdgeInsets.only(left: 16),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Center(
                                child: Text(
                                  "ELENCO",
                                  style: GoogleFonts.oswald(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 35)),

                    // TAB BAR CUSTOMIZADO
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.primary,
                            ),
                            labelColor: Colors.white, // TEXTO DA ABA ATIVA
                            unselectedLabelColor: Colors.white.withValues(
                              alpha: 0.5,
                            ), // ABA INATIVA
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: GoogleFonts.poppins(
                              fontSize: 13,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: widget.timeA.toUpperCase()),
                              Tab(text: widget.timeB.toUpperCase()),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 35)),

                    // LISTA DE ATLETAS (USA SLIVER FILL REMAINING PARA O TABBARVIEW)
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListaTime(
                            _titularesA,
                            _reservasA,
                            widget.timeA,
                            widget.escudoA,
                          ),
                          _buildListaTime(
                            _titularesB,
                            _reservasB,
                            widget.timeB,
                            widget.escudoB,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildListaTime(
    List<Atleta> titulares,
    List<Atleta> reservas,
    String timeNome,
    String? escudoUrl,
  ) {
    if (titulares.isEmpty && reservas.isEmpty) {
      return Center(
        child: Text(
          'Nenhum atleta inscrito.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        if (titulares.isNotEmpty) ...[
          _buildSectionHeader("TITULARES"),
          ...titulares.map((a) => _buildAtletaCard(a, timeNome, escudoUrl)),
          const SizedBox(height: 25),
        ],
        if (reservas.isNotEmpty) ...[
          _buildSectionHeader("RESERVAS"),
          ...reservas.map((a) => _buildAtletaCard(a, timeNome, escudoUrl)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 4),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 18,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAtletaCard(Atleta atleta, String timeNome, String? escudoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstatisticaAtletaScreen(
              partidaId: widget.partidaId,
              atleta: atleta,
              timeNome: timeNome,
              escudoUrl: escudoUrl,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.black,
            backgroundImage: atleta.fotoUrl != null
                ? NetworkImage(atleta.fotoUrl!)
                : null,
            child: atleta.fotoUrl == null
                ? const Icon(Icons.person, color: Colors.white24)
                : null,
          ),
        ),
        title: Text(
          atleta.nome.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
