import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../widgets/shared/partida_card_widget.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, required this.partidas});

  final List<PartidaMock> partidas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Partidas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Todas as partidas em destaque, com foco nas próximas disputas e jogos ao vivo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...partidas.map((partida) => PartidaCardWidget(partida: partida)),
        ],
      ),
    );
  }
}
