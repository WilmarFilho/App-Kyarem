import 'package:flutter/material.dart';

/// Design tokens centralizados do App Publico.
/// Substitui todas as cores hardcoded espalhadas pelo projeto.
abstract class AppColors {
  // ── Cores Primárias ─────────────────────────────────────────────────
  /// Vermelho principal — brand color
  static const Color primary = Color(0xFFF22F1D);

  /// Laranja/accent — botões secundários e game screens
  static const Color accent = Color(0xFFF85C39);

  /// Laranja intermediário — gradientes
  static const Color orange = Color(0xFFF2561D);

  /// Laranja escuro — modalidades
  static const Color orangeDark = Color(0xFFF26B1D);

  /// Âmbar — variante para cards
  static const Color amber = Color(0xFFF29422);

  // ── Backgrounds ─────────────────────────────────────────────────────
  /// Fundo principal escuro
  static const Color bgDark = Color(0xFF260404);

  /// Fundo de cards
  static const Color bgCard = Color(0xFF110101);

  /// Fundo de superfícies elevadas
  static const Color surface = Color(0xFF160202);

  /// Fundo denso (dark sections)
  static const Color bgDeep = Color(0xFF1A0202);

  // ── Utilitários ─────────────────────────────────────────────────────
  /// Sucesso
  static const Color success = Color(0xFF2E7D32);
}
