import 'package:flutter/material.dart';
import '../../data/models/evento_model.dart';

class EventoTimelineTile extends StatelessWidget {
  final Evento evento;

  const EventoTimelineTile({super.key, required this.evento});

  Icon _getIconeEvento(String tipo) {
    switch (tipo) {
      case 'GOL': return const Icon(Icons.sports_soccer, color: Colors.greenAccent);
      case 'AMARELO': return const Icon(Icons.style, color: Colors.amberAccent);
      default: return const Icon(Icons.style, color: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _getIconeEvento(evento.tipo),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.atletaNome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(evento.tipo, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Text(
            evento.timestamp.toString().substring(11, 16),
            style: const TextStyle(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}