// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/campeonato.dart';
import '../../../../services/campeonato_service.dart';
import 'atletica_campeonato_screen.dart';

class AtleticaEnrollmentScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaEnrollmentScreen({super.key, required this.minhaAtletica});

  @override
  State<AtleticaEnrollmentScreen> createState() =>
      _AtleticaEnrollmentScreenState();
}

class _AtleticaEnrollmentScreenState extends State<AtleticaEnrollmentScreen> {
  final _campeonatoService = CampeonatoService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Campeonato> _campeonatos = [];
  List<Campeonato> _filtrados = [];
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadCampeonatos();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCampeonatos() async {
    try {
      final data = await _campeonatoService.getCampeonatos();
      if (!mounted) return;
      setState(() {
        _campeonatos = data
            .where(
              (c) =>
                  c.status.toUpperCase() == 'ATIVO' ||
                  c.status.toUpperCase() == 'EM_ANDAMENTO',
            )
            .toList();
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar campeonatos: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase().trim();
    final filtered = _campeonatos.where((c) {
      final matchesSearch =
          q.isEmpty ||
          c.nome.toLowerCase().contains(q) ||
          (c.edicao?.toLowerCase().contains(q) ?? false);
      final status = c.status.toUpperCase();
      final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    setState(() => _filtrados = filtered);
  }

  void _selectCampeonato(Campeonato campeonato) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AtleticaCampeonatoScreen(
          minhaAtletica: widget.minhaAtletica,
          campeonato: campeonato,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 7, 106, 227), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Participação em campeonatos',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${widget.minhaAtletica.atleticaNome ?? 'Sua atlética'} escolhe aqui em qual campeonato deseja entrar para gerenciar times, atletas e staff.',
                        style: const TextStyle(
                          color: Color(0xFFD7E0EA),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE8EDF5),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Buscar campeonato ou edição',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.textMuted,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _StatusChip(
                                    label: 'Todos',
                                    selected: _statusFilter == 'ALL',
                                    onTap: () {
                                      setState(() => _statusFilter = 'ALL');
                                      _applyFilters();
                                    },
                                  ),
                                 
                                  _StatusChip(
                                    label: 'Em andamento',
                                    selected:
                                        _statusFilter == 'EM_ANDAMENTO',
                                    onTap: () {
                                      setState(
                                        () => _statusFilter = 'EM_ANDAMENTO',
                                      );
                                      _applyFilters();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        )
                      : _filtrados.isEmpty
                      ? _EmptyCampeonatoState(
                          hasSearchOrFilter:
                              _searchController.text.trim().isNotEmpty ||
                              _statusFilter != 'ALL',
                          hasAny: _campeonatos.isNotEmpty,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${_filtrados.length} campeonato(s)',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Escolha um para continuar',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  20,
                                ),
                                itemCount: _filtrados.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final c = _filtrados[index];
                                  return _CampeonatoCard(
                                    campeonato: c,
                                    onTap: () => _selectCampeonato(c),
                                  );
                                },
                              ),
                            ),
                          ],
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

class _CampeonatoCard extends StatelessWidget {
  final Campeonato campeonato;
  final VoidCallback onTap;

  const _CampeonatoCard({required this.campeonato, required this.onTap});

  String get _statusLabel {
    switch (campeonato.status.toUpperCase()) {
      case 'ATIVO':
        return 'Ativo';
      case 'EM_ANDAMENTO':
        return 'Em andamento';
      default:
        return campeonato.status;
    }
  }

  Color get _statusColor {
    switch (campeonato.status.toUpperCase()) {
      case 'ATIVO':
        return const Color(0xFF2E9E56);
      case 'EM_ANDAMENTO':
        return const Color(0xFF1565C0);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  image: campeonato.escudoUrl != null &&
                          campeonato.escudoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(campeonato.escudoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    campeonato.escudoUrl == null ||
                        campeonato.escudoUrl!.isEmpty
                    ? const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.secondary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campeonato.nome,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (campeonato.edicao?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        campeonato.edicao!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (campeonato.dataInicio != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(campeonato.dataInicio!) +
                                (campeonato.dataFim != null
                                    ? ' - ${_formatDate(campeonato.dataFim!)}'
                                    : ''),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length >= 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return iso;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        selectedColor: AppColors.secondary.withValues(alpha: 0.14),
        checkmarkColor: AppColors.secondary,
        side: BorderSide(
          color: selected ? AppColors.secondary : const Color(0xFFD7E0EA),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.secondary : AppColors.textMuted,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _EmptyCampeonatoState extends StatelessWidget {
  final bool hasSearchOrFilter;
  final bool hasAny;

  const _EmptyCampeonatoState({
    required this.hasSearchOrFilter,
    required this.hasAny,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              !hasAny
                  ? 'Nenhum campeonato ativo no momento.'
                  : hasSearchOrFilter
                  ? 'Nenhum campeonato encontrado com esse filtro.'
                  : 'Nenhum campeonato disponível.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
