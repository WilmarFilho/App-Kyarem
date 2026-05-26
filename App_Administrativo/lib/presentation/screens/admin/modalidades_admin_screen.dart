import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'modalidade_detalhe_screen.dart';
import 'modalidade_form_screen.dart';

class ModalidadesAdminScreen extends StatefulWidget {
  final AdminApiService? apiService;

  const ModalidadesAdminScreen({super.key, this.apiService});

  @override
  State<ModalidadesAdminScreen> createState() => _ModalidadesAdminScreenState();
}

class _ModalidadesAdminScreenState extends State<ModalidadesAdminScreen>
    with SingleTickerProviderStateMixin {
  static const int _itensPorPagina = 8;
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  List<ModalidadeCatalogo> _modalidades = [];
  List<Campeonato> _campeonatosEmAndamento = [];
  Map<String, Set<String>> _campeonatosPorModalidade = {};
  bool _isLoading = true;
  late AnimationController _animController;
  _FiltroModo _filtroModo = _FiltroModo.genero;
  String _generoSelecionado = 'TODAS';
  String _campeonatoSelecionado = 'TODOS';
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _carregar();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final lista = await _api.listarModalidadesCatalogo();
    final campeonatos = await _api.listarCampeonatos();
    final associacoes = await Future.wait(
      lista.map(
        (modalidade) => _api.listarAssociacoesModalidadeCatalogo(modalidade.id),
      ),
    );
    if (!mounted) return;
    final campeonatosPorModalidade = <String, Set<String>>{};
    for (var i = 0; i < lista.length; i++) {
      final modalidade = lista[i];
      final itens = associacoes[i];
      campeonatosPorModalidade[modalidade.id] = itens
          .map((item) => item.campeonatoId)
          .where((id) => id.isNotEmpty)
          .toSet();
    }
    final campeonatosEmAndamento =
        campeonatos
            .where(
              (campeonato) => _statusCampeonato(campeonato) == 'em_andamento',
            )
            .toList()
          ..sort(
            (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
          );
    setState(() {
      _modalidades = lista.cast<ModalidadeCatalogo>();
      _campeonatosPorModalidade = campeonatosPorModalidade;
      _campeonatosEmAndamento = campeonatosEmAndamento;
      if (_campeonatoSelecionado != 'TODOS' &&
          !_campeonatosEmAndamento.any((c) => c.id == _campeonatoSelecionado)) {
        _campeonatoSelecionado = 'TODOS';
      }
      _isLoading = false;
      _paginaAtual = 0;
    });
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _abrirFormulario({ModalidadeCatalogo? modalidade}) async {
    final isNew = modalidade == null;
    final result = await Navigator.push<ModalidadeCatalogo>(
      context,
      MaterialPageRoute(
        builder: (_) => ModalidadeFormScreen(modalidade: modalidade),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      await _carregar();
      if (isNew && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModalidadeDetalheScreen(modalidade: result),
          ),
        );
        if (mounted) {
          await _carregar();
        }
      }
    }
  }

  Future<void> _abrirDetalhe(ModalidadeCatalogo modalidade) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModalidadeDetalheScreen(modalidade: modalidade),
      ),
    );
    if (!mounted) return;
    await _carregar();
  }

  Future<void> _deletar(ModalidadeCatalogo modalidade) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Excluir modalidade?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja realmente excluir "${modalidade.nome}"?'),
            const SizedBox(height: 12),
            const Text(
              'Atenção: Esta ação apagará também todos os tipos de eventos, associações de campeonatos, inscrições e partidas vinculadas a essa modalidade.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir Tudo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    final ok = await _api.excluirModalidadeCatalogo(modalidade.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Modalidade excluída.' : 'Erro ao excluir.')),
    );
    if (ok) {
      await _carregar();
    }
  }

  List<_StatusOption> get _statusOptions {
    final options = <_StatusOption>[
      _StatusOption(
        value: 'TODAS',
        label: 'Todas',
        count: _modalidades.length,
        color: const Color(0xFFF85C39),
      ),
    ];

    final generosUnicos =
        _modalidades
            .map((m) {
              final g = m.genero.trim();
              return g.isEmpty ? 'indefinido' : g.toLowerCase();
            })
            .toSet()
            .toList()
          ..sort();

    for (final genero in generosUnicos) {
      final count = _modalidades.where((m) {
        final g = m.genero.trim();
        final val = g.isEmpty ? 'indefinido' : g.toLowerCase();
        return val == genero;
      }).length;
      final label = genero == 'indefinido'
          ? 'Indefinido'
          : genero
                .replaceAll('_', ' ')
                .split(' ')
                .map(
                  (w) => w.isEmpty
                      ? ''
                      : w[0].toUpperCase() + w.substring(1).toLowerCase(),
                )
                .join(' ');
      options.add(
        _StatusOption(
          value: genero,
          label: label,
          count: count,
          color: const Color(0xFFF85C39),
        ),
      );
    }

    return options;
  }

  List<_StatusOption> get _campeonatoOptions {
    final options = <_StatusOption>[
      _StatusOption(
        value: 'TODOS',
        label: 'Todos',
        count: _modalidades.length,
        color: const Color(0xFFF85C39),
      ),
    ];

    for (final campeonato in _campeonatosEmAndamento) {
      final count = _modalidades.where((modalidade) {
        final ids =
            _campeonatosPorModalidade[modalidade.id] ?? const <String>{};
        return ids.contains(campeonato.id);
      }).length;

      options.add(
        _StatusOption(
          value: campeonato.id,
          label: campeonato.nome,
          count: count,
          color: const Color(0xFFF85C39),
        ),
      );
    }

    return options;
  }

  List<ModalidadeCatalogo> get _modalidadesFiltradas {
    if (_filtroModo == _FiltroModo.genero) {
      if (_generoSelecionado == 'TODAS') return _modalidades;
      return _modalidades.where((m) {
        final g = m.genero.trim();
        final val = g.isEmpty ? 'indefinido' : g.toLowerCase();
        return val == _generoSelecionado;
      }).toList();
    }

    if (_campeonatoSelecionado == 'TODOS') return _modalidades;
    return _modalidades.where((modalidade) {
      final ids = _campeonatosPorModalidade[modalidade.id] ?? const <String>{};
      return ids.contains(_campeonatoSelecionado);
    }).toList();
  }

  int get _totalPaginas {
    if (_modalidadesFiltradas.isEmpty) return 1;
    return (_modalidadesFiltradas.length / _itensPorPagina).ceil();
  }

  List<ModalidadeCatalogo> get _modalidadesPaginadas {
    final inicio = _paginaAtual * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(
      0,
      _modalidadesFiltradas.length,
    );
    if (inicio >= _modalidadesFiltradas.length) {
      return const <ModalidadeCatalogo>[];
    }
    return _modalidadesFiltradas.sublist(inicio, fim);
  }

  void _selecionarGenero(String genero) {
    if (_generoSelecionado == genero) return;
    setState(() {
      _generoSelecionado = genero;
      _paginaAtual = 0;
    });
  }

  void _selecionarCampeonato(String campeonatoId) {
    if (_campeonatoSelecionado == campeonatoId) return;
    setState(() {
      _campeonatoSelecionado = campeonatoId;
      _paginaAtual = 0;
    });
  }

  void _alterarFiltroModo(_FiltroModo modo) {
    if (_filtroModo == modo) return;
    setState(() {
      _filtroModo = modo;
      _paginaAtual = 0;
      if (modo == _FiltroModo.campeonato &&
          _campeonatoSelecionado == 'TODOS' &&
          _campeonatoOptions.length > 1) {
        _campeonatoSelecionado = _campeonatoOptions[1].value;
      }
    });
  }

  void _mudarPagina(int pagina) {
    if (pagina < 0 || pagina >= _totalPaginas || pagina == _paginaAtual) {
      return;
    }
    setState(() => _paginaAtual = pagina);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MODALIDADES',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            Text(
              'Catálogo esportivo',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _modalidades.isEmpty
          ? Stack(
              children: [
                const Center(
                  child: Text(
                    'Nenhuma modalidade cadastrada',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Positioned(right: 16, bottom: 88, child: _buildFab()),
              ],
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _buildStatusFilterBar(),
                    Expanded(
                      child: _modalidadesFiltradas.isEmpty
                          ? Center(
                              child: Text(
                                _filtroModo == _FiltroModo.campeonato &&
                                        _campeonatosEmAndamento.isEmpty
                                    ? 'Nenhum campeonato em andamento para filtrar'
                                    : 'Nenhuma modalidade neste filtro',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                100,
                              ),
                              itemCount: _modalidadesPaginadas.length,
                              itemBuilder: (context, index) {
                                final animation = CurvedAnimation(
                                  parent: _animController,
                                  curve: Interval(
                                    (index * 0.08).clamp(0.0, 0.9),
                                    ((index * 0.08) + 0.5).clamp(0.1, 1.0),
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.15),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: _buildCard(
                                      _modalidadesPaginadas[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_modalidadesFiltradas.isNotEmpty) _buildPaginationBar(),
                  ],
                ),
                Positioned(right: 16, bottom: 88, child: _buildFab()),
              ],
            ),
    );
  }

  Widget _buildFab() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: const Color(0xFFF85C39),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nova modalidade',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ModalidadeCatalogo modalidade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
          child: const Icon(Icons.sports, color: Color(0xFFF85C39)),
        ),
        title: Text(
          modalidade.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${modalidade.esporteNome ?? 'Sem esporte'} · ${modalidade.genero}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _abrirFormulario(modalidade: modalidade),
              icon: Icon(Icons.edit_rounded, color: Colors.blue.shade400),
            ),
            IconButton(
              onPressed: () => _deletar(modalidade),
              icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
            ),
          ],
        ),
        onTap: () => _abrirDetalhe(modalidade),
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    final filtros = _filtroModo == _FiltroModo.genero
        ? _statusOptions
        : _campeonatoOptions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFFF85C39),
              ),
              const SizedBox(width: 8),
              Text(
                _filtroModo == _FiltroModo.genero
                    ? 'Filtrar por gênero'
                    : 'Filtrar por campeonato',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_modalidadesFiltradas.length} resultado(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF85C39).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFiltroModoButton(
                    label: 'Filtro por Gênero',
                    isSelected: _filtroModo == _FiltroModo.genero,
                    onTap: () => _alterarFiltroModo(_FiltroModo.genero),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFiltroModoButton(
                    label: 'Filtro por Campeonato',
                    isSelected: _filtroModo == _FiltroModo.campeonato,
                    onTap: () => _alterarFiltroModo(_FiltroModo.campeonato),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtros.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = filtros[index];
                final isSelected = _filtroModo == _FiltroModo.genero
                    ? item.value == _generoSelecionado
                    : item.value == _campeonatoSelecionado;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text('${item.label} (${item.count})'),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : item.color,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: item.color.withValues(alpha: 0.10),
                  selectedColor: item.color,
                  side: BorderSide(
                    color: isSelected
                        ? item.color
                        : item.color.withValues(alpha: 0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (_) => _filtroModo == _FiltroModo.genero
                      ? _selecionarGenero(item.value)
                      : _selecionarCampeonato(item.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroModoButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFF85C39) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFF85C39),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _statusCampeonato(Campeonato campeonato) {
    final status = campeonato.status?.trim() ?? '';
    return status.isEmpty ? 'indefinido' : status.toLowerCase();
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Página ${_paginaAtual + 1} de $_totalPaginas',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _paginaAtual > 0
                ? () => _mudarPagina(_paginaAtual - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
          const SizedBox(width: 8),
          ...List.generate(_totalPaginas, (index) {
            final isSelected = index == _paginaAtual;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _mudarPagina(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF85C39)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            onPressed: _paginaAtual < _totalPaginas - 1
                ? () => _mudarPagina(_paginaAtual + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  final String value;
  final String label;
  final int count;
  final Color color;

  _StatusOption({
    required this.value,
    required this.label,
    required this.count,
    required this.color,
  });
}

enum _FiltroModo { genero, campeonato }
