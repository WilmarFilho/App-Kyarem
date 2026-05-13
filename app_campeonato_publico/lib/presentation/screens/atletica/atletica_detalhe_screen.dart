import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

import '../../../models/campeonato_atletica_publica_model.dart';
import '../../../models/campeonato_time_publico_model.dart';
import '../../../services/atletica_public_service.dart';
import '../../widgets/layout/gradient_background.dart';

class AtleticaDetalheScreen extends StatefulWidget {
  final CampeonatoAtleticaPublica atletica;
  final AtleticaPublicService? atleticaService;

  const AtleticaDetalheScreen({
    super.key,
    required this.atletica,
    this.atleticaService,
  });

  @override
  State<AtleticaDetalheScreen> createState() => _AtleticaDetalheScreenState();
}

class _AtleticaDetalheScreenState extends State<AtleticaDetalheScreen> {
  late final AtleticaPublicService _service =
      widget.atleticaService ?? AtleticaPublicService();
  late Future<_AtleticaDetalheData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AtleticaDetalheData> _load() async {
    final results = await Future.wait([
      _service.getStatsForAthletics(widget.atletica.atleticaId),
      _service.getTeamsForAthletics(widget.atletica.campeonatoAtleticaId),
    ]);

    return _AtleticaDetalheData(
      stats: results[0] as AtleticaStatsResumo,
      teams: results[1] as List<CampeonatoTimePublico>,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GradientBackground(),
          RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.primary,
            child: FutureBuilder<_AtleticaDetalheData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'Não foi possível carregar os dados da atlética.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(data.stats),
                            const SizedBox(height: 28),
                            _buildSectionTitle('TIMES INSCRITOS'),
                            const SizedBox(height: 12),
                            if (data.teams.isEmpty)
                              _buildEmptyState()
                            else
                              ...data.teams.map(_buildTeamCard),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasLogo =
        widget.atletica.escudoUrl != null && widget.atletica.escudoUrl!.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        24,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: hasLogo
                    ? NetworkImage(widget.atletica.escudoUrl!)
                    : null,
                child: !hasLogo
                    ? Text(
                        (widget.atletica.sigla ?? widget.atletica.nome)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.atletica.nome.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    if ((widget.atletica.sigla ?? '').isNotEmpty)
                      Text(
                        widget.atletica.sigla!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AtleticaStatsResumo stats) {
    final items = <Map<String, String>>[
      {'label': 'Jogos', 'value': stats.jogos.toString()},
      {'label': 'Vitórias', 'value': stats.vitorias.toString()},
      {'label': 'Empates', 'value': stats.empates.toString()},
      {'label': 'Derrotas', 'value': stats.derrotas.toString()},
      {'label': 'Gols Pró', 'value': stats.golsPro.toString()},
      {'label': 'Saldo', 'value': stats.saldo.toString()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final label = item['label'] ?? '';
        final value = item['value'] ?? '0';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.oswald(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTeamCard(CampeonatoTimePublico team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.nomeEquipe,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.modalidadeNome ?? 'Modalidade',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              team.status.toUpperCase(),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        'Nenhum time inscrito foi encontrado para esta atlética.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}

class _AtleticaDetalheData {
  final AtleticaStatsResumo stats;
  final List<CampeonatoTimePublico> teams;

  const _AtleticaDetalheData({required this.stats, required this.teams});
}
