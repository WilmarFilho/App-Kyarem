import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import 'athletics_tab.dart';

class AthleticDetailScreen extends StatelessWidget {
  const AthleticDetailScreen({
    super.key,
    required this.athletic,
  });

  final AthleticMock athletic;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(athletic.name),
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
                  athletic.imageUrl,
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
                      'Campus: ${athletic.campus}',
                      athletic.description,
                      'Histórico recente em campeonatos universitários e presença de torcida.',
                    ],
                  ),
                  const _DetailList(
                    sections: [
                      '12 modalidades ativas',
                      '78% de aproveitamento nas últimas rodadas',
                      '4 troféus conquistados no último ciclo',
                    ],
                  ),
                  const _DetailList(
                    sections: [
                      'Elenco principal por modalidade',
                      'Atletas em destaque da temporada',
                      'Perfis públicos e números individuais',
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
