import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import 'athletic_detail_screen.dart';

class AthleticMock {
  final String name;
  final String description;
  final String campus;
  final String imageUrl;

  const AthleticMock({
    required this.name,
    required this.description,
    required this.campus,
    required this.imageUrl,
  });
}

const _athletics = [
  AthleticMock(
    name: 'AAAFEI',
    description:
        'Atlética com presença forte em quadra e torcida sempre muito ativa nos campeonatos regionais.',
    campus: 'FEI São Bernardo',
    imageUrl: 'https://picsum.photos/seed/atletica-fei/900/500',
  ),
  AthleticMock(
    name: 'AAAUSP',
    description:
        'Delegação tradicional, conhecida por volume de modalidades e organização de torcida.',
    campus: 'USP São Paulo',
    imageUrl: 'https://picsum.photos/seed/atletica-usp/900/500',
  ),
  AthleticMock(
    name: 'AAUNICAMP',
    description:
        'Equipe forte em esportes coletivos, com bom histórico competitivo e engajamento alto.',
    campus: 'UNICAMP Campinas',
    imageUrl: 'https://picsum.photos/seed/atletica-unicamp/900/500',
  ),
];

class AthleticsTab extends StatelessWidget {
  const AthleticsTab({super.key});

  void _openDetail(BuildContext context, AthleticMock athletic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AthleticDetailScreen(athletic: athletic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
        ..._athletics.map(
          (athletic) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AthleticCard(
              athletic: athletic,
              onTap: () => _openDetail(context, athletic),
            ),
          ),
        ),
      ],
    );
  }
}

class _AthleticCard extends StatelessWidget {
  const _AthleticCard({
    required this.athletic,
    required this.onTap,
  });

  final AthleticMock athletic;
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
                  athletic.imageUrl,
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
                      athletic.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      athletic.description,
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
                          Icons.school_outlined,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          athletic.campus,
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
