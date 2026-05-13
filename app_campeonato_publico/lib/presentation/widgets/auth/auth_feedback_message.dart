import 'package:flutter/material.dart';

/// Widget para exibir mensagens de feedback (erro ou sucesso) nas telas de autenticação
class AuthFeedbackMessage extends StatelessWidget {
  final String? errorMessage;
  final String? successMessage;
  
  const AuthFeedbackMessage({
    super.key,
    this.errorMessage,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null && successMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorMessage != null)
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (successMessage != null)
            Text(
              successMessage!,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
