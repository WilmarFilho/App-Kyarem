import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:intl/intl.dart';

import '../../../models/atleta_model.dart';
import '../../../models/modalidade_model.dart';
import '../../../models/partida_model.dart';
import '../../../services/estatistica_service.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../game/estatistica_atleta_screen.dart';
import '../game/partida_screen.dart';
import '../main/main_screen.dart';

class _WaveClipper extends CustomClipper<Path> {
  final double waveHeight;
  _WaveClipper({this.waveHeight = 30});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - waveHeight);
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - waveHeight);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint = Offset(
      size.width * 0.75,
      size.height - waveHeight * 2,
    );
    final secondEndPoint = Offset(size.width, size.height - waveHeight);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) =>
      oldClipper.waveHeight != waveHeight;
}

class PartidasModalidadeScreen extends StatefulWidget {
  final Modalidade modalidade;
  final PartidaService? partidaService;
  final EstatisticaService? estatisticaService;

  const PartidasModalidadeScreen({
    super.key,
    required this.modalidade,
    this.partidaService,
    this.estatisticaService,
  });

  @override
  State<PartidasModalidadeScreen> createState() =>
      _PartidasModalidadeScreenState();
}

enum _FiltroStatus { todas, agendadas, emAndamento, finalizadas }

class _PartidasModalidadeScreenState extends State<PartidasModalidadeScreen> {
  late final PartidaService _partidaService =
      widget.partidaService ?? PartidaService();
  late final EstatisticaService _estatisticaService =
      widget.estatisticaService ?? EstatisticaService();

  bool _loading = true;
  bool _loadingStats = true;
  _FiltroStatus _filtro = _FiltroStatus.todas;
  String _ordemStats = 'Gols';
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
    try {
      final stats = await _estatisticaService.getEstatisticsByModality(
        widget.modalidade.id,
      );
      if (!mounted) return;
      setState(() {
        _estatisticas = stats;
        _ordenarEstatisticas();
        _loadingStats = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      if (!mounted) return;
      setState(() {
        _estatisticas = [];
        _loadingStats = false;
      });
    }
  }

  void _ordenarEstatisticas() {
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
  }

  num _getStatValue(EstatisticaAtleta est) {
    switch (_ordemStats) {
      case 'Gols':
        return est.gols;
      case 'Faltas':
        return est.faltas;
      case 'Cartões':
        return est.cartoesAmarelos + est.cartoesVermelhos;
      case 'Pênaltis':
        return est.penaltis;
      default:
        return est.gols;
    }
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final statusSupabase = _statusParaApi(_filtro);
      var partidas = await _partidaService.getMatchesByModalityAndStatus(
        modalityId: widget.modalidade.id,
        status: statusSupabase ?? 'all',
      );

      if (_filtro == _FiltroStatus.emAndamento) {
        partidas = partidas.where((p) {
          final st = p.status.trim().toLowerCase();
          return st != 'agendada' && st != 'finalizada' && st != 'fechada';
        }).toList();
      }

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
    } catch (e) {
      debugPrint('Erro ao carregar partidas: $e');
      if (!mounted) return;
      setState(() {
        _partidas = [];
        _loading = false;
      });
    }
  }

  String? _statusParaApi(_FiltroStatus filtro) {
    switch (filtro) {
      case _FiltroStatus.agendadas:
        return 'agendada';
      case _FiltroStatus.finalizadas:
        return 'finalizada';
      default:
        return null;
    }
  }

