import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../screens/main/calendar_screen.dart';
import '../../screens/main/favorites_screen.dart';
import '../../screens/main/matches_screen.dart';
import '../../screens/main/search_screen.dart';
import '../../../services/partida_service.dart';

class MainTopBar extends StatelessWidget {
  const MainTopBar({
    super.key,
    required this.onProfileTap,
    this.hasPendingInvite = false,
    this.trailing,
  });

  final VoidCallback onProfileTap;
  final bool hasPendingInvite;
  final Widget? trailing;

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _openQuickMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Fechar acesso rápido',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        final panelWidth = MediaQuery.of(context).size.width * 0.62;
        return Align(
          alignment: Alignment.centerRight,
          child: _QuickLinksPanel(width: panelWidth),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openSearch(context),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF99AABB),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Buscar Rápida',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF99AABB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MainTopBarIconButton(
            icon: Icons.bolt_rounded,
            onTap: () => _openQuickMenu(context),
          ),
          const SizedBox(width: 8),
          MainTopBarIconButton(
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
            highlighted: hasPendingInvite,
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class MainTopBarIconButton extends StatelessWidget {
  const MainTopBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? AppColors.secondary
                  : AppColors.secondary.withValues(alpha: 0.14),
              width: highlighted ? 1.8 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, size: 22, color: AppColors.primary)),
              if (highlighted)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painel de Acesso Rápido ────────────────────────────────────────────────────

class _QuickLinksPanel extends StatelessWidget {
  const _QuickLinksPanel({required this.width});

  final double width;

  void _navigate(BuildContext context, Widget screen) {
    // Captura o navigator ANTES do pop — após pop() o contexto do diálogo
    // é deactivated e Navigator.of(context) lançaria uma assertion.
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );
  }

  /// Abre a tela de partidas — busca os dados no cache ou API.
  Future<void> _openResultados(BuildContext context) async {
    // Captura o navigator ANTES do pop pelo mesmo motivo que _navigate.
    final nav = Navigator.of(context);
    nav.pop();
    try {
      final partidas = await PartidaService().getPartidasFeed();
      nav.push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => MatchesScreen(partidas: partidas),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 340),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final atalhos = [
      _QuickShortcut(
        title: 'Calendário',
        subtitle: 'Veja a agenda de partidas no calendário',
        icon: Icons.calendar_month_rounded,
        onTap: () => _navigate(context, const CalendarScreen()),
      ),
      _QuickShortcut(
        title: 'Resultados',
        subtitle: 'Checar placares e destaques recentes',
        icon: Icons.scoreboard_rounded,
        onTap: () => _openResultados(context),
      ),
      _QuickShortcut(
        title: 'Favoritos',
        subtitle: 'Todos seus favoritados',
        icon: Icons.star_rounded,
        onTap: () => _navigate(context, const FavoritesScreen()),
      ),
    ];

    return Material(
      color: Colors.white,
      elevation: 18,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Acesso rápido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Atalhos para as áreas que mais importam durante o evento.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                ...atalhos.map(
                  (atalho) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShortcutTile(atalho: atalho),
                  ),
                ),
                const Spacer(),
                // Rodapé decorativo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1A3A6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Acesse rapidamente o que importa.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tile individual do atalho ──────────────────────────────────────────────────

class _ShortcutTile extends StatefulWidget {
  const _ShortcutTile({required this.atalho});
  final _QuickShortcut atalho;

  @override
  State<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends State<_ShortcutTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.atalho.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.secondary.withValues(alpha: 0.06)
                : const Color(0xFFF7FAFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? AppColors.secondary.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.atalho.icon,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.atalho.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.atalho.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modelo ─────────────────────────────────────────────────────────────────────

class _QuickShortcut {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
