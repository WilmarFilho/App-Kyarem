import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../models/partida_feed_item.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/main_top_bar.dart';
import '../../widgets/shared/metric_tile.dart';
import '../../widgets/shared/partida_card_widget.dart';
import 'matches_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onProfileTap,
    required this.hasPendingInvite,
  });

  final VoidCallback onProfileTap;
  final bool hasPendingInvite;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PartidaService _partidaService = PartidaService();

  List<PartidaFeedItem> _partidas = const [];
  bool _loading = true;
  String _selectedSport = 'Todos';

  List<String> get _sports {
    final sports = _partidas
        .map((item) => item.esporteNome.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Todos', ...sports];
  }

  List<PartidaFeedItem> get _partidasFiltradas {
    if (_selectedSport == 'Todos') return _partidas;
    return _partidas
        .where(
          (item) =>
              item.esporteNome.trim().toLowerCase() ==
              _selectedSport.trim().toLowerCase(),
        )
        .toList();
  }

  int get _championshipCount =>
      _partidas.map((item) => item.campeonatoId).where((id) => id.isNotEmpty).toSet().length;

  int get _liveCount => _partidas.where((item) => item.isLive).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final partidas = await _partidaService.getPartidasFeed();
      if (!mounted) return;
      setState(() {
        _partidas = partidas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _abrirPartidas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchesScreen(partidas: _partidasFiltradas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partidas = _partidasFiltradas;

    return Column(
      children: [
        MainTopBar(
          onProfileTap: widget.onProfileTap,
          hasPendingInvite: widget.hasPendingInvite,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
                    MetricTile(
                      label: 'Campeonatos',
                      value: '$_championshipCount',
                    ),
                    const SizedBox(width: 12),
                    MetricTile(
                      label: 'Partidas ao vivo',
                      value: '$_liveCount',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Próximas partidas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _abrirPartidas,
                      child: Text(
                        'Ver todas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Filtre pelas modalidades esportivas reais já vinculadas às partidas do ecossistema.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = _sports[i] == _selectedSport;
                      final sport = _sports[i];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSport = sport),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.secondary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.secondary
                                  : const Color(0xFFDDE3EE),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconForSport(sport),
                                size: 15,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sport,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (partidas.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sports_rounded,
                          size: 48,
                          color: Color(0xFFDDE3EE),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma partida encontrada',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...partidas.map((p) => PartidaCardWidget(partida: p)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForSport(String sport) {
    final normalized = sport.trim().toLowerCase();
    if (normalized.contains('volei')) return Icons.sports_volleyball;
    if (normalized.contains('basquete')) return Icons.sports_basketball;
    if (normalized.contains('handebol')) return Icons.sports_handball;
    if (normalized.contains('tenis')) return Icons.sports_tennis;
    if (normalized == 'todos') return Icons.sports_rounded;
    return Icons.sports_soccer;
  }
}
