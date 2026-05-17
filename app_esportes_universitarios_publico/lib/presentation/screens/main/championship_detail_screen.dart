import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import 'championships_tab.dart';

class ChampionshipDetailScreen extends StatelessWidget {
  const ChampionshipDetailScreen({
    super.key,
    required this.championship,
  });

  final ChampionshipMock championship;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(championship.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Geral'),
              Tab(text: 'Estatísticas'),
              Tab(text: 'Atletas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  championship.imageUrl,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DetailList(
                    sections: [
                      'Local: ${championship.location}',
                      'Período: ${championship.dateLabel}',
                      championship.description,
                    ],
                  ),
                  const _DetailList(
                    sections: [
                      '18 modalidades mapeadas',
                      '64 partidas previstas',
                      'Média de 1.240 torcedores por arena',
                    ],
                  ),
                  const _DetailList(
                    sections: [
                      'Atletas destaque da rodada',
                      'Ranking de pontuação e assistências',
                      'Lista pública de inscritos por delegação',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF5)),
        ),
        child: Text(
          sections[index],
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: sections.length,
    );
  }
}
