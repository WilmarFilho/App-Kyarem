import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/game_service.dart';

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
      final partidaData = await _gameService.getPartidaComEquipes(widget.partidaId);

      final String? atleticaIdA = partidaData['equipe_a']?['atletica_id']?.toString();
      final String? atleticaIdB = partidaData['equipe_b']?['atletica_id']?.toString();
      final String modalidadeId = partidaData['modalidade_id'];

      final modalidadeInfo = await _gameService.getModalidadeInfo(modalidadeId);
      final tipos = await _gameService.getTiposEventos(modalidadeInfo['esporte_id']);
      final eventosDocs = await _gameService.getEventosPartida(widget.partidaId);

      Map<String, int> performanceAtletas = {};
      Map<String, Map<String, dynamic>> cacheAtletas = {};

      for (var ev in eventosDocs) {
        final tipoId = ev['tipo_evento_id'];
        final tipo = tipos.firstWhere(
          (t) => t['id'] == tipoId,
          orElse: () => {'nome': ''},
        );
        final rawNome = (tipo['nome']?.toString() ?? '').toUpperCase();

        final atletaInfo = ev['atletas'];
        if (atletaInfo == null) continue;

        final atletaId = ev['atleta_id'];
        final atletaAtleticaId = atletaInfo['atletica_id']?.toString();

        bool isTeamA = atletaAtleticaId == atleticaIdA;
        bool isTeamB = atletaAtleticaId == atleticaIdB;

        if (rawNome.contains('GOL') || rawNome.contains('PENALTI_CONVERTIDO')) {
          if (isTeamA) golsA++;
          if (isTeamB) golsB++;

          if (atletaId != null) {
            performanceAtletas[atletaId] =
                (performanceAtletas[atletaId] ?? 0) + 1;
            cacheAtletas[atletaId] = {
              'id': atletaId,
              'nome': atletaInfo['nome'],
              'atletica_id': atletaAtleticaId,
            };
          }
        } else if (rawNome.contains('FALTA')) {
          if (isTeamA) faltasA++;
          if (isTeamB) faltasB++;
        } else if (rawNome.contains('AMARELO')) {
          if (isTeamA) amarelosA++;
          if (isTeamB) amarelosB++;
        } else if (rawNome.contains('VERMELHO')) {
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
          atleticaId: mvpInfo['atletica_id'],
          nome: mvpInfo['nome'],
        );
        mvpTeam = mvpInfo['atletica_id'] == atleticaIdA
            ? widget.timeA
            : widget.timeB;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Erro ao carregar resumo: \$e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "RESUMO DA PARTIDA",
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mvpData != null) _buildMvpCard(),
                  if (mvpData != null) const SizedBox(height: 30),
                  const Text(
                    "COMPARAÇÃO DE EQUIPES",
                    style: TextStyle(
                      fontFamily: 'Bebas Neue',
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildComparisonTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildMvpCard() {
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
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.star, size: 40, color: Colors.amber),
          ),
          const SizedBox(height: 15),
          Text(
            mvpData!.nome,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.timeA,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  widget.timeB,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1),
          _buildStatRow("Gols / Pontos", golsA.toString(), golsB.toString()),
          _buildStatRow("Faltas", faltasA.toString(), faltasB.toString()),
          _buildStatRow(
            "Cartões Amarelos",
            amarelosA.toString(),
            amarelosB.toString(),
          ),
          _buildStatRow(
            "Cartões Vermelhos",
            vermelhosA.toString(),
            vermelhosB.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String valA, String valB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  valA,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: Text(
                  valB,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
