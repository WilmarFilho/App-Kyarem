import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.85, -0.9),
          radius: 1.5,
          colors: [
            Color(0xFFBBD2FF),
            Color(0xFFEAF1FF),
            Color(0xFFF6F8FD),
          ],
          stops: [0, 0.35, 1],
        ),
      ),
    );
  }
}
