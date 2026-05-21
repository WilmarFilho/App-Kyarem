// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import '../../../../models/atletica_membro.dart';
import '../../../../models/campeonato.dart';
import '../../../../models/time_atletica.dart';
import '../../../../services/campeonato_service.dart';
import '../../../../services/membro_service.dart';
import '../../../../services/time_service.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/profile_service.dart';

/// Tela de gestão da participação da atlética em um campeonato específico.
/// Permite: inscrever times, ver atletas inscritos e gerenciar staff.
class AtleticaCampeonatoScreen extends StatefulWidget {
  final MinhaAtletica minhaAtletica;
  final Campeonato campeonato;

  const AtleticaCampeonatoScreen({
    super.key,
    required this.minhaAtletica,
    required this.campeonato,
  });

  @override
  State<AtleticaCampeonatoScreen> createState() =>
      _AtleticaCampeonatoScreenState();
}

class _AtleticaCampeonatoScreenState extends State<AtleticaCampeonatoScreen> {
  final _campeonatoService = CampeonatoService();
  final _timeService = TimeService();

  bool _isLoading = true;

  // Modalidades disponíveis no campeonato
  List<CampeonatoModalidade> _modalidadesCampeonato = [];

  // Times permanentes da atlética
  List<TimeAtletica> _timesPermanentes = [];

  // Times já inscritos neste campeonato (de qualquer atlética)
  List<CampeonatoTime> _timesInscritos = [];

