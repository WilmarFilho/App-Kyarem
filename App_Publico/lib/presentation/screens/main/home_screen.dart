import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/services/atleta_service.dart';
import 'package:kyarem_eventos_publico/services/modalidade_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/models/modalidade_model.dart';
import '../../../services/partida_service.dart';
import '../game/partida_screen.dart';
import '../game/estatistica_atleta_screen.dart';
import '../../screens/modalidade/partidas_modalidade_screen.dart';
import '../../../../models/atleta_model.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/partida_list_item.dart';
import '../../widgets/home/partida_card.dart';

class HomeScreen extends StatefulWidget {
  final bool isMainScreenChild;
  final SupabaseClient? supabaseClient;
  final PartidaService? partidaService;
  final ModalidadeService? modalidadeService;
  final AtletaService? atletaService;

  const HomeScreen({
    super.key,
    this.isMainScreenChild = false,
    this.supabaseClient,
    this.partidaService,
    this.modalidadeService,
    this.atletaService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final SupabaseClient _supabase =
      widget.supabaseClient ?? Supabase.instance.client;
  late final PartidaService _partidaService =
      widget.partidaService ?? PartidaService();
  late final ModalidadeService _modalidadeService =
      widget.modalidadeService ?? ModalidadeService();
  late final AtletaService _atletaService =
      widget.atletaService ?? AtletaService();

  List<Partida> _partidasDestaque = [];
  List<Partida> _historicoPartidas = [];
  bool _carregandoDados = true;
  List<Modalidade> _modalidades = [];

  // Scroll-driven header animation
  final ScrollController _scrollController = ScrollController();
  double _headerCollapseProgress = 0.0;

  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations = [];
  late List<Animation<Offset>> _slideAnimations = [];

  late final Stream<List<Map<String, dynamic>>> _partidasRealtimeStream;

  List<Map<String, dynamic>> _topArtilheiros = [];
  List<Map<String, dynamic>> _topCestinhas = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Listener para animar o header com base no scroll
    _scrollController.addListener(_onScroll);

    _partidasRealtimeStream = _supabase
        .from('partidas_ao_vivo')
        .stream(primaryKey: ['partida_id']);

    _carregarDadosReais();
    _carregarDestaques();

    _partidasRealtimeStream.listen((_) {
      _carregarDadosReais(isRefresh: true);
    });
  }

  // 1. Ajuste na busca (buscando gols e pontos separadamente)
  void _carregarDestaques() async {
    try {
      final resultados = await Future.wait([
        _atletaService.getTopAthletes('GOL'),
        _atletaService.getTopAthletes('PONTO'),
      ]);

      if (mounted) {
        setState(() {
          _topArtilheiros = resultados[0];
          _topCestinhas = resultados[1];
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar destaques: $e");
    }
  }

  void _onScroll() {
    const maxScroll = 120.0; // pixels para colapsar totalmente
    final progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    if ((progress - _headerCollapseProgress).abs() > 0.01) {
      setState(() => _headerCollapseProgress = progress);
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosReais({bool isRefresh = false}) async {
    if (!mounted) return;
    if (!isRefresh) setState(() => _carregandoDados = true);

    // Buscas que possuem cache local (retornam quase instantaneamente)
    _partidaService
        .getFinishedMatches()
        .then<void>((historico) {
          if (mounted) setState(() => _historicoPartidas = historico);
        })
        .catchError((e) {
          debugPrint("Erro histórico: \$e");
        });

    _modalidadeService
        .getModalities()
        .then<void>((mods) {
          if (mounted) setState(() => _modalidades = mods);
        })
        .catchError((e) {
          debugPrint("Erro modalidades: \$e");
        });

    // O request de Partidas Ao Vivo não possui cache (pois é realtime)
    // Logo, ele ditará o fim do "_carregandoDados" geral.
    try {
      final destaques = await _partidaService.getActiveMatches();

      if (mounted) {
        setState(() {
          _partidasDestaque = destaques;

          if (!isRefresh) _initializeAnimations(_partidasDestaque.length);
          _carregandoDados = false;
        });
        if (!isRefresh) _animationController.forward();
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados ao vivo: \$e");
      if (mounted) setState(() => _carregandoDados = false);
    }
  }

  // ─── SECTION TITLE HELPER ───
  Widget _buildSectionTitle(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 14),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.oswald(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    // A altura do header diminui conforme o colapso
    final headerHeight = (155.0 - (_headerCollapseProgress * 150)).clamp(
      70.0,
      170.0,
    );

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),

          // ── CONTEÚDO SCROLLÁVEL ──
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _carregarDadosReais,
              color: AppColors.primary,
              backgroundColor: const Color(0xFF1A0202),
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(top: headerHeight),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // ── 2. PARTIDAS AO VIVO ──
                  _buildSectionTitle(
                    "PARTIDAS AO VIVO",
                    AppColors.primary,
                  ),
                  _buildCardsSection(),

                  // ── 3. ÚLTIMAS FINALIZADAS ──
                  _buildSectionTitle(
                    "ÚLTIMAS FINALIZADAS",
                    const Color(0xFFF22F1D),
                  ),
                  _buildFinalizadasSection(),

                  // ── 5. ATLETAS MVP ──
                  // No seu build, substitua as chamadas antigas por:
                  _buildSectionTitle(
                    "DESTAQUES DO CAMPEONATO",
                    const Color(0xFFF22F1D),
                  ),
                  _buildMvpSection([
                    if (_topArtilheiros.isNotEmpty) _topArtilheiros.first,
                    if (_topCestinhas.isNotEmpty) _topCestinhas.first,
                  ]),

                  // ── 4. MODALIDADES ──
                  _buildSectionTitle("MODALIDADES", const Color(0xFFF22F1D)),
                  _buildModalidadesSection(),
                  // Espaço para o Bottom Nav apenas se não for filho do MainScreen
                  if (!widget.isMainScreenChild)
                    const SizedBox(height: 120)
                  else
                    const SizedBox(height: 170),
                ],
              ),
            ),
          ),

          // ── HEADER FIXO NO TOPO ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(collapseProgress: _headerCollapseProgress),
          ),

          if (!widget.isMainScreenChild)
            const BottomNavigationWidget(currentIndex: 0),
        ],
      ),
    );
  }

  // ─── PARTIDAS AO VIVO ───
  Widget _buildCardsSection() {
    if (_carregandoDados && _partidasDestaque.isEmpty) {
      return const SizedBox(
        height: 185,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_partidasDestaque.isEmpty) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF160202),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
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
                size: 140,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "QUADRAS VAZIAS NO MOMENTO",
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Acompanhe o app para novidades!",
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

  // ─── ÚLTIMAS FINALIZADAS ───
  Widget _buildFinalizadasSection() {
    if (_carregandoDados && _historicoPartidas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    if (_historicoPartidas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Text(
          "Nenhuma partida finalizada recentemente.",
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return Column(
      children: _historicoPartidas.take(5).map((partida) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
          child: PartidaListItem(
            partida: partida,
            onTap: () => _navegarParaPartida(context, partida),
          ),
        );
      }).toList(),
    );
  }

  // ─── MODALIDADES ───
  Widget _buildModalidadesSection() {
    if (_carregandoDados && _modalidades.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _modalidades.length,
        itemBuilder: (context, index) {
          final mod = _modalidades[index];
          // Pegamos o nome e normalizamos para comparar
          final nomeMod = (mod.nome ?? '').toUpperCase();

          // 1. Definir ÍCONE baseado no NOME
          final IconData iconData = switch (nomeMod) {
            String s when s.contains('FUTSAL') || s.contains('FUTEBOL') =>
              Icons.sports_soccer,
            String s when s.contains('VÔLEI') || s.contains('VOLEI') =>
              Icons.sports_volleyball,
            String s when s.contains('BASQUETE') || s.contains('BASKET') =>
              Icons.sports_basketball,
            String s when s.contains('HANDEBOL') => Icons.sports_handball,
            String s when s.contains('TÊNIS') || s.contains('TENIS') =>
              Icons.sports_tennis,
            _ => Icons.sports, // Ícone padrão para outros
          };

          // 2. Definir COR baseado no NOME
          final Color modColor = switch (nomeMod) {
            String s when s.contains('FUTSAL') => const Color(
              0xFFF22F1D,
            ), // Vermelho
            String s when s.contains('VÔLEI') => const Color(
              0xFFF2561D,
            ), // Laranja
            String s when s.contains('BASQUETE') => const Color(
              0xFFF26B1D,
            ), // Laranja Escuro
            String s when s.contains('HANDEBOL') => const Color(
              0xFFF29422,
            ), // Âmbar
            _ => const Color(0xFFF22F1D), // Cor padrão
          };

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartidasModalidadeScreen(modalidade: mod),
                ),
              );
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: modColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: modColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: modColor, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nomeMod,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMvpSection(List<Map<String, dynamic>> destaques) {
    if (destaques.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        // === GRADIENTE ASSINATURA DO PARTIDA CARD ===
        gradient: const LinearGradient(
          colors: [
            AppColors.orange,
            AppColors.primary,
          ], // Laranja para Vermelho
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // === BORDA ARREDONDADA ===
        borderRadius: BorderRadius.circular(
          28,
        ), // Combinando com o estilo premium
        // === SOMBRA COLORIDA DISSIPADA ===
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFF22F1D,
            ).withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: destaques.map((atleta) {
          final bool isLast = destaques.last == atleta;

          // Mantemos o primaryColor (vermelho principal) para elementos internos
          const Color primaryColor = Color(0xFFF22F1D);

          return GestureDetector(
            onTap: () {
              if (atleta['atleta_id'] == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EstatisticaAtletaScreen(
                    atleta: Atleta(
                      id: atleta['atleta_id'].toString(),
                      atleticaId: '',
                      nome: atleta['nome'] ?? 'Atleta',
                      fotoUrl: atleta['foto'],
                    ),
                    timeNome: atleta['modalidade'] ?? 'Equipe',
                    escudoUrl: atleta['time_escudo'],
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top:
                    5, // Adicionado um recuo no topo para o primeiro card não colar no header
                bottom: isLast ? 5 : 16, // Espaçamento entre os cards (16px)
              ),
              height: 115, // Mais compacto e elegante
              decoration: BoxDecoration(
                // === FUNDO DO CARD INTERNO (TRANSPARÊNCIA SOBRE GRADIENTE) ===
                // Usamos branco opaco para criar um "vidro" sobre o gradiente vermelho
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                // Borda sutil para definir o limite do card
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Foto do Atleta ou Placeholder
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        // Sombra suave para o avatar se destacar
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                        image: atleta['foto'] != null
                            ? DecorationImage(
                                image: NetworkImage(atleta['foto']),
                                fit: BoxFit.cover,
                              )
                            : null,
                        // Borda sutil no avatar
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: atleta['foto'] == null
                          ? Icon(
                              Icons.person,
                              size: 35,
                              color: Colors.black.withValues(
                                alpha: 0.2,
                              ), // Ícone escuro suave
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Informações
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        // Garante que a coluna ocupe apenas o espaço necessário
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label + Valor juntos no Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  atleta['valor'] ?? '0',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Flexible previne overflow se o texto do label for muito longo
                                Flexible(
                                  child: Text(
                                    "${atleta['label']}${int.tryParse(atleta['valor'].toString()) != null && int.parse(atleta['valor'].toString()) > 1 ? 'S' : ''}"
                                        .toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ), // Reduzi de 8 para 4 para ganhar espaço vertical
                          Text(
                            atleta['nome']?.toUpperCase() ?? '',
                            style: GoogleFonts.oswald(
                              color: Colors.white,
                              fontSize: 18, // Reduzi levemente de 19 para 18
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            atleta['modalidade'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11, // Reduzi levemente de 12 para 11
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
