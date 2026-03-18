import 'package:flutter/material.dart';

/// Widget de botões de ação para o resumo da partida
class SummaryActionButtons extends StatelessWidget {
  final VoidCallback onPdfPressed;
  final VoidCallback? onClosePressed;
  final VoidCallback onHomePressed;

  const SummaryActionButtons({
    super.key,
    required this.onPdfPressed,
    this.onClosePressed,
    required this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPdfPressed,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                "VER PDF DA SÚMULA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          if (onClosePressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onClosePressed,
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                label: const Text(
                  "FECHAR SÚMULA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onHomePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                "VOLTAR PARA O INÍCIO",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
