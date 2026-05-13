import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/layout/gradient_background.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/game_service.dart';

// 1. Defina esta classe simples fora do build para organizar os dados
class StatItem {
  final String label;
  final String value;
  final Color? color;
  StatItem(this.label, this.value, {this.color});
}

class ResumoEstatisticaPartidaScreen extends StatefulWidget {
  final String partidaId;
  final String timeA;
  final String timeB;
  final String? escudoA;
  final String? escudoB;
  final GameService? gameService;

  const ResumoEstatisticaPartidaScreen({
    super.key,
    required this.partidaId,
    required this.timeA,
    required this.timeB,
    this.escudoA,
    this.escudoB,
    this.gameService,
  });

  @override
  State<ResumoEstatisticaPartidaScreen> createState() =>
      _ResumoEstatisticaPartidaScreenState();
}

class _ResumoEstatisticaPartidaScreenState
    extends State<ResumoEstatisticaPartidaScreen> {
  late final GameService _gameService = widget.gameService ?? GameService();
  bool _isLoading = true;

  int golsA = 0;
  int faltasA = 0;
  int amarelosA = 0;
  int vermelhosA = 0;

  int golsB = 0;
  int faltasB = 0;
  int amarelosB = 0;
  int vermelhosB = 0;

  int _selectedTeamIndex = 0; // 0 para Time A, 1 para Time B

  Atleta? mvpData;
  int mvpGols = 0;
  String? mvpTeam;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      // Busca dados da partida no schema público (partidas_ao_vivo ou partidas_historico)
      final partidaData = await _gameService.getPartidaComEquipes(
        widget.partidaId,
      );

      final String? equipeIdA =
          (partidaData['campeonato_time_a_id'] ?? partidaData['equipe_a']?['id'])
              ?.toString();
      final String? equipeIdB =
          (partidaData['campeonato_time_b_id'] ?? partidaData['equipe_b']?['id'])
              ?.toString();

      // Busca eventos da partida em public.eventos_partida_publicos
      final eventosDocs = await _gameService.getEventosPartida(
        widget.partidaId,
      );

      Map<String, int> performanceAtletas = {};
      Map<String, Map<String, dynamic>> cacheAtletas = {};

      for (var ev in eventosDocs) {
        // Usa tipo_evento_codigo (campo correto no schema public)
        final rawCodigo = (
          ev['tipo_evento_codigo']?.toString() ??
          ev['tipo_evento_nome']?.toString() ??
          ''
        ).toUpperCase();

        final atletaId = ev['atleta_id']?.toString();
        final eventoEquipeId = ev['equipe_id']?.toString();

        final bool isTeamA =
            eventoEquipeId != null &&
            equipeIdA != null &&
            eventoEquipeId == equipeIdA;
        final bool isTeamB =
            eventoEquipeId != null &&
            equipeIdB != null &&
            eventoEquipeId == equipeIdB;

        if (rawCodigo.contains('GOL') ||
            rawCodigo.contains('CESTA') ||
            rawCodigo.contains('PONTO') ||
            rawCodigo.contains('PENALTI_CONVERTIDO')) {
          if (isTeamA) golsA++;
          if (isTeamB) golsB++;

          if (atletaId != null) {
            performanceAtletas[atletaId] =
                (performanceAtletas[atletaId] ?? 0) + 1;
            cacheAtletas[atletaId] = {
              'id': atletaId,
              'nome': ev['atleta_nome_exibicao'] ?? 'Atleta',
              'atletica_id': eventoEquipeId,
              'foto_url': ev['atleta_foto_url'],
            };
          }
        } else if (rawCodigo.contains('FALTA')) {
          if (isTeamA) faltasA++;
          if (isTeamB) faltasB++;
        } else if (rawCodigo.contains('AMARELO')) {
          if (isTeamA) amarelosA++;
          if (isTeamB) amarelosB++;
        } else if (rawCodigo.contains('VERMELHO')) {
          if (isTeamA) vermelhosA++;
          if (isTeamB) vermelhosB++;
        }
      }

      if (performanceAtletas.isNotEmpty) {
        String melhorAtletaId = performanceAtletas.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        mvpGols = performanceAtletas[melhorAtletaId]!;

        final mvpInfo = cacheAtletas[melhorAtletaId]!;
        mvpData = Atleta(
          id: mvpInfo['id'],
          atleticaId: mvpInfo['atletica_id'] ?? '',
          nome: mvpInfo['nome'],
          fotoUrl: mvpInfo['foto_url'],
        );
        mvpTeam = mvpInfo['atletica_id'] == equipeIdA
            ? widget.timeA
            : widget.timeB;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erro ao carregar resumo: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF22F1D);
    const Color accentColor = Color(0xFFF2561D);

    return Scaffold(
      backgroundColor: const Color(0xFF110101),
      body: Stack(
        children: [
          const GradientBackground(),

          CustomScrollView(
            slivers: [
              // === HEADER ESTÁTICO (SOBE COM O SCROLL) ===
              SliverToBoxAdapter(
                child: Container(
                  height: 120, // Mesma altura que estávamos usando
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    // Garante que não fique embaixo da barra de status
                    bottom: false,
                    child: Stack(
                      children: [
                        // BOTÃO VOLTAR
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: const EdgeInsets.only(left: 16),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        // TÍTULO CENTRALIZADO
                        Center(
                          child: Text(
                            "RESUMO DA PARTIDA",
                            style: GoogleFonts.oswald(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // === CONTEÚDO DO CORPO ===
              SliverToBoxAdapter(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildComparisonTable(),

                            const SizedBox(height: 20),

                            if (mvpData != null) ...[
                              _buildMvpCard(),
                              const SizedBox(height: 30),
                            ],

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMvpCard() {
    final hasMvpPhoto = mvpData?.fotoUrl != null && mvpData!.fotoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, const Color(0xFFFF8B70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "⭐ Destaque da Partida ⭐",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Borda dupla ou gradiente para destacar o MVP
              border: Border.all(color: const Color(0xFFF2561D), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF22F1D).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF110101),
              backgroundImage: hasMvpPhoto ? NetworkImage(mvpData!.fotoUrl!) : null,
              onBackgroundImageError: hasMvpPhoto
                  ? (exception, stackTrace) {
                      // Log opcional ou tratamento de erro de carregamento
                    }
                  : null,
              child: hasMvpPhoto
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.white24,
                    ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            mvpData!.nome,
            textAlign: TextAlign.center,
            textWidthBasis: TextWidthBasis
                .longestLine, // Ajuda a equilibrar o espaço ao redor
            style: GoogleFonts.oswald(
              // Mantendo o seu padrão esportivo
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height:
                  1.1, // Reduz o espaçamento entre linhas para o nome não "espalhar"
            ),
          ),
          const SizedBox(height: 5),
          Text(
            mvpTeam ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                "$mvpGols Gols",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final isTeamA = _selectedTeamIndex == 0;

    // 2. Mapeie os dados dinamicamente para as listas que o Column espera
    final List<StatItem> _statsTeamA = [
      StatItem("Gols / Pontos", golsA.toString()),
      StatItem("Faltas", faltasA.toString()),
      StatItem("Cartões Amarelos", amarelosA.toString(), color: Colors.amber),
      StatItem(
        "Cartões Vermelhos",
        vermelhosA.toString(),
        color: Colors.redAccent,
      ),
    ];

    final List<StatItem> _statsTeamB = [
      StatItem("Gols / Pontos", golsB.toString()),
      StatItem("Faltas", faltasB.toString()),
      StatItem("Cartões Amarelos", amarelosB.toString(), color: Colors.amber),
      StatItem(
        "Cartões Vermelhos",
        vermelhosB.toString(),
        color: Colors.redAccent,
      ),
    ];

    return Column(
      children: [
        // === SELETOR DE ABAS ===
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              _buildTabButton(widget.timeA, 0),
              _buildTabButton(widget.timeB, 1),
            ],
          ),
        ),

        // === ÁREA DE DADOS COM ANIMAÇÃO REFINADA ===
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isEntering = child.key == ValueKey<int>(_selectedTeamIndex);

              // Lógica de direção: Se selecionou o 0 (A), vem da esquerda (-0.2). Se 1 (B), vem da direita (0.2).
              double xOffset = _selectedTeamIndex == 0 ? -0.2 : 0.2;

              // Se o elemento estiver SAINDO, ele vai para o lado oposto
              if (!isEntering) xOffset = -xOffset;

              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: Offset(xOffset, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_selectedTeamIndex),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: (isTeamA ? _statsTeamA : _statsTeamB)
                    .map(
                      (stat) => _buildStatRowSingle(
                        stat.label,
                        stat.value,
                        color: stat.color,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para os botões das abas
  Widget _buildTabButton(String nome, int index) {
    final isSelected = _selectedTeamIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeamIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF22F1D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            nome.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para cada linha de estatística (Versão Individual)
  Widget _buildStatRowSingle(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: color ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
