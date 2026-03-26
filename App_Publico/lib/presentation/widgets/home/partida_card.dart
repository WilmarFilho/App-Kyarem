import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';

class PartidaCard extends StatelessWidget {
  final Partida partida; // Agora é obrigatório para exibir os dados reais
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback? onTap;

  const PartidaCard({
    super.key,
    required this.partida,
    required this.fadeAnimation,
    required this.slideAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 290,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge de Status (AO VIVO ou AGENDADO)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    partida.status == '1° tempo' ||
                            partida.status == 'intervalo' ||
                            partida.status == '2° tempo' ||
                            partida.status == 'prorrogação'
                        ? '● AO VIVO'
                        : 'DESTAQUE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Área dos Times e Placar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time A
                    _buildTeamInfo(
                      partida.equipeA?.nome ?? "Time A",
                      partida.equipeA?.atletica?.escudoUrl,
                    ),

                    // Placar Central
                    Column(
                      children: [
                        Text(
                          "${partida.placarA} - ${partida.placarB}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily:
                                'Bebas Neue', // Usando a fonte do seu cabeçalho
                          ),
                        ),
                        const Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Time B
                    _buildTeamInfo(
                      partida.equipeB?.nome ?? "Time B",
                      partida.equipeB?.atletica?.escudoUrl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para montar a coluna de cada time dentro do card
  Widget _buildTeamInfo(String nome, String? logoUrl) {
    return SizedBox(
      width: 85,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
            child: logoUrl == null
                ? Text(
                    nome[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
