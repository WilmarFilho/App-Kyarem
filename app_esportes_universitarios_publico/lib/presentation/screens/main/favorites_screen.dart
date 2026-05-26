import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/partida_feed_item.dart';
import '../../../../models/campeonato.dart';
import '../../../../models/atletica.dart';
import '../../../../services/favorite_service.dart';
import '../../widgets/shared/partida_card_widget.dart';
import 'athletics_tab.dart';
import 'championships_tab.dart';

// ── Tela ───────────────────────────────────────────────────────────────────────

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _favoriteService = FavoriteService();
  
  bool _isLoading = true;
  List<PartidaFeedItem> _partidas = [];
  List<Campeonato> _campeonatos = [];
  List<Atletica> _atleticas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final data = await _favoriteService.getFavorites();
      if (mounted) {
        setState(() {
          _partidas = List<PartidaFeedItem>.from(data['partidas']!);
          _campeonatos = List<Campeonato>.from(data['campeonatos']!);
          _atleticas = List<Atletica>.from(data['atleticas']!);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar favoritos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAtleticasTab(),
                _buildPartidasTab(),
                _buildCampeonatosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cabeçalho ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favoritos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Tudo que você acompanha',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFCC00),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_atleticas.length + _campeonatos.length}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  // ── TabBar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        indicator: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 4,
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(height: 38, text: 'Atléticas'),
          Tab(height: 38, text: 'Partidas'),
          Tab(height: 38, text: 'Campeonatos'),
        ],
      ),
    );
  }

  // ── Tab: Atléticas ─────────────────────────────────────────────────────────

  Widget _buildAtleticasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_atleticas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma atlética favoritada.',
          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _atleticas.length,
      itemBuilder: (context, i) {
        final a = _atleticas[i];
        return AthleticCard(
          athletic: a,
          onTap: () {},
        );
      },
    );
  }

  // ── Tab: Partidas ──────────────────────────────────────────────────────────

  Widget _buildPartidasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_partidas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma partida favoritada.',
          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _partidas.length,
      itemBuilder: (context, i) {
        final p = _partidas[i];
        return PartidaCardWidget(partida: p);
      },
    );
  }

  // ── Tab: Campeonatos ───────────────────────────────────────────────────────

  Widget _buildCampeonatosTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_campeonatos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum campeonato favoritado.',
          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _campeonatos.length,
      itemBuilder: (context, i) {
        final c = _campeonatos[i];
        return ChampionshipCard(
          championship: c,
          onTap: () {},
        );
      },
    );
  }
}


