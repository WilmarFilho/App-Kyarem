import 'package:flutter/material.dart';

/// Widget de cartão de placar para o resumo da partida
class SummaryScoreCard extends StatelessWidget {
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  final String? escudoA;
  final String? escudoB;

  const SummaryScoreCard({
    super.key,
    required this.timeA,
    required this.timeB,
    required this.golsA,
    required this.golsB,
    this.escudoA,
    this.escudoB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _timeColumn(timeA, golsA, Colors.orange, escudoA),
          const Text(
            "VS",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          _timeColumn(timeB, golsB, Colors.blue, escudoB),
        ],
      ),
    );
  }

  Widget _timeColumn(String nome, int gols, Color cor, String? escudo) {
    final String logoUrl = escudo ?? '';

    return Column(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
          child: logoUrl.isEmpty
              ? Text(
                  nome.isNotEmpty ? nome[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          gols.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }
}