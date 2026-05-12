import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/layout/gradient_background.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/evento_service.dart';
import '../../../../services/game_service.dart';

class EstatisticaAtletaScreen extends StatefulWidget {
  final String? partidaId;
  final Atleta atleta;
  final String timeNome;
  final String? escudoUrl;
  final GameService? gameService;
  final EventoService? eventoService;

  const EstatisticaAtletaScreen({
    super.key,
    this.partidaId,
    required this.atleta,
    required this.timeNome,
    this.escudoUrl,
    this.gameService,
    this.eventoService,
  });

  @override
  State<EstatisticaAtletaScreen> createState() =>
      _EstatisticaAtletaScreenState();
}

class _EstatisticaAtletaScreenState extends State<EstatisticaAtletaScreen> {
  late final GameService _gameService = widget.gameService ?? GameService();
  List<Map<String, dynamic>> _eventos = [];
  // _tiposEventos removido: usamos tipo_evento_codigo diretamente
  bool _isLoading = true;

  int gols = 0;
  int faltas = 0;
  int cartoesAmarelos = 0;
  int cartoesVermelhos = 0;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    try {
      List<Map<String, dynamic>> eventosDocs = [];

      if (widget.partidaId != null) {
        // Busca eventos do atleta na partida via public.eventos_partida_publicos
        eventosDocs = await _gameService.getEventosAtleta(
          widget.partidaId!,
          widget.atleta.id,
        );
      } else {
        // Busca todos os eventos do atleta via public.eventos_partida_publicos
        eventosDocs = await _gameService.getEventosAtletaGeral(
          widget.atleta.id,
        );
      }

      int calcGols = 0;
      int calcFaltas = 0;
      int calcCA = 0;
      int calcCV = 0;

      for (final ev in eventosDocs) {
        // Usa tipo_evento_codigo (campo correto no schema public)
        final rawCodigo = (
          ev['tipo_evento_codigo']?.toString() ??
          ev['tipo_evento_nome']?.toString() ??
          ''
        ).toUpperCase();

        final atletaEvId = ev['atleta_id']?.toString();
        if (atletaEvId == widget.atleta.id) {
          if (rawCodigo.contains('GOL') ||
              rawCodigo.contains('CESTA') ||
              rawCodigo.contains('PONTO') ||
              rawCodigo.contains('PENALTI_CONVERTIDO')) {
            calcGols++;
          } else if (rawCodigo.contains('FALTA')) {
            calcFaltas++;
          } else if (rawCodigo.contains('AMARELO')) {
            calcCA++;
          } else if (rawCodigo.contains('VERMELHO')) {
            calcCV++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventos = eventosDocs;
          gols = calcGols;
          faltas = calcFaltas;
          cartoesAmarelos = calcCA;
          cartoesVermelhos = calcCV;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar estats individuais: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110101),
      body: Stack(
        children: [
          const GradientBackground(), // Seu widget de fundo
          CustomScrollView(
            slivers: [
              // HEADER ESTÁTICO COM GRADIENTE E SETA VOLTAR
              SliverToBoxAdapter(
                child: Container(
                  height: 120,
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
                    bottom: false,
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
                            "ESTATÍSTICAS DO ATLETA",
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

              // CONTEÚDO
              SliverToBoxAdapter(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 30),
                            _buildStatsGrid(),
                            const SizedBox(height: 40),
                            _buildSectionTitle(),
                            const SizedBox(height: 20),
                            _buildTimeline(),
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.black,
              backgroundImage: widget.atleta.fotoUrl != null
                  ? NetworkImage(widget.atleta.fotoUrl!)
                  : null,
              child: widget.atleta.fotoUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white24)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.atleta.nome.toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.escudoUrl != null) ...[
                      Image.network(widget.escudoUrl!, height: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.timeNome,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          "Gols",
          gols.toString(),
          Icons.sports_soccer,
          Colors.green,
        ),
        _buildStatCard(
          "Faltas",
          faltas.toString(),
          Icons.front_hand,
          Colors.orange,
        ),
        _buildStatCard(
          "C. Amarelo",
          cartoesAmarelos.toString(),
          Icons.style,
          Colors.amber,
        ),
        _buildStatCard(
          "C. Vermelho",
          cartoesVermelhos.toString(),
          Icons.style,
          Colors.red,
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, color: color.withValues(alpha: 0.05), size: 60),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.oswald(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            color: Colors.white.withValues(alpha: 0.2),
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            widget.partidaId != null
                ? "Nenhum lance registrado nesta partida."
                : "Nenhum histórico de lances encontrado.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_eventos.isEmpty) return _buildEmptyState();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final ev = _eventos[index];
        // Usa tipo_evento_codigo (campo do schema public) para lookup amigável
        final rawCodigo = ev['tipo_evento_codigo']?.toString() ??
            ev['tipo_evento_nome']?.toString() ??
            'Evento';
        final name = EventoService.friendly(rawCodigo);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LINHA DO TEMPO (INDICADOR VISUAL)
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(
                    top: 20,
                  ), // Alinha com o centro do card
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (index != _eventos.length - 1)
                  Container(
                    width: 2,
                    height: 60, // Aumentado para compensar o padding do card
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(width: 15),

            // CONTEÚDO DO LANCE COM BACKGROUND VISÍVEL (GLASSMORPHISM)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ), // Fundo levemente visível
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), // Borda sutil
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white24,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ev['minuto'] != null
                              ? '${ev['minuto']}\'${ev['segundo'] != null ? ':${ev['segundo']}"' : ''}'
                              : (ev['tempo_cronometro'] ?? "Tempo não definido"),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.partidaId != null
            ? "LANCES DESTA PARTIDA"
            : "HISTÓRICO DE LANCES",
        style: GoogleFonts.oswald(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
