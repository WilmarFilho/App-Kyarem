import 'package:flutter/material.dart';

import '../../widgets/shared/page_header.dart';
import '../../widgets/shared/section_card.dart';

class AthleticsTab extends StatelessWidget {
  const AthleticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        PageHeader(
          title: 'Atléticas',
          subtitle:
              'Espaco para explorar atleticas, seguir como torcedor, ver esportes praticados, equipes e historico em campeonatos.',
        ),
        SizedBox(height: 20),
        SectionCard(
          title: 'Virar torcedor',
          description:
              'Fluxo planejado para o usuario seguir atleticas e receber relevancia personalizada no dashboard e nas notificacoes.',
          icon: Icons.favorite_rounded,
          badge: 'Em desenho',
        ),
        SizedBox(height: 12),
        SectionCard(
          title: 'Equipes e modalidades',
          description:
              'Cada atletica vai expor seus times, papeis contextuais e presenca por campeonato, com leitura publica desacoplada do operacional.',
          icon: Icons.shield_rounded,
        ),
      ],
    );
  }
}
