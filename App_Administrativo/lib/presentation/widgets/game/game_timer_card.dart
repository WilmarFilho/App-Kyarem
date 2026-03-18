import 'package:flutter/material.dart';
import '../../screens/game/partida_screen.dart';

class GameTimerCard extends StatelessWidget {
  final int segundos;
  final bool rodando;
  final bool partidaJaIniciou;
  final PeriodoPartida periodoAtual;
  final bool emPausaTecnica;
  final String timeEmPausaTecnica;
  final int segundosPausaTecnica;
  final int segundosPausa;
  final int tempoProrrogacao;
  final bool temProrrogacao;
  
  // Prop para o cronômetro de intervalo
  final int segundosIntervalo; 

  // Campos para Acréscimo
  final int tempoAcrescimo;
  final bool temAcrescimo;

  final VoidCallback onToggleCronometro;
  final VoidCallback? onFinalizarPrimeiroTempo;
  final VoidCallback? onFinalizarSegundoTempo;
  final VoidCallback? onAbrirModalProrrogacao;
  final VoidCallback? onAbrirModalAcrescimo;
  final VoidCallback? onIniciarSegundoTempo;

  const GameTimerCard({
    super.key,
    required this.segundos,
    required this.rodando,
    required this.partidaJaIniciou,
    required this.periodoAtual,
    required this.emPausaTecnica,
    required this.timeEmPausaTecnica,
    required this.segundosPausaTecnica,
    required this.segundosPausa,
    required this.tempoProrrogacao,
    required this.temProrrogacao,
    required this.tempoAcrescimo,
    required this.temAcrescimo,
    required this.segundosIntervalo, 
    required this.onToggleCronometro,
    this.onFinalizarPrimeiroTempo,
    this.onFinalizarSegundoTempo,
    this.onAbrirModalProrrogacao,
    this.onAbrirModalAcrescimo,
    this.onIniciarSegundoTempo,
  });

  String _formatarTempo(int totalSegundos) {
    int min = totalSegundos ~/ 60;
    int seg = totalSegundos % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isIntervalo = periodoAtual == PeriodoPartida.intervalo;

    if (periodoAtual == PeriodoPartida.finalizada || periodoAtual == PeriodoPartida.fechada) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.sports_soccer, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text(
                'PARTIDA ENCERRADA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Botão Play/Pause (Sempre visível para permitir iniciar o 2º tempo)
          IconButton(
            onPressed: onToggleCronometro,
            icon: Icon(
              (rodando && !isIntervalo) ? Icons.pause_circle : Icons.play_circle,
              color: isIntervalo ? const Color(0xFF00FFC2) : Colors.white,
              size: 40,
            ),
          ),

          // Coluna Central (Cronômetro)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isIntervalo ? _formatarTempo(segundosIntervalo) : _formatarTempo(segundos),
                  style: TextStyle(
                    color: isIntervalo ? Colors.orange : const Color(0xFFD4FFD4),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                if (isIntervalo)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.coffee_rounded, color: Colors.orange, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'INTERVALO',
                        style: TextStyle(
                          color: Colors.orange, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),

                // Feedback de Acréscimo
                if (temAcrescimo && !isIntervalo)
                  Text(
                    periodoAtual == PeriodoPartida.acrescimo 
                        ? 'JOGO ATÉ ${tempoAcrescimo ~/ 60}min'
                        : 'Acréscimo: ${tempoAcrescimo ~/ 60}min',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                // Feedback de Prorrogação
                if (periodoAtual == PeriodoPartida.prorrogacao)
                  const Text(
                    'EM PRORROGAÇÃO',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold),
                  )
                else if (temProrrogacao && periodoAtual == PeriodoPartida.segundoTempo)
                  Text(
                    'PRORROGAÇÃO (${tempoProrrogacao ~/ 60}min)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orange, fontSize: 10),
                  ),
              ],
            ),
          ),

          // Coluna de Ações (Direita)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lógica para 1º Tempo
              if (periodoAtual == PeriodoPartida.primeiroTempo && !emPausaTecnica) ...[
                _buildTimeButton(
                  "Fim 1º tempo",
                  onFinalizarPrimeiroTempo ?? () {},
                ),
                const SizedBox(height: 4),
                _buildTimeButton(
                  temAcrescimo ? "Acr: ${tempoAcrescimo ~/ 60}min" : "Dar Acréscimo",
                  onAbrirModalAcrescimo ?? () {},
                ),
              ],

              // Lógica para 2º Tempo
              if (periodoAtual == PeriodoPartida.segundoTempo && !emPausaTecnica) ...[
                _buildTimeButton(
                  "Fim 2º tempo",
                  onFinalizarSegundoTempo ?? () {},
                ),
                const SizedBox(height: 4),
                _buildTimeButton(
                  temAcrescimo ? "Acr: ${tempoAcrescimo ~/ 60}min" : "Dar Acréscimo",
                  onAbrirModalAcrescimo ?? () {},
                ),
                const SizedBox(height: 4),
                _buildTimeButton(
                  temProrrogacao ? "Prr: ${tempoProrrogacao ~/ 60}min" : "Dar Prorrogação",
                  onAbrirModalProrrogacao ?? () {},
                ),
              ],
              
              // Se estiver no intervalo, a coluna de ações fica vazia (ou pode adicionar o botão de iniciar caso queira duplicar a função do play)
              if (isIntervalo && onIniciarSegundoTempo != null)
                _buildTimeButton(
                  "Iniciar 2º Tempo",
                  onIniciarSegundoTempo!,
                  color: const Color(0xFF00FFC2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, VoidCallback onPressed, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color == Colors.white ? Colors.black87 : Colors.black,
          ),
        ),
      ),
    );
  }
}