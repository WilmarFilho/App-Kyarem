import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/evento_service.dart';

class EstatisticaAtletaScreen extends StatefulWidget {
  final String partidaId;
  final Atleta atleta;
  final String timeNome;
  final String? escudoUrl;

  const EstatisticaAtletaScreen({
    super.key,
    required this.partidaId,
    required this.atleta,
    required this.timeNome,
    this.escudoUrl,
  });

  @override
  State<EstatisticaAtletaScreen> createState() =>
      _EstatisticaAtletaScreenState();
}

class _EstatisticaAtletaScreenState extends State<EstatisticaAtletaScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _tiposEventos = [];
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
      // 1. Busca modalidade e esporte para carregar os tipos de eventos
      final partidaData = await _supabase
          .from('partidas')
          .select('modalidade_id')
          .eq('id', widget.partidaId)
          .single();

      final tipos = await EventoService().buscarTiposPorPartida(
        partidaData['modalidade_id'],
      );

      debugPrint('tipos: $tipos');

      // 2. Busca todos os eventos DESSA partida relacionados DSTE atleta
      // Ele é o 'atleta_id' (quem fez o evento) ou 'atleta_sai_id' (substituído)
      final eventosDocs = await _supabase
          .from('eventos_partida')
          .select('*')
          .eq('partida_id', widget.partidaId)
          .or(
            'atleta_id.eq.${widget.atleta.id},atleta_sai_id.eq.${widget.atleta.id}',
          );

      debugPrint('eventosDocs: $eventosDocs');

      debugPrint('widget.atleta.id: ${widget.atleta.id}');

      // 3. Processa e calcula as estatísticas
      int calcGols = 0;
      int calcFaltas = 0;
      int calcCA = 0;
      int calcCV = 0;

      for (final ev in eventosDocs) {
        final tipoId = ev['tipo_evento_id'];
        final tipo = tipos.firstWhere(
          (t) => t['id'] == tipoId,
          orElse: () => {'nome': ''},
        );
        final rawNome = (tipo['nome']?.toString() ?? '').toUpperCase();

        // Só conta se ele foi o autor principal da ação (atleta_id)
        if (ev['atleta_id'] == widget.atleta.id) {
          if (rawNome.contains('GOL') ||
              rawNome.contains('PENALTI_CONVERTIDO')) {
            calcGols++;
          } else if (rawNome.contains('FALTA')) {
            calcFaltas++;
          } else if (rawNome.contains('AMARELO')) {
            calcCA++;
          } else if (rawNome.contains('VERMELHO')) {
            calcCV++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventos = List<Map<String, dynamic>>.from(eventosDocs);
          _tiposEventos = tipos;
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "ESTATÍSTICAS DO ATLETA",
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF85C39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "LANCES DESTA PARTIDA",
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTimeline(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF5F5F5),
            backgroundImage: widget.atleta.fotoUrl != null
                ? NetworkImage(widget.atleta.fotoUrl!)
                : null,
            child: widget.atleta.fotoUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.atleta.nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.timeNome,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_eventos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Nenhum lance registrado para este atleta na partida.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _eventos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ev = _eventos[index];
        final tipoId = ev['tipo_evento_id'];
        final tipo = _tiposEventos.firstWhere(
          (t) => t['id'] == tipoId,
          orElse: () => {'nome': 'Evento'},
        );
        final friendlyName = EventoService.friendly(tipo['nome']?.toString());

        // Tratamento de mensagens baseadas no tipo de evento
        String subtitulo = ev['tempo_cronometro'] ?? '--:--';
        if (friendlyName.contains("Substituição")) {
          if (ev['atleta_id'] == widget.atleta.id) {
            subtitulo += " - Entrou em campo";
          } else if (ev['atleta_sai_id'] == widget.atleta.id) {
            subtitulo += " - Saiu de campo";
          }
        }

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF85C39).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFFF85C39),
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendlyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
