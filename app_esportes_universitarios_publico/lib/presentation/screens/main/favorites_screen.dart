import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';

// ── Modelos mock ───────────────────────────────────────────────────────────────

class _MockAtletica {
  final String nome;
  final String universidade;
  final String esporte;
  final String iniciais;
  final Color cor;

  const _MockAtletica({
    required this.nome,
    required this.universidade,
    required this.esporte,
    required this.iniciais,
    required this.cor,
  });
}

class _MockPartida {
  final String timeA;
  final String timeB;
  final String esporte;
  final String campeonato;
  final String status;
  final String data;

  const _MockPartida({
    required this.timeA,
    required this.timeB,
    required this.esporte,
    required this.campeonato,
    required this.status,
    required this.data,
  });
}

class _MockCampeonato {
  final String nome;
  final String modalidade;
  final String periodo;
  final String status;
  final int times;

  const _MockCampeonato({
    required this.nome,
    required this.modalidade,
    required this.periodo,
    required this.status,
    required this.times,
  });
}

// ── Dados mockados ─────────────────────────────────────────────────────────────

const _atleticas = [
  _MockAtletica(
    nome: 'AA Politécnica',
    universidade: 'Poli USP',
    esporte: 'Futebol • Basquete',
    iniciais: 'AP',
    cor: Color(0xFF1667FF),
  ),
  _MockAtletica(
    nome: 'Cefet Warriors',
    universidade: 'CEFET-MG',
    esporte: 'Vôlei • Handebol',
    iniciais: 'CW',
    cor: Color(0xFF0A2342),
  ),
  _MockAtletica(
    nome: 'Unicamp Athletics',
    universidade: 'Unicamp',
    esporte: 'Natação • Atletismo',
    iniciais: 'UA',
    cor: Color(0xFF1F9254),
  ),
];

const _partidas = [
  _MockPartida(
    timeA: 'AA Politécnica',
    timeB: 'Cefet Warriors',
    esporte: 'Futebol',
    campeonato: 'Copa Universitária 2025',
    status: 'AO VIVO',
    data: 'Hoje, 19:00',
  ),
  _MockPartida(
    timeA: 'Unicamp Athletics',
    timeB: 'AA Politécnica',
    esporte: 'Basquete',
    campeonato: 'Liga Paulista',
    status: 'AGENDADA',
    data: 'Sáb, 26 mai · 15:30',
  ),
  _MockPartida(
    timeA: 'Cefet Warriors',
    timeB: 'Unicamp Athletics',
    esporte: 'Vôlei',
    campeonato: 'Torneio Regional',
    status: 'ENCERRADA',
    data: 'Sex, 24 mai · 18:00',
  ),
];

const _campeonatos = [
  _MockCampeonato(
    nome: 'Copa Universitária 2025',
    modalidade: 'Futebol',
    periodo: 'Mai – Jul 2025',
    status: 'Em andamento',
    times: 16,
  ),
  _MockCampeonato(
    nome: 'Liga Paulista Universitária',
    modalidade: 'Basquete',
    periodo: 'Jun – Ago 2025',
    status: 'Inscrições abertas',
    times: 8,
  ),
  _MockCampeonato(
    nome: 'Torneio Regional de Vôlei',
    modalidade: 'Vôlei',
    periodo: 'Jul 2025',
    status: 'Em breve',
    times: 12,
  ),
];

// ── Tela ───────────────────────────────────────────────────────────────────────

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _atleticas.length,
      itemBuilder: (context, i) {
        final a = _atleticas[i];
        return _AtleticaCard(atletica: a);
      },
    );
  }

  // ── Tab: Partidas ──────────────────────────────────────────────────────────

  Widget _buildPartidasTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _partidas.length,
      itemBuilder: (context, i) {
        final p = _partidas[i];
        return _PartidaFavCard(partida: p);
      },
    );
  }

  // ── Tab: Campeonatos ───────────────────────────────────────────────────────

  Widget _buildCampeonatosTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _campeonatos.length,
      itemBuilder: (context, i) {
        final c = _campeonatos[i];
        return _CampeonatoFavCard(campeonato: c);
      },
    );
  }
}

// ── Cards ──────────────────────────────────────────────────────────────────────

class _AtleticaCard extends StatelessWidget {
  const _AtleticaCard({required this.atletica});
  final _MockAtletica atletica;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar com iniciais
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: atletica.cor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      atletica.iniciais,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atletica.nome,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        atletica.universidade,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _SportPill(label: atletica.esporte),
                    ],
                  ),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFCC00),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartidaFavCard extends StatelessWidget {
  const _PartidaFavCard({required this.partida});
  final _MockPartida partida;

  @override
  Widget build(BuildContext context) {
    final isLive = partida.status == 'AO VIVO';
    final isEnd = partida.status == 'ENCERRADA';

    Color statusColor = AppColors.secondary;
    if (isLive) statusColor = const Color(0xFFE83B3B);
    if (isEnd) statusColor = AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            partida.status,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      partida.esporte,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      partida.data,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        partida.timeA,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'vs',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        partida.timeB,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  partida.campeonato,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampeonatoFavCard extends StatelessWidget {
  const _CampeonatoFavCard({required this.campeonato});
  final _MockCampeonato campeonato;

  @override
  Widget build(BuildContext context) {
    final bool isActive = campeonato.status == 'Em andamento';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [
                              AppColors.secondary,
                              AppColors.secondary.withValues(alpha: 0.6),
                            ]
                          : [const Color(0xFF99AABB), const Color(0xFFBBCCDD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campeonato.nome,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            campeonato.modalidade,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            campeonato.periodo,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.textMuted.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              campeonato.status,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${campeonato.times} times',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFCC00),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SportPill extends StatelessWidget {
  const _SportPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
