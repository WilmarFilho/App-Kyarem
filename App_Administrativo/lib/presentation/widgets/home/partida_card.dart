import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';

class PartidaCard extends StatelessWidget {
  final Partida partida;
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
            width: 280,
            margin: const EdgeInsets.only(
              right: 16,
              bottom: 18,
            ), // Pequena margem para sombra não cortar
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ), // Padding vertical reduzido
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3A68F), Color(0xFFF85C39)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF85C39).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Ocupa apenas o espaço necessário
              children: [
                // Badge de Status (AO VIVO ou AGENDADO)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    partida.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9, // Reduzido ligeiramente
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(), // Distribui o espaço dinamicamente
                // Área dos Times e Placar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTeamInfo(
                      partida.equipeA?.nome ?? "Time A",
                      partida.equipeA?.atleticaEscudoUrl ??
                          partida.equipeA?.atletica?.escudoUrl,
                    ),

                    // Placar Central
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${partida.placarA} - ${partida.placarB}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28, // Reduzido de 32 para evitar overflow
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Bebas Neue',
                          ),
                        ),
                        const Text(
                          "VS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    

                    _buildTeamInfo(
                      partida.equipeB?.nome ?? "Time B",
                      partida.equipeB?.atleticaEscudoUrl ??
                          partida.equipeB?.atletica?.escudoUrl,
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String nome, String? logoUrl) {
    final sanitizedUrl =
        (logoUrl != null && logoUrl.trim().isNotEmpty) ? logoUrl.trim() : null;
    debugPrint('logoUrl: $sanitizedUrl');
    return SizedBox(
      width: 80, // Aumentado levemente de 75 para 80 para dar mais margem
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: sanitizedUrl == null
                ? Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ClipOval(
                    child: Image.network(
                      sanitizedUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        return Center(
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 2, // Permitir até 2 linhas
            softWrap: true, // Habilitar quebra de linha
            overflow: TextOverflow
                .ellipsis, // Se for maior que 2 linhas, coloca "..."
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10, // Reduzido para 10 para comportar melhor a quebra
              fontWeight: FontWeight.w600,
              height: 1.1, // Ajuste de altura de linha para ficar compacto
            ),
          ),
        ],
      ),
    );
  }
}
