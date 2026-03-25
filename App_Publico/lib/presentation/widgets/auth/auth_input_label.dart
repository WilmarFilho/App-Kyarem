import 'package:flutter/material.dart';

/// Widget para exibir labels padronizados nos campos de entrada de autenticação
class AuthInputLabel extends StatelessWidget {
  final String label;

  const AuthInputLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
