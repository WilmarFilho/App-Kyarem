// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/campeonato.dart';
import '../../../../services/campeonato_service.dart';
import 'atletica_campeonato_screen.dart';

/// Tela de associação: o presidente seleciona um campeonato via UI refinada
/// e é direcionado para a tela de gestão daquele campeonato.
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

  @override
  void initState() {
    super.initState();
    _loadCampeonatos();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCampeonatos() async {
    try {
      final data = await _campeonatoService.getCampeonatos();
      setState(() {
        _campeonatos = data
            .where((c) =>
                c.status.toUpperCase() == 'ATIVO' ||
                c.status.toUpperCase() == 'EM_ANDAMENTO')
            .toList();
        _filtrados = _campeonatos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar campeonatos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? _campeonatos
          : _campeonatos
              .where((c) =>
                  c.nome.toLowerCase().contains(q) ||
                  (c.edicao?.toLowerCase().contains(q) ?? false))
              .toList();
    });
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Selecionar Campeonato',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          // Cabeçalho com instrução
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.minhaAtletica.atleticaNome ?? 'Sua atlética',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selecione um campeonato para gerenciar sua participação — inscrever times, atletas e staff.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Buscar campeonato...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de campeonatos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.secondary))
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined,
                                size: 64,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _campeonatos.isEmpty
                                  ? 'Nenhum campeonato ativo no momento.'
                                  : 'Nenhum resultado para sua busca.',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              // Escudo / ícone do campeonato
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  image: campeonato.escudoUrl != null &&
                          campeonato.escudoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(campeonato.escudoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: campeonato.escudoUrl == null ||
                        campeonato.escudoUrl!.isEmpty
                    ? const Icon(Icons.emoji_events,
                        color: AppColors.secondary, size: 28)
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
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (campeonato.edicao != null) ...[
                      const SizedBox(height: 2),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(campeonato.dataInicio!) +
                                (campeonato.dataFim != null
                                    ? ' → ${_formatDate(campeonato.dataFim!)}'
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
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
