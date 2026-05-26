import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/campeonato_atletica_publica_model.dart';
import '../../../services/atletica_public_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../atletica/atletica_detalhe_screen.dart';
import 'main_screen.dart';

class AtleticasScreen extends StatefulWidget {
  final bool isMainScreenChild;
  final AtleticaPublicService? atleticaService;

  const AtleticasScreen({
    super.key,
    this.isMainScreenChild = false,
    this.atleticaService,
  });

  @override
  State<AtleticasScreen> createState() => _AtleticasScreenState();
}

class _AtleticasScreenState extends State<AtleticasScreen> {
  late final AtleticaPublicService _service =
      widget.atleticaService ?? AtleticaPublicService();
  final _supabase = Supabase.instance.client;
  late Future<List<CampeonatoAtleticaPublica>> _future;

  void _onBottomTabSelected(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = _service.getAthletics();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.getAthletics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GradientBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 22, top: 32),
                    child: Text(
                      'ATLÉTICAS',
                      style: GoogleFonts.oswald(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  background: Container(
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
                  ),
                ),
              ),
              SliverFillRemaining(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: AppColors.primary,
                  child: FutureBuilder<List<CampeonatoAtleticaPublica>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final atleticas = snapshot.data ?? [];
                      if (atleticas.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.only(
                            top: 120,
                            bottom: widget.isMainScreenChild ? 100 : 120,
                          ),
                          children: const [
                            Center(
                              child: Text(
                                'Nenhuma atlética inscrita encontrada.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        );
                      }

                      final campeonatoAtleticaIds = atleticas
                          .map((atletica) => atletica.campeonatoAtleticaId)
                          .where((id) => id.trim().isNotEmpty)
                          .toList();

                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: campeonatoAtleticaIds.isEmpty
                            ? null
                            : _supabase
                                  .from('atletica_torcida_votos')
                                  .stream(primaryKey: ['id'])
                                  .inFilter(
                                    'campeonato_atletica_id',
                                    campeonatoAtleticaIds,
                                  ),
                        builder: (context, votesSnapshot) {
                          final votes =
                              votesSnapshot.data ??
                              const <Map<String, dynamic>>[];
                          final ranking = _buildRanking(atleticas, votes);
                          final totalVotes = votes.length;

                          return ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              18,
                              20,
                              18,
                              widget.isMainScreenChild ? 100 : 120,
                            ),
                            itemCount: ranking.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildTorcidaSpotlight(
                                  ranking: ranking,
                                  totalVotes: totalVotes,
                                );
                              }
                              return _buildAtleticaCard(
                                ranking[index - 1],
                                totalVotes,
                                ranking.isEmpty ? 0 : ranking.first.votes,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (!widget.isMainScreenChild)
            BottomNavigationWidget(
              currentIndex: 2,
              onTabSelected: _onBottomTabSelected,
            ),
        ],
      ),
    );
  }

  List<_AtleticaTorcidaRank> _buildRanking(
    List<CampeonatoAtleticaPublica> atleticas,
    List<Map<String, dynamic>> votes,
  ) {
    final counts = <String, int>{};
    for (final vote in votes) {
      final campeonatoAtleticaId = vote['campeonato_atletica_id']?.toString();
      if (campeonatoAtleticaId == null || campeonatoAtleticaId.isEmpty)
        continue;
      counts.update(
        campeonatoAtleticaId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final ranking =
        atleticas
            .map(
              (atletica) => _AtleticaTorcidaRank(
                atletica: atletica,
                votes: counts[atletica.campeonatoAtleticaId] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byVotes = b.votes.compareTo(a.votes);
            if (byVotes != 0) return byVotes;
            return a.atletica.nome.toLowerCase().compareTo(
              b.atletica.nome.toLowerCase(),
            );
          });

    for (var i = 0; i < ranking.length; i++) {
      ranking[i] = ranking[i].copyWith(position: i + 1);
    }
    return ranking;
  }

  Widget _buildTorcidaSpotlight({
    required List<_AtleticaTorcidaRank> ranking,
    required int totalVotes,
  }) {
    final leader = ranking.isEmpty ? null : ranking.first;
    final runnerUp = ranking.length > 1 ? ranking[1] : null;
    final leaderGap = leader == null
        ? 0
        : leader.votes - (runnerUp?.votes ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.9),
            AppColors.primary.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TORCIDA AO VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$totalVotes voto(s)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            leader == null
                ? 'A disputa de torcida ainda vai começar.'
                : leader.votes == 0
                ? 'Nenhuma torcida marcou presença ainda.'
                : '${leader.atletica.nome} está puxando a arquibancada.',
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            leader == null || leader.votes == 0
                ? 'Seja o primeiro voto e coloque sua atlética na frente.'
                : runnerUp == null
                ? 'Por enquanto ela reina sozinha no torcidômetro.'
                : leaderGap == 0
                ? 'A liderança está empatada. Qual torcida assume a ponta?'
                : 'Vantagem de $leaderGap voto(s).',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtleticaCard(
    _AtleticaTorcidaRank rank,
    int totalVotes,
    int leaderVotes,
  ) {
    final atletica = rank.atletica;
    final hasLogo =
        atletica.escudoUrl != null && atletica.escudoUrl!.isNotEmpty;
    final normalizedLeaderVotes = leaderVotes > 0 ? leaderVotes : 1;
    final progress = totalVotes == 0 ? 0.0 : rank.votes / normalizedLeaderVotes;
    final isLeader = rank.position == 1 && rank.votes > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AtleticaDetalheScreen(
                  atletica: atletica,
                  atleticaService: _service,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: hasLogo
                          ? NetworkImage(atletica.escudoUrl!)
                          : null,
                      child: !hasLogo
                          ? Text(
                              (atletica.sigla ?? atletica.nome)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      left: -6,
                      top: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isLeader ? AppColors.orange : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLeader ? Colors.white : Colors.white24,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${rank.position}',
                          style: TextStyle(
                            color: isLeader ? Colors.white : AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atletica.nome.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if ((atletica.sigla ?? '').isNotEmpty)
                        Text(
                          atletica.sigla!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isLeader
                                  ? AppColors.orange.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isLeader
                                    ? AppColors.orange.withValues(alpha: 0.5)
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(
                              isLeader
                                  ? 'Líder da torcida'
                                  : 'Torcida #${rank.position}',
                              style: TextStyle(
                                color: isLeader
                                    ? AppColors.orange
                                    : Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rank.votes} voto(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLeader ? AppColors.orange : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalVotes == 0
                            ? 'Sem votos ainda. Seja a torcida que estreia o placar.'
                            : isLeader
                            ? 'Na frente da disputa neste momento.'
                            : '${(progress * 100).round()}% do ritmo da liderança.',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtleticaTorcidaRank {
  final CampeonatoAtleticaPublica atletica;
  final int votes;
  final int position;

  const _AtleticaTorcidaRank({
    required this.atletica,
    required this.votes,
    this.position = 0,
  });

  _AtleticaTorcidaRank copyWith({
    CampeonatoAtleticaPublica? atletica,
    int? votes,
    int? position,
  }) {
    return _AtleticaTorcidaRank(
      atletica: atletica ?? this.atletica,
      votes: votes ?? this.votes,
      position: position ?? this.position,
    );
  }
}
