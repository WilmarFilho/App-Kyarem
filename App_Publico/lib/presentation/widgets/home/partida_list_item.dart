import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';

class PartidaListItem extends StatelessWidget {
  final Partida partida;
  final VoidCallback? onTap;

  const PartidaListItem({super.key, required this.partida, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String dataFormatada = partida.iniciadaEm != null
        ? DateFormat('dd MMM', 'pt_BR').format(partida.iniciadaEm!)
        : '--/--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Coluna da Data/Hora
            Column(
              children: [
                Text(
                  dataFormatada.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      partida.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    partida.status == 'finalizada' ? 'FIM' : 'AGEND',
                    style: TextStyle(
                      color: _getStatusColor(partida.status),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Times e Placar
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(
                    partida.equipeA?.nome ?? 'Time A',
                    partida.equipeA?.atleticaEscudoUrl,
                    partida.placarA,
                    venceu: partida.placarA > partida.placarB,
                  ),
                  const SizedBox(height: 6),
                  _buildTeamRow(
                    partida.equipeB?.nome ?? 'Time B',
                    partida.equipeB?.atleticaEscudoUrl,
                    partida.placarB,
                    venceu: partida.placarB > partida.placarA,
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String nome,
    String? logoUrl,
    int placar, {
    bool venceu = false,
  }) {
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF2A0808),
          backgroundImage: hasLogo ? NetworkImage(logoUrl) : null,
          child: !hasLogo
              ? Text(
                  nome[0],
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                )
              : null,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Text(
            nome,
            style: TextStyle(
              fontSize: 14,
              fontWeight: venceu ? FontWeight.bold : FontWeight.w500,
              color: venceu ? Colors.white : Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Text(
          placar.toString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: venceu ? AppColors.orange : Colors.white54,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'encerrada':
      case 'finalizada':
        return Colors.grey;
      case 'em_andamento':
        return AppColors.primary;
      default:
        return AppColors.amber;
    }
  }
}
