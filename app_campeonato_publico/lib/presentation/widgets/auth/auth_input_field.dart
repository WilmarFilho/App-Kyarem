import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Campo de entrada padronizado para telas de autenticação
/// Suporta ícones SVG, texto obscuro (senha) e diferentes tipos de teclado
class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? svgAsset;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool isSmall;
  
  const AuthInputField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.svgAsset,
    this.obscureText = false,
    this.keyboardType,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isSmall ? 48 : 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          if (svgAsset != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SvgPicture.asset(
                svgAsset!,
                width: 18,
                height: 18,
                // ignore: deprecated_member_use
                colorFilter: ColorFilter.mode(
                  AppColors.primary.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              // Remove autocorreção e primeira letra maiúscula para evitar erros de login
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(
                  right: 16,
                  left: svgAsset == null ? 16 : 0,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
