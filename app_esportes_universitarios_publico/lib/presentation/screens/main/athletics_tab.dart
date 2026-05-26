import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../services/atletica_service.dart';
import '../../../../services/favorite_service.dart';
import '../../widgets/layout/main_top_bar.dart';
import 'athletic_detail_screen.dart';
import 'atletica_management_screen.dart';

class AthleticsTab extends StatefulWidget {
  const AthleticsTab({
    super.key,
    required this.onProfileTap,
    required this.hasPendingInvite,
  });

  final VoidCallback onProfileTap;
  final bool hasPendingInvite;

  @override
  State<AthleticsTab> createState() => _AthleticsTabState();
}

class _AthleticsTabState extends State<AthleticsTab> {
  final AtleticaService _atleticaService = AtleticaService();
  late Future<List<Atletica>> _atleticasFuture;
  late Future<List<MinhaAtletica>> _minhasAtleticasFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _atleticasFuture = _atleticaService.getAtleticas();
      _minhasAtleticasFuture = _atleticaService.getMinhasAtleticas().catchError(
        (_) => <MinhaAtletica>[],
      );
    });
  }


  void _openManagement(BuildContext context, MinhaAtletica minhaAtletica) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AtleticaManagementScreen(minhaAtletica: minhaAtletica),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([_atleticasFuture, _minhasAtleticasFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar atléticas.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _fetchData,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final atleticas = snapshot.data![0] as List<Atletica>;
        final minhasAtleticas = snapshot.data![1] as List<MinhaAtletica>;
        final minhasAtleticasPresidencia = minhasAtleticas
            .where((m) => m.papelCodigo == 'PRESIDENT' || m.papelCodigo == 'DIRECTOR')
            .toList();

        final managedIds = minhasAtleticasPresidencia.map((m) => m.atleticaId).toSet();
        atleticas.sort((a, b) {
          final aManaged = managedIds.contains(a.id);
          final bManaged = managedIds.contains(b.id);
          if (aManaged && !bManaged) return -1;
          if (!aManaged && bManaged) return 1;
          return a.nome.compareTo(b.nome);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          children: [
            MainTopBar(
              onProfileTap: widget.onProfileTap,
              hasPendingInvite: widget.hasPendingInvite,
              trailing: minhasAtleticasPresidencia.isNotEmpty
                  ? MainTopBarIconButton(
                      icon: Icons.settings,
                      onTap: () {
                        _openManagement(
                          context,
                          minhasAtleticasPresidencia.first,
                        );
                      },
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atléticas',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encontre atléticas, entre em cada perfil e navegue entre visão geral, estatísticas e atletas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (atleticas.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Nenhuma atlética encontrada.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...atleticas.map((atletica) {
                      final isManaged = managedIds.contains(atletica.id);
                      final papel = isManaged 
                          ? minhasAtleticasPresidencia.firstWhere((m) => m.atleticaId == atletica.id).papelCodigo 
                          : null;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AthleticCard(
                          athletic: atletica,
                          isManaged: isManaged,
                          papel: papel,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AthleticDetailScreen(athletic: atletica),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class AthleticCard extends StatefulWidget {
  const AthleticCard({
    required this.athletic, 
    required this.onTap,
    this.isManaged = false,
    this.papel,
  });

  final Atletica athletic;
  final VoidCallback onTap;
  final bool isManaged;
  final String? papel;

  @override
  State<AthleticCard> createState() => _AthleticCardState();
}

class _AthleticCardState extends State<AthleticCard> {
  bool _isFavorite = false;
  final _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoriteService.isFavorite(atleticaId: widget.athletic.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteService.currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para favoritar a atlética')),
      );
      return;
    }

    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      await _favoriteService.toggleFavorite(atleticaId: widget.athletic.id);
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: widget.isManaged 
                ? Border.all(color: AppColors.secondary, width: 2) 
                : Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Stack(
                  children: [
                    widget.athletic.escudoUrl != null && widget.athletic.escudoUrl!.isNotEmpty
                        ? Image.network(
                            widget.athletic.escudoUrl!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: double.infinity,
                              height: 160,
                              color: AppColors.surface,
                              child: const Icon(
                                Icons.shield,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 160,
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.shield,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                          ),
                    if (widget.isManaged && widget.papel != null)
                      Positioned(
                        top: 12,
                        left: 12, // Move left so favorite can be on the right
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.papel == 'PRESIDENT' ? 'PRESIDENTE' : 'DIRETORIA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
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
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.athletic.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.athletic.sigla ?? '',
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
                          Icons.verified,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.athletic.status,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
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
