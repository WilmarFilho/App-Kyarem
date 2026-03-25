import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final double heightFactor;

  const GradientBackground({super.key, this.heightFactor = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.6, -0.7),
          radius: 1.6,
          colors: [
            Color.fromARGB(255, 177, 0, 0), // Lighter dark red at center
            const Color(0xFF260404), // Main background red/brown
            const Color(0xFF110101), // Almost black for edge
          ],
        ),
      ),
    );
  }
}
