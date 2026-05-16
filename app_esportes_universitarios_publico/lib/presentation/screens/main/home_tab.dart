import 'package:flutter/material.dart';

import '../../widgets/shared/metric_tile.dart';
import '../../widgets/shared/page_header.dart';
import '../../widgets/shared/section_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        PageHeader(
          title: 'Dashboard geral',
          subtitle:
              'Visao consolidada do ecossistema esportivo: campeonatos, atleticas, atletas e engajamento do publico.',
        ),
        SizedBox(height: 20),
        Row(
          children: [
            MetricTile(label: 'Campeonatos ativos', value: '12'),
            SizedBox(width: 12),
            MetricTile(label: 'Atleticas mapeadas', value: '48'),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            MetricTile(label: 'Atletas destacados', value: '160'),
            SizedBox(width: 12),
            MetricTile(label: 'Torcedores seguindo', value: '2.4k'),
          ],
        ),
        SizedBox(height: 20),
        SectionCard(
          title: 'Estatisticas globais',
          description:
              'Aqui vamos ligar os read models do schema public para mostrar rankings, lideres por modalidade, comparativos e tendencia dos campeonatos.',
          icon: Icons.query_stats_rounded,
          badge: 'Prioridade alta',
        ),
        SizedBox(height: 12),
        SectionCard(
          title: 'Minha gestao de atletica',
          description:
              'Quando o usuario receber papel de PRESIDENT ou DIRECTOR no app admin, esta area passa a liberar criacao de times, elenco e convites de atletas.',
          icon: Icons.admin_panel_settings_rounded,
        ),
      ],
    );
  }
}
