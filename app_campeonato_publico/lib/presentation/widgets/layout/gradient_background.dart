import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final double heightFactor;

  const GradientBackground({super.key, this.heightFactor = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        // Mudamos para Linear para um controle maior da "queda" da luz
        // Ou um Radial com foco deslocado e cores mais análogas
        gradient: RadialGradient(
          center: Alignment(0.7, -0.6), // Luz vindo do canto superior direito
          radius: 1.8,
          colors: [
            Color(
              0xFF450A0A,
            ), // Um vermelho profundo, menos saturado (Bordeaux)
            Color(0xFF1A0505), // Transição suave para um vinho quase preto
            Color(0xFF0D0202), // O "True Dark" para as extremidades
          ],
          stops: [0.0, 0.4, 1.0], // Controle de onde a luz começa a dissipar
        ),
      ),
    );
  }
}
