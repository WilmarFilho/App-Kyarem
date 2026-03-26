import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/modalidade_model.dart';
import '../../../models/partida_model.dart';
import '../../../services/estatistica_service.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../game/partida_screen.dart';

class PartidasModalidadeScreen extends StatefulWidget {
  final Modalidade modalidade;
  final String campeonatoNome;

  const PartidasModalidadeScreen({
    super.key,
    required this.modalidade,
    required this.campeonatoNome,
  });

  @override
  State<PartidasModalidadeScreen> createState() =>
      _PartidasModalidadeScreenState();
}

enum _FiltroStatus { todas, agendadas, emAndamento, finalizadas }

class _PartidasModalidadeScreenState extends State<PartidasModalidadeScreen> {
  final _partidaService = PartidaService();
  final _estatisticaService = EstatisticaService();

  bool _loading = true;
  bool _loadingStats = true;
  _FiltroStatus _filtro = _FiltroStatus.todas;
  String _ordemStats = 'Gols'; // 'Gols', 'Faltas', 'Cartões', 'Pênaltis'
  List<Partida> _partidas = [];
  List<EstatisticaAtleta> _estatisticas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _loadingStats = true);
    final stats = await _estatisticaService.getEstatisticsByModality(
      widget.modalidade.id,
    );
    if (!mounted) return;
    setState(() {
      _estatisticas = stats;
      _ordenarEstatisticas();
      _loadingStats = false;
    });
  }

  void _ordenarEstatisticas() {
    setState(() {
      switch (_ordemStats) {
        case 'Gols':
          _estatisticas.sort((a, b) => b.gols.compareTo(a.gols));
          break;
        case 'Faltas':
          _estatisticas.sort((a, b) => b.faltas.compareTo(a.faltas));
          break;
        case 'Cartões':
          _estatisticas.sort((a, b) {
            final totalA = a.cartoesAmarelos + (a.cartoesVermelhos * 2);
            final totalB = b.cartoesAmarelos + (b.cartoesVermelhos * 2);
            return totalB.compareTo(totalA);
          });
          break;
        case 'Pênaltis':
          _estatisticas.sort((a, b) => b.penaltis.compareTo(a.penaltis));
          break;
      }
    });
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);

    // 1) Partidas (Supabase)
    final statusSupabase = _statusParaApi(_filtro);
    var partidas = await _partidaService.getMatchesByModalityAndStatus(
      modalityId: widget.modalidade.id,
      status: statusSupabase ?? 'all',
    );

    // 2) Filtro "Em andamento"
    if (_filtro == _FiltroStatus.emAndamento) {
      partidas = partidas.where((p) {
        final st = p.status.trim().toLowerCase();
        return st != 'agendada' && st != 'finalizada' && st != 'fechada';
      }).toList();
    }

    // 3) Ordenação
    partidas.sort((a, b) {
      final da = a.iniciadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.iniciadaEm ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    if (!mounted) return;
    setState(() {
      _partidas = partidas;
      _loading = false;
    });
  }

  String? _statusParaApi(_FiltroStatus filtro) {
    switch (filtro) {
      case _FiltroStatus.agendadas:
        return 'agendada';
      case _FiltroStatus.finalizadas:
        return 'finalizada';
      case _FiltroStatus.emAndamento:
        return null;
      case _FiltroStatus.todas:
        return null;
    }
  }

  String _tituloFiltro(_FiltroStatus filtro) {
    switch (filtro) {
      case _FiltroStatus.agendadas:
        return 'Agendadas';
      case _FiltroStatus.emAndamento:
        return 'Em andamento';
      case _FiltroStatus.finalizadas:
        return 'Finalizadas';
      case _FiltroStatus.todas:
        return 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (widget.modalidade.nome ?? 'Modalidade').trim().isNotEmpty
        ? widget.modalidade.nome!
        : 'Modalidade';

    return Scaffold(
      backgroundColor: const Color(0xFF260404),
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF110101),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            const GradientBackground(),
            Column(
              children: [
                _buildHeader(titulo),
                Container(
                  color: const Color(0xFF110101),
                  child: const TabBar(
                    labelColor: Color(0xFFF22F1D),
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Color(0xFFF22F1D),
                    tabs: [
                      Tab(text: 'Partidas'),
                      Tab(text: 'Estatísticas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Primeira aba: Lista de Partidas
                      _buildAbaPartidas(),
                      // Segunda aba: Estatísticas
                      _buildAbaEstatisticas(),
                    ],
                  ),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationWidget(currentRoute: '/modalidades'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbaPartidas() {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
          )
        : RefreshIndicator(
            onRefresh: _carregar,
            color: const Color(0xFFF22F1D),
            child: _partidas.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Nenhuma partida encontrada.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    itemCount: _partidas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PartidaTile(
                      partida: _partidas[i],
                      onTap: () => _abrirDetalhe(_partidas[i]),
                    ),
                  ),
          );
  }

  Widget _buildAbaEstatisticas() {
    return _loadingStats
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFF22F1D)),
          )
        : RefreshIndicator(
            onRefresh: _carregarEstatisticas,
            color: const Color(0xFFF22F1D),
            child: _estatisticas.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Nenhuma estatística encontrada para esta modalidade.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildSortingChips()),
                      if (_ordemStats == 'Gols' && _estatisticas.length >= 3)
                        SliverToBoxAdapter(child: _buildPodium()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            // Se estivermos mostrando o pódio, pulamos os 3 primeiros na lista principal
                            final showPodium =
                                _ordemStats == 'Gols' &&
                                _estatisticas.length >= 3;
                            final offset = showPodium ? 3 : 0;
                            if (i + offset >= _estatisticas.length) {
                              return null;
                            }

                            final est = _estatisticas[i + offset];
                            return _buildEstatisticaItem(est, i + offset);
                          }),
                        ),
                      ),
                    ],
                  ),
          );
  }

  Widget _buildSortingChips() {
    final filters = ['Gols', 'Faltas', 'Cartões', 'Pênaltis'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: filters.map((f) {
            final isSelected = _ordemStats == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _ordemStats = f;
                      _ordenarEstatisticas();
                    });
                  }
                },
                selectedColor: const Color(0xFFF22F1D),
                backgroundColor: const Color(0xFF1A0202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFF22F1D)
                        : Colors.white12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPodium() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumSpot(_estatisticas[1], 2)),
          Expanded(child: _buildPodiumSpot(_estatisticas[0], 1)),
          Expanded(child: _buildPodiumSpot(_estatisticas[2], 3)),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(EstatisticaAtleta est, int pos) {
    final heightFactor = pos == 1 ? 1.0 : (pos == 2 ? 0.8 : 0.7);
    final color = pos == 1
        ? const Color(0xFFFFD700)
        : (pos == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: pos == 1 ? 32 : 26,
          backgroundColor: color.withOpacity(0.2),
          child: CircleAvatar(
            radius: pos == 1 ? 28 : 23,
            backgroundColor: const Color(0xFF110101),
            backgroundImage: (est.fotoUrl != null && est.fotoUrl!.isNotEmpty)
                ? NetworkImage(est.fotoUrl!)
                : (est.equipeEscudoUrl != null &&
                      est.equipeEscudoUrl!.isNotEmpty)
                ? NetworkImage(est.equipeEscudoUrl!)
                : null,
            child:
                ((est.fotoUrl == null || est.fotoUrl!.isEmpty) &&
                    (est.equipeEscudoUrl == null ||
                        est.equipeEscudoUrl!.isEmpty))
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          est.nomeAtleta.split(' ').first,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 100 * heightFactor,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.6)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$posº',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Oswald',
                ),
              ),
              Text(
                '${est.gols} Gols',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstatisticaItem(EstatisticaAtleta est, int pos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0202),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${pos + 1}º',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white30,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2A0808),
            backgroundImage: (est.fotoUrl != null && est.fotoUrl!.isNotEmpty)
                ? NetworkImage(est.fotoUrl!)
                : (est.equipeEscudoUrl != null &&
                      est.equipeEscudoUrl!.isNotEmpty)
                ? NetworkImage(est.equipeEscudoUrl!)
                : null,
            child:
                ((est.fotoUrl == null || est.fotoUrl!.isEmpty) &&
                    (est.equipeEscudoUrl == null ||
                        est.equipeEscudoUrl!.isEmpty))
                ? const Icon(Icons.person, size: 20, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  est.nomeAtleta,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                Text(
                  est.equipeNome,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildStatMiniBadge('⚽', est.gols.toString(), est.gols > 0),
              _buildStatMiniBadge(
                '🟨',
                est.cartoesAmarelos.toString(),
                est.cartoesAmarelos > 0,
              ),
              _buildStatMiniBadge(
                '🟥',
                est.cartoesVermelhos.toString(),
                est.cartoesVermelhos > 0,
              ),
              _buildStatMiniBadge('🚫', est.faltas.toString(), est.faltas > 0),
              _buildStatMiniBadge(
                '🎯',
                est.penaltis.toString(),
                est.penaltis > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniBadge(String emoji, String value, bool visible) {
    if (!visible) return const SizedBox.shrink();
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String titulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF110101),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.campeonatoNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (widget.modalidade.esporteNome ?? '').isNotEmpty
                      ? '${widget.modalidade.esporteNome} • $titulo'
                      : titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_FiltroStatus>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (v) {
              setState(() => _filtro = v);
              _carregar();
            },
            itemBuilder: (context) {
              return _FiltroStatus.values
                  .map(
                    (v) => PopupMenuItem<_FiltroStatus>(
                      value: v,
                      child: Text(_tituloFiltro(v)),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  void _abrirDetalhe(Partida p) {
    final timeA = p.equipeA?.nome ?? 'Time A';
    final timeB = p.equipeB?.nome ?? 'Time B';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          partidaId: p.id,
          modalidadeId: p.modalidadeId,
          timeA: timeA,
          timeB: timeB,
          // ✅ Escudos enriquecidos
          EscudoTimeA: p.equipeA?.atleticaEscudoUrl,
          EscudoTimeB: p.equipeB?.atleticaEscudoUrl,
          status: p.status,
          placarA: p.placarA.toString(),
          placarB: p.placarB.toString(),
        ),
      ),
    );
  }
}

class _PartidaTile extends StatelessWidget {
  final Partida partida;
  final VoidCallback onTap;

  const _PartidaTile({required this.partida, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeA = partida.equipeA?.nome ?? 'Time A';
    final timeB = partida.equipeB?.nome ?? 'Time B';
    final escudoA = partida.equipeA?.atleticaEscudoUrl ?? '';
    final escudoB = partida.equipeB?.atleticaEscudoUrl ?? '';

    final st = partida.status.toUpperCase();
    final isFinalizada =
        partida.status.trim().toLowerCase() == 'finalizada' ||
        partida.status.trim().toLowerCase() == 'fechada';
    final isAoVivo =
        partida.status.trim().toLowerCase() != 'agendada' && !isFinalizada;

    final dt = partida.iniciadaEm;
    final dtStr = dt != null
        ? DateFormat('dd/MM • HH:mm').format(dt.toLocal())
        : '';

    final badgeColor = isAoVivo
        ? Colors.green
        : isFinalizada
        ? Colors.grey
        : const Color(0xFFF22F1D);

    return Material(
      color: const Color(0xFF110101),
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              // ── Badge + data ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (dtStr.isNotEmpty)
                    Text(
                      dtStr,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAoVivo) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          st,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Times + Placar ────────────────────────────────────────
              Row(
                children: [
                  // Time A
                  Expanded(
                    child: _buildTeamBlock(
                      escudoA,
                      timeA,
                      CrossAxisAlignment.start,
                    ),
                  ),

                  // Placar central
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          '${partida.placarA}  –  ${partida.placarB}',
                          style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        if ((partida.local ?? '').trim().isNotEmpty)
                          Text(
                            partida.local!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Time B
                  Expanded(
                    child: _buildTeamBlock(
                      escudoB,
                      timeB,
                      CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBlock(
    String url,
    String nome,
    CrossAxisAlignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF2A0808),
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
          onBackgroundImageError: url.isNotEmpty
              ? (error, stackTrace) {
                  print('ERRO AO CARREGAR IMAGEM ($url): $error');
                }
              : null,
          child: url.isEmpty
              ? Text(
                  nome.isNotEmpty ? nome[0] : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          nome,
          maxLines: 2,
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