  _CampeonatoView _selectedView = _CampeonatoView.meusTimes;
  String _selectedModalidadeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _campeonatoService.getModalidadesDoCampeonato(widget.campeonato.id),
        _timeService.getTimesPorAtletica(widget.minhaAtletica.atleticaId!),
        _timeService.getTimesDoCampeonato(widget.campeonato.id),
      ]);
      setState(() {
        _modalidadesCampeonato = results[0] as List<CampeonatoModalidade>;
        _timesPermanentes = results[1] as List<TimeAtletica>;
        _timesInscritos = (results[2] as List<CampeonatoTime>)
            .where(
              (t) =>
                  t.atleticaNome == widget.minhaAtletica.atleticaNome ||
                  _timesPermanentes.any((p) => p.id == t.timeAtleticaId),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  /// Verifica se a modalidade do time está associada ao campeonato.
  bool _modalidadeAssociada(TimeAtletica time) {
    return _modalidadesCampeonato.any(
      (m) => m.modalidadeId == time.modalidadeCatalogoId,
    );
  }

  /// Retorna a CampeonatoModalidade correspondente ao time (se houver).
  CampeonatoModalidade? _modalidadeDoCampeonatoParaTime(TimeAtletica time) {
    try {
      return _modalidadesCampeonato.firstWhere(
        (m) => m.modalidadeId == time.modalidadeCatalogoId,
      );
    } catch (_) {
      return null;
    }
  }

  List<_CampeonatoFilterOption> get _modalidadeFilters {
    final seen = <String>{};
    final options = <_CampeonatoFilterOption>[
      const _CampeonatoFilterOption(value: 'ALL', label: 'Todas'),
    ];

    for (final modalidade in _modalidadesCampeonato) {
      if (!seen.add(modalidade.id)) continue;
      options.add(
        _CampeonatoFilterOption(
          value: modalidade.id,
          label: modalidade.modalidadeNome,
        ),
      );
    }
    return options;
  }

  List<TimeAtletica> get _timesPermanentesFiltrados {
    if (_selectedModalidadeFilter == 'ALL') return _timesPermanentes;
    return _timesPermanentes.where((time) {
      final modalidade = _modalidadeDoCampeonatoParaTime(time);
      return modalidade?.id == _selectedModalidadeFilter;
    }).toList();
  }

  List<CampeonatoTime> get _timesInscritosFiltrados {
    if (_selectedModalidadeFilter == 'ALL') return _timesInscritos;
    return _timesInscritos.where((time) {
      if ((time.campeonatoModalidadeId ?? '').isNotEmpty) {
        return time.campeonatoModalidadeId == _selectedModalidadeFilter;
      }
      final modalidade = _modalidadesCampeonato.where(
        (m) => m.id == _selectedModalidadeFilter,
      );
      return modalidade.isNotEmpty &&
          time.modalidadeNome == modalidade.first.modalidadeNome;
    }).toList();
  }

  Future<void> _inscreverTime(TimeAtletica time) async {
    final modalidade = _modalidadeDoCampeonatoParaTime(time);
    if (modalidade == null) return;

    try {
      await _timeService.inscreverTimeNoCampeonato(
        campeonatoModalidadeId: modalidade.id,
        timeAtleticaId: time.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time inscrito com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao inscrever: $e')));
      }
    }
  }

  Future<void> _removerTime(CampeonatoTime ct) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover time'),
        content: Text(
          'Remover "${ct.nome ?? ct.modalidadeNome}" do campeonato?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'REMOVER',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _timeService.removerTimeDoCampeonato(ct.id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTimes = _timesPermanentesFiltrados.isNotEmpty;
    final hasInscritos = _timesInscritosFiltrados.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.campeonato.nome,
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    children: [
                      _buildContentToggle(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildFilterTags(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedView == _CampeonatoView.meusTimes
                      ? hasTimes
                          ? _buildTimesTab()
                          : _buildEmptyState(
                              _timesPermanentes.isEmpty
                                  ? 'Você não tem times cadastrados.\nCrie times em "Equipes Permanentes".'
                                  : 'Nenhum time encontrado para esse filtro.',
                              Icons.group_off,
                            )
                      : hasInscritos
                      ? _buildInscritosTab()
                      : _buildEmptyState(
                          _timesInscritos.isEmpty
                              ? 'Nenhum time inscrito neste campeonato.'
                              : 'Nenhum inscrito encontrado para esse filtro.',
                          Icons.emoji_events_outlined,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildContentToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CampeonatoTopSegmentButton(
              label: 'Meus Times',
              icon: Icons.shield_rounded,
              selected: _selectedView == _CampeonatoView.meusTimes,
              onTap: () {
                setState(() => _selectedView = _CampeonatoView.meusTimes);
              },
            ),
          ),
          Expanded(
            child: _CampeonatoTopSegmentButton(
              label: 'Inscritos',
              icon: Icons.emoji_events_rounded,
              selected: _selectedView == _CampeonatoView.inscritos,
              onTap: () {
                setState(() => _selectedView = _CampeonatoView.inscritos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTags() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _modalidadeFilters.map((option) {
          final selected = option.value == _selectedModalidadeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(option.label),
              onSelected: (_) {
                setState(() => _selectedModalidadeFilter = option.value);
              },
              selectedColor: AppColors.secondary.withValues(alpha: 0.14),
              checkmarkColor: AppColors.secondary,
              side: BorderSide(
                color: selected
                    ? AppColors.secondary
                    : const Color(0xFFD7E0EA),
              ),
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.secondary : AppColors.textMuted,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Aba 1: times permanentes da atlética ───────────────────────────────────
  Widget _buildTimesTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      itemCount: _timesPermanentesFiltrados.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final time = _timesPermanentesFiltrados[i];
        final jaInscrito = _timesInscritos.any(
          (ct) => ct.timeAtleticaId == time.id,
        );
        final modalidadeOk = _modalidadeAssociada(time);

        return _TimeCard(
          time: time,
          jaInscrito: jaInscrito,
          modalidadeAssociada: modalidadeOk,
          onInscrever: modalidadeOk && !jaInscrito
              ? () => _inscreverTime(time)
              : (jaInscrito
                    ? () {
                        final ct = _timesInscritos.firstWhere(
                          (c) => c.timeAtleticaId == time.id,
                        );
                        _removerTime(ct);
                      }
                    : null),
          onVerAtletas: () {
            if (jaInscrito) {
              final ct = _timesInscritos.firstWhere(
                (c) => c.timeAtleticaId == time.id,
              );
              _showAtletasSheet(ct);
            } else {
              // Passa null para CampeonatoTime, pois não está inscrito, mas a sheet deve suportar exibir apenas a atlética
              _showAtletasSheet(
                CampeonatoTime(
                  id: '',
                  timeAtleticaId: time.id,
                  nome: time.nome,
                ),
              );
            }
          },
        );
      },
    );
  }

  // ─── Aba 2: times já inscritos ───────────────────────────────────────────────
  Widget _buildInscritosTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      itemCount: _timesInscritosFiltrados.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final ct = _timesInscritosFiltrados[i];
        return _InscritoCard(
          campeonatoTime: ct,
          onVerAtletas: () => _showAtletasSheet(ct),
          onRemover: () => _removerTime(ct),
        );
      },
    );
  }

  // ─── Sheet de atletas do time no campeonato ──────────────────────────────────
  void _showAtletasSheet(CampeonatoTime ct) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RosterSheet(
        campeonatoTime: ct,
        minhaAtletica: widget.minhaAtletica,
        timeService: _timeService,
        membroService: MembroService(),
      ),
    );
  }
}

enum _CampeonatoView { meusTimes, inscritos }

class _CampeonatoFilterOption {
  final String value;
  final String label;

  const _CampeonatoFilterOption({
    required this.value,
    required this.label,
  });
}

class _CampeonatoTopSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CampeonatoTopSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.secondary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.secondary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card: time permanente ────────────────────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final TimeAtletica time;
  final bool jaInscrito;
  final bool modalidadeAssociada;
  final VoidCallback? onInscrever;
  final VoidCallback? onVerAtletas;

  const _TimeCard({
    required this.time,
    required this.jaInscrito,
    required this.modalidadeAssociada,
    this.onInscrever,
    this.onVerAtletas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: jaInscrito
              ? const Color(0xFF2E9E56).withValues(alpha: 0.4)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time.nome,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${time.modalidadeNome ?? "—"} · ${time.genero == "M"
                          ? "Masculino"
                          : time.genero == "F"
                          ? "Feminino"
                          : "Misto"}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (jaInscrito)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E9E56).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Inscrito',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E9E56),
                    ),
                  ),
                ),
            ],
          ),
          // Aviso se modalidade não está no campeonato
          if (!modalidadeAssociada) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A modalidade "${time.modalidadeNome}" não está associada a este campeonato.',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (onVerAtletas != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onVerAtletas,
                    icon: const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    label: const Text(
                      'Ver Atletas',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (!jaInscrito && modalidadeAssociada)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onInscrever,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Inscrever',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (jaInscrito)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        onInscrever, // Tratar como remover no onInscrever callback na listagem
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'Tirar Inscrição',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Card: time inscrito ──────────────────────────────────────────────────────
class _InscritoCard extends StatelessWidget {
  final CampeonatoTime campeonatoTime;
  final VoidCallback onVerAtletas;
  final VoidCallback onRemover;

  const _InscritoCard({
    required this.campeonatoTime,
    required this.onVerAtletas,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campeonatoTime.nome ??
                      campeonatoTime.modalidadeNome ??
                      'Time',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                if (campeonatoTime.modalidadeNome != null)
                  Text(
                    campeonatoTime.modalidadeNome!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline, color: AppColors.secondary),
            tooltip: 'Ver atletas',
            onPressed: onVerAtletas,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Remover',
            onPressed: onRemover,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet de Roster (Atletas & Staff) ──────────────────────────────────────────────────
class _RosterSheet extends StatefulWidget {
  final CampeonatoTime campeonatoTime;
  final MinhaAtletica minhaAtletica;
  final TimeService timeService;
  final MembroService membroService;

  const _RosterSheet({
    required this.campeonatoTime,
    required this.minhaAtletica,
    required this.timeService,
    required this.membroService,
  });

  @override
  State<_RosterSheet> createState() => _RosterSheetState();
}

class _RosterSheetState extends State<_RosterSheet> {
  bool _isLoading = true;
  List<AtletaRoster> _atletas = [];
  List<EquipeStaff> _staff = [];
  List<AtleticaMembro> _elencoDisponivel = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final hasTeam = widget.campeonatoTime.id.isNotEmpty;
      final results = await Future.wait([
        hasTeam
            ? widget.timeService.getAtletasDoCampeonatoTime(
                widget.campeonatoTime.id,
              )
            : Future.value(<AtletaRoster>[]),
        widget.membroService.getMembros(widget.minhaAtletica.atleticaId!),
        hasTeam 
            ? widget.timeService.getStaffDoCampeonatoTime(
                widget.campeonatoTime.id,
              )
            : Future.value(<EquipeStaff>[]),
      ]);
      setState(() {
        _atletas = results[0] as List<AtletaRoster>;
        final allMembros = results[1] as List<AtleticaMembro>;
        _elencoDisponivel = allMembros
            .where((m) => m.papelCodigo == 'ATHLETE')
            .toList();
        _staff = results[2] as List<EquipeStaff>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editNumeroCamisa(AtletaRoster atleta) async {
    final controller = TextEditingController(
      text: atleta.numeroCamisa?.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Camisa'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Número da Camisa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await widget.timeService.atualizarNumeroCamisa(
          widget.campeonatoTime.id,
          atleta.id,
          result,
        );
        _load(); // Reload after update
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
        }
      }
    }
  }

  Future<void> _showAddStaffModal() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final cargoController = TextEditingController();
    UserProfile? selectedUser;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Adicionar Staff',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buscar Usuário (Opcional)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<UserProfile>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 3) {
                          return const Iterable<UserProfile>.empty();
                        }
                        return await ProfileService().searchProfiles(
                          textEditingValue.text,
                        );
                      },
                      displayStringForOption: (UserProfile option) =>
                          option.nomeExibicao,
                      onSelected: (UserProfile selection) {
                        selectedUser = selection;
                        nomeController.text = selection.nomeExibicao;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Digite o nome ou e-mail',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EDF5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EDF5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nomeController,
                      validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                      decoration: InputDecoration(
                        labelText: 'Nome do Staff',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cargoController,
                      validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                      decoration: InputDecoration(
                        labelText: 'Cargo (Ex: Treinador, Auxiliar)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);
                              try {
                                await widget.timeService.adicionarStaff(
                                  widget.campeonatoTime.id,
                                  userId: selectedUser?.id,
                                  nome: nomeController.text.trim(),
                                  cargo: cargoController.text.trim(),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                                _load();
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Erro: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,),
                            )
                          : const Text(
                              'ADICIONAR STAFF',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTeam = widget.campeonatoTime.id.isNotEmpty;
    final listCount = hasTeam ? _atletas.length : _elencoDisponivel.length;
    final isEmpty = hasTeam ? _atletas.isEmpty : _elencoDisponivel.isEmpty;

    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.campeonatoTime.nome ??
                          widget.campeonatoTime.modalidadeNome ??
                          'Time',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.secondary,
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Atletas'),
                Tab(text: 'Staff'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Atletas
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        )
                      : isEmpty
                      ? Center(
                          child: Text(
                            hasTeam
                                ? 'Nenhum atleta inscrito neste time.'
                                : 'Nenhum atleta cadastrado na atlética.',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: listCount,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            if (!hasTeam) {
                              final m = _elencoDisponivel[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: m.fotoUrl != null
                                      ? NetworkImage(m.fotoUrl!)
                                      : null,
                                  child: m.fotoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.textMuted,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  m.nomeExibicao ?? m.email ?? 'Sem Nome',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }

                            final a = _atletas[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surface,
                                backgroundImage: a.fotoUrl != null
                                    ? NetworkImage(a.fotoUrl!)
                                    : null,
                                child: a.fotoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: AppColors.textMuted,
                                      )
                                    : null,
                              ),
                              title: Text(
                                a.nome,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (a.numeroCamisa != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${a.numeroCamisa}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => _editNumeroCamisa(a),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  
                  // Tab 2: Staff
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: _staff.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Nenhum staff cadastrado.',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _staff.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, i) {
                                        final s = _staff[i];
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: const CircleAvatar(
                                            backgroundColor: AppColors.surface,
                                            child: Icon(
                                              Icons.badge,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          title: Text(
                                            s.nome,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Text(
                                            s.cargo,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            if (hasTeam)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton.icon(
                                  onPressed: _showAddStaffModal,
                                  icon: const Icon(Icons.person_add, color: Colors.white),
                                  label: const Text(
                                    'ADICIONAR STAFF',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
