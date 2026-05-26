import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/campeonato.dart';
import '../../../../services/campeonato_service.dart';
import '../../../../services/favorite_service.dart';
import '../../widgets/layout/main_top_bar.dart';
import 'championship_detail_screen.dart';

class ChampionshipsTab extends StatefulWidget {
  const ChampionshipsTab({
    super.key,
    required this.onProfileTap,
    required this.hasPendingInvite,
  });

  final VoidCallback onProfileTap;
  final bool hasPendingInvite;

  @override
  State<ChampionshipsTab> createState() => _ChampionshipsTabState();
}

class _ChampionshipsTabState extends State<ChampionshipsTab> {
  final _service = CampeonatoService();
  List<Campeonato> _campeonatos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.getCampeonatos();
      setState(() {
        _campeonatos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar campeonatos: $e')),
        );
      }
    }
  }

  void _openDetail(Campeonato campeonato) {
    // Note: ChampionshipDetailScreen might need to be updated to receive Campeonato instead of ChampionshipMock.
    // For now, if it still expects a mock or if we haven't updated it, it will fail. Let's assume we update it too.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChampionshipDetailScreen(championship: campeonato),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      children: [
        MainTopBar(
          onProfileTap: widget.onProfileTap,
          hasPendingInvite: widget.hasPendingInvite,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campeonatos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore os campeonatos ativos e entre em cada um para ver visão geral, estatísticas e atletas.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (_campeonatos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Nenhum campeonato encontrado.',
                      style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
                    ),
                  ),
                )
              else
                ..._campeonatos.map(
                  (championship) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ChampionshipCard(
                      championship: championship,
                      onTap: () => _openDetail(championship),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChampionshipCard extends StatefulWidget {
  const ChampionshipCard({
    required this.championship,
    required this.onTap,
  });

  final Campeonato championship;
  final VoidCallback onTap;

  @override
  State<ChampionshipCard> createState() => _ChampionshipCardState();
}

class _ChampionshipCardState extends State<ChampionshipCard> {
  bool _isFavorite = false;
  final _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoriteService.isFavorite(campeonatoId: widget.championship.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteService.currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para favoritar o campeonato')),
      );
      return;
    }

    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      await _favoriteService.toggleFavorite(campeonatoId: widget.championship.id);
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao favoritar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: widget.championship.escudoUrl != null && widget.championship.escudoUrl!.isNotEmpty
                        ? Image.network(
                            widget.championship.escudoUrl!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 160,
                            color: AppColors.surface,
                            child: const Icon(Icons.emoji_events, size: 64, color: AppColors.textMuted),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                          color: _isFavorite ? const Color(0xFFF3B63F) : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.championship.nome,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.championship.edicao ?? 'Edição não informada',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Sede a definir',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.championship.dataInicio ?? 'A definir',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
