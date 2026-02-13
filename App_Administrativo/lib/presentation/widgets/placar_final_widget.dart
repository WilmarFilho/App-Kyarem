import 'dart:ui';
import 'package:flutter/material.dart';

class PlacarFinalWidget extends StatelessWidget {
  final String nomeTimeA;
  final String nomeTimeB;
  final int placarA;
  final int placarB;

  const PlacarFinalWidget({
    super.key,
    required this.nomeTimeA,
    required this.nomeTimeB,
    required this.placarA,
    required this.placarB,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timeInfo(nomeTimeA, placarA, Colors.blueAccent),
              const Text(
                "VS",
                style: TextStyle(color: Colors.white24, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              _timeInfo(nomeTimeB, placarB, Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeInfo(String nome, int placar, Color cor) {
    return Column(
      children: [
        Text(nome, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("$placar", style: TextStyle(color: cor, fontSize: 48, fontWeight: FontWeight.w900)),
      ],
    );
  }
}