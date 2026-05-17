import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import 'championship_detail_screen.dart';

class ChampionshipMock {
  final String name;
  final String description;
  final String location;
  final String dateLabel;
  final String imageUrl;

  const ChampionshipMock({
    required this.name,
    required this.description,
    required this.location,
    required this.dateLabel,
    required this.imageUrl,
  });
}

const _championships = [
  ChampionshipMock(
    name: 'Copa Universitária Sudeste',
    description:
        'Competições intensas entre atléticas da região, com confrontos decisivos e torcida pesada.',
    location: 'São Paulo, SP',
    dateLabel: '12 a 18 de Julho',
    imageUrl: 'https://picsum.photos/seed/champ-sudeste/900/500',
  ),
  ChampionshipMock(
    name: 'Liga Paulista Universitária',
    description:
        'Calendário completo de modalidades coletivas com classificações atualizadas ao longo da semana.',
    location: 'Campinas, SP',
    dateLabel: '03 a 09 de Agosto',
    imageUrl: 'https://picsum.photos/seed/champ-paulista/900/500',
  ),
  ChampionshipMock(
    name: 'Open Universitário Nacional',
    description:
        'Encontro nacional com foco em jogos eliminatórios, atletas em destaque e cobertura completa.',
    location: 'Belo Horizonte, MG',
    dateLabel: '20 a 26 de Setembro',
    imageUrl: 'https://picsum.photos/seed/champ-open/900/500',
  ),
];

class ChampionshipsTab extends StatelessWidget {
  const ChampionshipsTab({super.key});

  void _openDetail(BuildContext context, ChampionshipMock championship) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChampionshipDetailScreen(championship: championship),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
        ..._championships.map(
          (championship) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ChampionshipCard(
              championship: championship,
              onTap: () => _openDetail(context, championship),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChampionshipCard extends StatelessWidget {
  const _ChampionshipCard({
    required this.championship,
    required this.onTap,
  });

  final ChampionshipMock championship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
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
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  championship.imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      championship.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      championship.description,
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
                        Text(
                          championship.location,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          championship.dateLabel,
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
