import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../widgets/shared/metric_tile.dart';
import '../../widgets/shared/partida_card_widget.dart';
import 'matches_screen.dart';
import 'search_screen.dart';

const _partidasMock = [
  PartidaMock(
    esporte: 'Futsal',
    esporteIcon: Icons.sports_soccer,
    campeonatoNome: 'Copa Universitária Sudeste',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/copa-sudeste/80/80',
    timeA: 'AAAFEI',
    timeB: 'AAAUSP',
    horario: '14:30',
    dia: 'Hoje',
    aoVivo: true,
    placarA: '2',
    placarB: '1',
  ),
  PartidaMock(
    esporte: 'Vôlei',
    esporteIcon: Icons.sports_volleyball,
    campeonatoNome: 'Liga Paulista Universitária',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/liga-paulista/80/80',
    timeA: 'CAASO',
    timeB: 'AAUNICAMP',
    horario: '16:00',
    dia: 'Hoje',
  ),
  PartidaMock(
    esporte: 'Basquete',
    esporteIcon: Icons.sports_basketball,
    campeonatoNome: 'Circuito Atléticas Brasil',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/circuito-atleticas/80/80',
    timeA: 'AAAUFSCAR',
    timeB: 'CAAFEA',
    horario: '18:30',
    dia: 'Hoje',
  ),
  PartidaMock(
    esporte: 'Futebol',
    esporteIcon: Icons.sports_soccer,
    campeonatoNome: 'Taça Interior Universitária',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/taca-interior/80/80',
    timeA: 'AAAFEI',
    timeB: 'CAAESQ',
    horario: '10:00',
    dia: 'Amanhã',
  ),
  PartidaMock(
    esporte: 'Handebol',
    esporteIcon: Icons.sports_handball,
    campeonatoNome: 'Jogos Universitários Elite',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/jogos-elite/80/80',
    timeA: 'AAUNICAMP',
    timeB: 'AAAUSP',
    horario: '15:00',
    dia: 'Amanhã',
  ),
  PartidaMock(
    esporte: 'Vôlei',
    esporteIcon: Icons.sports_volleyball,
    campeonatoNome: 'Festival Atléticas em Quadra',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/festival-quadra/80/80',
    timeA: 'CAASO',
    timeB: 'AAAUFSCAR',
    horario: '09:30',
    dia: 'Depois',
  ),
  PartidaMock(
    esporte: 'Tênis',
    esporteIcon: Icons.sports_tennis,
    campeonatoNome: 'Open Universitário Nacional',
    campeonatoAvatarUrl: 'https://picsum.photos/seed/open-universitario/80/80',
    timeA: 'AAAFEI',
    timeB: 'CAAFEA',
    horario: '14:00',
    dia: 'Depois',
  ),
];

class _FiltroEsporte {
  final String label;
  final IconData icon;

  const _FiltroEsporte(this.label, this.icon);
}

class _AtalhoRapido {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AtalhoRapido({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const _filtros = [
  _FiltroEsporte('Todos', Icons.sports_rounded),
  _FiltroEsporte('Futebol', Icons.sports_soccer),
  _FiltroEsporte('Futsal', Icons.sports_soccer),
  _FiltroEsporte('Vôlei', Icons.sports_volleyball),
  _FiltroEsporte('Basquete', Icons.sports_basketball),
  _FiltroEsporte('Handebol', Icons.sports_handball),
  _FiltroEsporte('Tênis', Icons.sports_tennis),
];

const _atalhos = [
  _AtalhoRapido(
    title: 'Calendário',
    subtitle: 'Ver agenda de partidas da semana',
    icon: Icons.calendar_month_rounded,
  ),
  _AtalhoRapido(
    title: 'Resultados',
    subtitle: 'Checar placares e destaques recentes',
    icon: Icons.scoreboard_rounded,
  ),
  _AtalhoRapido(
    title: 'Atléticas favoritas',
    subtitle: 'Abrir as torcidas que você acompanha',
    icon: Icons.groups_rounded,
  ),
  _AtalhoRapido(
    title: 'Alertas',
    subtitle: 'Visualizar notificações e lembretes',
    icon: Icons.notifications_active_rounded,
  ),
];

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _filtroIndex = 0;

  List<PartidaMock> get _partidasFiltradas {
    if (_filtroIndex == 0) return _partidasMock;
    final label = _filtros[_filtroIndex].label;
    return _partidasMock.where((p) => p.esporte == label).toList();
  }

  void _abrirBusca() {
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

  void _abrirPartidas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchesScreen(partidas: _partidasFiltradas),
      ),
    );
  }

  void _abrirQuickMenu() {
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

  void _abrirFiltroModal() {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Fechar filtros',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _MatchFiltersModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partidas = _partidasFiltradas;

    return Column(
      children: [
        _TopBar(
          onSearchTap: _abrirBusca,
          onQuickLinksTap: _abrirQuickMenu,
          onProfileTap: widget.onProfileTap,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              const Row(
                children: [
                  MetricTile(label: 'Campeonatos ativos', value: '12'),
                  SizedBox(width: 12),
                  MetricTile(label: 'Atléticas mapeadas', value: '48'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Próximas partidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _abrirPartidas,
                    child: Text(
                      'Ver todas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _abrirFiltroModal,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filtros.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _filtroIndex;
                    final filtro = _filtros[i];
                    return GestureDetector(
                      onTap: () => setState(() => _filtroIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.secondary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.secondary
                                : const Color(0xFFDDE3EE),
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              filtro.icon,
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filtro.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (partidas.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sports_rounded,
                        size: 48,
                        color: Color(0xFFDDE3EE),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma partida encontrada',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...partidas.map((p) => PartidaCardWidget(partida: p)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onSearchTap,
    required this.onQuickLinksTap,
    required this.onProfileTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onQuickLinksTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
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
                      'Buscar partidas, atléticas...',
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
          _IconButton(icon: Icons.bolt_rounded, onTap: onQuickLinksTap),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.person_outline_rounded, onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _QuickLinksPanel extends StatelessWidget {
  const _QuickLinksPanel({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
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
                ..._atalhos.map(
                  (atalho) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: const Color(0xFFF7FAFE),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  atalho.icon,
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
                                      atalho.title,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      atalho.subtitle,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Mais atalhos e ações contextuais entram aqui depois.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
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

class _MatchFiltersModal extends StatelessWidget {
  const _MatchFiltersModal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrar partidas',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Refine por campeonato, atlética, período e status das partidas.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const _FilterSection(
                title: 'Campeonato',
                options: [
                  'Todos',
                  'Copa Universitária Sudeste',
                  'Liga Paulista Universitária',
                  'Open Universitário Nacional',
                ],
              ),
              const SizedBox(height: 14),
              const _FilterSection(
                title: 'Atlética',
                options: ['Todas', 'AAAFEI', 'AAAUSP', 'AAUNICAMP', 'CAASO'],
              ),
              const SizedBox(height: 14),
              const _FilterSection(
                title: 'Data',
                options: ['Hoje', 'Amanhã', 'Próximos 7 dias'],
              ),
              const SizedBox(height: 14),
              const _FilterSection(
                title: 'Status',
                options: ['Todas', 'Ao vivo', 'Agendadas', 'Finalizadas'],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.22),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.options});

  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (option) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFE),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDDE6F2)),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
              color: AppColors.secondary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}