  void _onBottomTabSelected(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String titulo = (widget.modalidade.nome?.trim().isNotEmpty ?? false)
        ? widget.modalidade.nome!.toUpperCase()
        : 'MODALIDADE';

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: DefaultTabController(
        length: 2,
        child: Stack(
          children: [
            const GradientBackground(),
            Column(
              children: [
                _buildHeader(titulo),
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                      tabs: const [
                        Tab(text: 'PARTIDAS'),
                        Tab(text: 'ESTATÍSTICAS'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [_buildAbaPartidas(), _buildAbaEstatisticas()],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavigationWidget(
                currentIndex: 1,
                onTabSelected: _onBottomTabSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String titulo) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        height: 140 + statusBarHeight,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, statusBarHeight, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.bgDeep,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  titulo,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bgDeep,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbaPartidas() {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : RefreshIndicator(
            onRefresh: _carregar,
            color: AppColors.primary,
            child: _partidas.isEmpty
                ? _buildEmptyState('Nenhuma partida encontrada.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    physics: const BouncingScrollPhysics(),
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
    if (_loadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarEstatisticas,
      color: AppColors.primary,
      child: _estatisticas.isEmpty
          ? _buildEmptyState('Nenhuma estatística encontrada.')
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildSortingChips()),
                if (_estatisticas.length >= 3)
                  SliverToBoxAdapter(child: _buildPodium()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final bool hasPodium = _estatisticas.length >= 3;
                        final int index = hasPodium ? i + 3 : i;
                        if (index >= _estatisticas.length) return null;
                        return _buildEstatisticaItem(
                          _estatisticas[index],
                          index,
                        );
                      },
                      childCount: _estatisticas.length >= 3
                          ? _estatisticas.length - 3
                          : _estatisticas.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.info_outline, color: Colors.white24, size: 48),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            mensagem,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
                  if (!selected) return;
                  setState(() {
                    _ordemStats = f;
                    _ordenarEstatisticas();
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.bgDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.white12,
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
      // Aumentamos levemente para 240 ou 250 para dar respiro,
      // ou mantemos 220 e deixamos o Expanded trabalhar.
      height: 240,
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
    final bool isFirst = pos == 1;
    final color = isFirst
        ? const Color(0xFFFFD700)
        : (pos == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _abrirEstatisticaAtleta(est),
      child: Column(
        mainAxisSize: MainAxisSize
            .max, // Altera para max para preencher o Expanded do Row
        children: [
          // 1. Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isFirst ? 32 : 26, // Reduzi levemente para ganhar espaço
              backgroundColor: color,
              child: CircleAvatar(
                radius: isFirst ? 29 : 23,
                backgroundColor: AppColors.bgCard,
                backgroundImage: (est.fotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(est.fotoUrl!)
                    : (est.equipeEscudoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(est.equipeEscudoUrl!)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Nome
          Text(
            est.nomeAtleta.split(' ').first.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              fontSize: isFirst ? 13 : 11,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 3. Base do Pódio (O segredo está no Expanded aqui)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$posº',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: isFirst ? 32 : 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_getStatValue(est)} ${_ordemStats.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticaItem(EstatisticaAtleta est, int pos) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _abrirEstatisticaAtleta(est),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Text(
                '${pos + 1}º',
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: Colors.white24,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.bgDeep,
                backgroundImage: (est.fotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(est.fotoUrl!)
                    : (est.equipeEscudoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(est.equipeEscudoUrl!)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      est.nomeAtleta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      est.equipeNome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getStatValue(est).toString(),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirEstatisticaAtleta(EstatisticaAtleta est) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstatisticaAtletaScreen(
          atleta: Atleta(
            id: est.atletaId,
            atleticaId: '',
            nome: est.nomeAtleta,
            fotoUrl: est.fotoUrl,
          ),
          timeNome: est.equipeNome,
          escudoUrl: est.equipeEscudoUrl,
        ),
      ),
    );
  }

  void _abrirDetalhe(Partida p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JogoDetalhesScreen(
          partidaId: p.id,
          modalidadeId: p.modalidadeId,
          timeA: p.equipeA?.nome ?? 'Time A',
          timeB: p.equipeB?.nome ?? 'Time B',
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
    final st = partida.status.toUpperCase();
    final isFinalizada = [
      'finalizada',
      'fechada',
    ].contains(partida.status.trim().toLowerCase());
    final isAoVivo =
        partida.status.trim().toLowerCase() != 'agendada' && !isFinalizada;
    final dtStr = partida.iniciadaEm != null
        ? DateFormat('dd/MM • HH:mm').format(partida.iniciadaEm!.toLocal())
        : '';
    final badgeColor = isAoVivo
        ? Colors.green
        : isFinalizada
        ? Colors.grey
        : AppColors.primary;

    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
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
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
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
              Row(
                children: [
                  Expanded(
                    child: _buildTeamBlock(
                      partida.equipeA?.atleticaEscudoUrl ?? '',
                      partida.equipeA?.nome ?? 'Time A',
                      CrossAxisAlignment.start,
                    ),
                  ),
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
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildTeamBlock(
                      partida.equipeB?.atleticaEscudoUrl ?? '',
                      partida.equipeB?.nome ?? 'Time B',
                      CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
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
          backgroundColor: AppColors.bgDeep,
          backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
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
