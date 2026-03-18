import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';

class SummaryEventItem {
  final String id;
  final EventoPartida evento;
  final String? equipeId;
  final String? atletaId;
  final String? atletaSaiId;
  final bool isSubstitution;
  final String tipoEventoId;
  final String tempoCronometro;

  SummaryEventItem({
    required this.id,
    required this.evento,
    required this.tipoEventoId,
    required this.tempoCronometro,
    this.equipeId,
    this.atletaId,
    this.atletaSaiId,
    this.isSubstitution = false,
  });
}

/// Widget de lista de eventos para o resumo da partida,
/// com suporte a edição/remoção quando habilitado.
class SummaryEventList extends StatelessWidget {
  final List<SummaryEventItem> eventos;
  final bool podeEditar;
  final void Function(SummaryEventItem) onEdit;
  final void Function(SummaryEventItem) onDelete;

  const SummaryEventList({
    super.key,
    required this.eventos,
    required this.podeEditar,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return const Center(child: Text("Nenhum evento registrado."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final item = eventos[index];
        final ev = item.evento;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: _getIconForEvent(ev.tipo),
            title: Text(
              ev.descricao,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text("Tempo: ${ev.horario}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ev.corTime != null)
                  CircleAvatar(radius: 4, backgroundColor: ev.corTime),
                if (podeEditar) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Editar evento',
                    onPressed: () => onEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Excluir evento',
                    onPressed: () => onDelete(item),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getIconForEvent(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('gol')) {
      return const Icon(Icons.sports_soccer, color: Colors.green);
    }
    if (t.contains('amarelo')) {
      return const Icon(Icons.style, color: Colors.amber);
    }
    if (t.contains('vermelho')) {
      return const Icon(Icons.style, color: Colors.red);
    }
    if (t.contains('substit')) {
      return const Icon(Icons.swap_horiz, color: Colors.blue);
    }
    return const Icon(Icons.info_outline, color: Colors.grey);
  }
}
