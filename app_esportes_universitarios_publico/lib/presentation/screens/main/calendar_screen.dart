import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../models/partida_feed_item.dart';
import '../../../services/partida_service.dart';
import '../../widgets/shared/partida_card_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final PartidaService _service = PartidaService();

  List<PartidaFeedItem> _partidas = const [];
  bool _loading = true;

  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _load();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getPartidasFeed();
      if (!mounted) return;
      setState(() {
        _partidas = list;
        _loading = false;
      });
      _slideCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Set<DateTime> get _datesWithMatches {
    return _partidas
        .map((p) {
          final d = p.agendadoPara ?? p.iniciadaEm ?? p.encerradaEm;
          return d != null ? _dateOnly(d) : null;
        })
        .whereType<DateTime>()
        .toSet();
  }

  List<PartidaFeedItem> get _selectedDayPartidas {
    if (_selectedDay == null) return const [];
    return _partidas.where((p) {
      final d = p.agendadoPara ?? p.iniciadaEm ?? p.encerradaEm;
      if (d == null) return false;
      return _dateOnly(d) == _selectedDay;
    }).toList();
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
    _slideCtrl.forward(from: 0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.secondary,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: 8),
                        _buildDaySection(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cabeçalho gradiente ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendário',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Agenda de partidas',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildLivePulse(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePulse() {
    final liveCount = _partidas.where((p) => p.isLive).length;
    if (liveCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE83B3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$liveCount ao vivo',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendário ─────────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    final days = _daysInMonth(_focusedMonth);
    final firstWeekday = days.first.weekday % 7; // 0=Dom, 1=Seg, ...
    final withMatches = _datesWithMatches;

    final monthLabel = _monthName(_focusedMonth.month);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navegação de mês
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(
              children: [
                Text(
                  '$monthLabel ${_focusedMonth.year}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _prevMonth,
                ),
                const SizedBox(width: 4),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _nextMonth,
                ),
              ],
            ),
          ),

          // Cabeçalho dias da semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Grade de dias
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: days.length + firstWeekday,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox.shrink();
                final day = days[index - firstWeekday];
                final isToday = _dateOnly(DateTime.now()) == day;
                final isSelected = _selectedDay == day;
                final hasMatch = withMatches.contains(day);

                return GestureDetector(
                  onTap: () => _selectDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary
                          : isToday
                              ? AppColors.secondary.withValues(alpha: 0.10)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        if (hasMatch && !isSelected)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Seção de partidas do dia selecionado ───────────────────────────────────

  Widget _buildDaySection() {
    final partidas = _selectedDayPartidas;
    final label = _selectedDay != null
        ? '${_selectedDay!.day} de ${_monthName(_selectedDay!.month)}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                partidas.isEmpty
                    ? 'Sem partidas'
                    : '${partidas.length} partida${partidas.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (partidas.isEmpty)
            SlideTransition(
              position: _slideAnim,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 40,
                      color: Color(0xFFDDE3EE),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Nenhuma partida nesta data',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SlideTransition(
              position: _slideAnim,
              child: Column(
                children: partidas
                    .map((p) => PartidaCardWidget(partida: p))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return names[month];
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
