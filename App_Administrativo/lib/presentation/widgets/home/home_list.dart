import 'package:flutter/material.dart';
import '../../screens/admin/partida_form_screen.dart';
import '../../screens/main/arbitro_detalhe_screen.dart';
import '../../screens/admin/campeonato_form_screen.dart';

class HomeListItem extends StatelessWidget {
  final dynamic item; // Pode ser Partida, Arbitro ou Campeonato
  final String type;

  const HomeListItem({super.key, required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    String titulo = '';
    String? subTitulo;
    Widget leading;

    if (type == 'Jogos') {
      titulo = '${item.equipeA?.nome} vs ${item.equipeB?.nome}';
      subTitulo = item.status.isNotEmpty
          ? '${item.status[0].toUpperCase()}${item.status.substring(1).toLowerCase()}'
          : item.status;
      leading = const Icon(Icons.sports_soccer, color: Color(0xFFF85C39));
    } else if (type == 'Árbitros') {
      titulo = item.nome;
      leading = CircleAvatar(
        backgroundImage: item.fotoUrl != null
            ? NetworkImage(item.fotoUrl!)
            : null,
        child: item.fotoUrl == null ? const Icon(Icons.person) : null,
      );
    } else {
      titulo = item.nome;
      leading = const Icon(Icons.emoji_events, color: Colors.amber);
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
          }
        },
      ),
    );
  }
}
