import 'package:flutter/material.dart';

import '../../widgets/shared/page_header.dart';
import '../../widgets/shared/section_card.dart';

class ChampionshipsTab extends StatelessWidget {
  const ChampionshipsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        PageHeader(
          title: 'Campeonatos',
          subtitle:
              'Tela dedicada para listar campeonatos especificos, modalidades inscritas, atleticas participantes e detalhes por competicao.',
        ),
        SizedBox(height: 20),
        SectionCard(
          title: 'Filtro por campeonato',
          description:
              'Vamos conectar com os read models publicos para abrir cada torneio, seus grupos, rodadas e confrontos.',
          icon: Icons.filter_alt_rounded,
        ),
        SizedBox(height: 12),
        SectionCard(
          title: 'Atletas por campeonato',
          description:
              'Detalhamento de atletas inscritos, estatisticas dentro da competicao e comparacao entre edicoes.',
          icon: Icons.sports_handball_rounded,
        ),
      ],
    );
  }
}
