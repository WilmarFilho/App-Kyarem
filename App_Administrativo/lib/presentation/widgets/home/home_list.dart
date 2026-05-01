import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import '../../screens/admin/atletica_detalhe_screen.dart';
import '../../screens/admin/partida_form_screen.dart';
import '../../screens/main/arbitro_detalhe_screen.dart';
import '../../screens/admin/campeonato_form_screen.dart';
import '../../screens/admin/modalidade_detalhe_screen.dart';

class HomeListItem extends StatelessWidget {
  final dynamic item;
  final String type;

  const HomeListItem({super.key, required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    String titulo = '';
    String? subTitulo;
    Widget leading;

    if (type == 'Jogos' && (item.runtimeType.toString() == 'Partida')) {
      titulo = '${item.equipeA?.nome} vs ${item.equipeB?.nome}';
      subTitulo = item.status.isNotEmpty
          ? (item.status.toString().toLowerCase() == 'pênaltis'
                ? 'Pênaltis'
                : '${item.status[0].toUpperCase()}${item.status.substring(1).toLowerCase()}')
          : item.status;
      leading = const Icon(Icons.sports_soccer, color: Color(0xFFF85C39));
    } else if (type == 'Árbitros' &&
        (item.runtimeType.toString() == 'Arbitro' ||
            (item.runtimeType.toString() != 'Partida' &&
                item.runtimeType.toString() != 'Campeonato'))) {
      titulo = item.nome;
      leading = CircleAvatar(
        backgroundImage: item.fotoUrl != null
            ? NetworkImage(item.fotoUrl!)
            : null,
        child: item.fotoUrl == null ? const Icon(Icons.person) : null,
      );
    } else if (type == 'Campeonatos' &&
        (item.runtimeType.toString() == 'Campeonato' ||
            (item.runtimeType.toString() != 'Partida' &&
                item.runtimeType.toString() != 'Arbitro'))) {
      titulo = item.nome;
      leading = const Icon(Icons.emoji_events, color: Colors.amber);
    } else if (type == 'Atléticas') {
      titulo = item.nome;
      subTitulo = item.sigla?.toString();
      leading = const Icon(Icons.shield, color: Color(0xFFF85C39));
    } else if (type == 'Modalidades' && item is ModalidadeCatalogo) {
      titulo = item.nome;
      subTitulo = item.esporteNome;
      leading = const Icon(Icons.sports, color: Color(0xFFF85C39));
    } else {
      titulo = 'Carregando...';
      leading = const Icon(Icons.sync, color: Colors.grey);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: leading,
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subTitulo != null ? Text(subTitulo) : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          if (type == 'Jogos') {
            final String statusStr = item.status?.toLowerCase() ?? '';
            final bool podeEditar = statusStr == 'agendada';

            if (podeEditar) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartidaFormScreen(partida: item),
                ),
              );
            } else {
              String motivo = 'Partida em andamento não pode ser editada.';
              if (statusStr == 'finalizada' || statusStr == 'fechada') {
                motivo = 'Partida encerrada não pode ser editada.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(motivo)),
                    ],
                  ),
                  backgroundColor: Colors.grey.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else if (type == 'Árbitros') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ArbitroDetalheScreen(arbitro: item, canEdit: true),
              ),
            );
          } else if (type == 'Campeonatos') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CampeonatoFormScreen(campeonato: item),
              ),
            );
          } else if (type == 'Atléticas') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AtleticaDetalheScreen(atletica: item),
              ),
            );
          } else if (type == 'Modalidades' && item is ModalidadeCatalogo) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ModalidadeDetalheScreen(modalidade: item),
              ),
            );
          }
        },
      ),
    );
  }
}
