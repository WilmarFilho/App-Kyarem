import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import '../../../services/admin_api_service.dart';
import 'campeonato_form_screen.dart';

class CampeonatosAdminScreen extends StatefulWidget {
  final AdminApiService? apiService;
  const CampeonatosAdminScreen({super.key, this.apiService});

  @override
  State<CampeonatosAdminScreen> createState() => _CampeonatosAdminScreenState();
}

class _CampeonatosAdminScreenState extends State<CampeonatosAdminScreen>
    with SingleTickerProviderStateMixin {
  static const int _itensPorPagina = 8;
  late final AdminApiService _apiService =
      widget.apiService ?? AdminApiService();
  List<Campeonato> _campeonatos = [];
  bool _isLoading = true;
  late AnimationController _animController;
  String _statusSelecionado = 'TODOS';
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _carregarCampeonatos();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarCampeonatos() async {
    setState(() => _isLoading = true);
    final lista = await _apiService.listarCampeonatos();
    setState(() {
      _campeonatos = lista;
      _isLoading = false;
      _paginaAtual = 0;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _deletarCampeonato(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir Campeonato?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja excluir "$nome"?\nEssa ação não pode ser desfeita.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await _apiService.excluirCampeonato(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sucesso ? 'Campeonato excluído!' : 'Erro ao excluir.',
            ),
            backgroundColor: sucesso ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (sucesso) _carregarCampeonatos();
      }
    }
  }

  void _abrirFormulario({Campeonato? campeonato}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampeonatoFormScreen(campeonato: campeonato),
      ),
    );
    if (result == true) _carregarCampeonatos();
  }

  List<_StatusOption> get _statusOptions {
    final options = <_StatusOption>[
      _StatusOption(
        value: 'TODOS',
        label: 'Todos',
        count: _campeonatos.length,
        color: const Color(0xFFF85C39),
      ),
    ];

    final statusUnicos =
        _campeonatos
            .map((c) {
              final s = c.status?.trim() ?? '';
              return s.isEmpty ? 'indefinido' : s.toLowerCase();
            })
            .toSet()
            .toList()
          ..sort();

    for (final status in statusUnicos) {
      final count = _campeonatos.where((c) {
        final s = c.status?.trim() ?? '';
        final val = s.isEmpty ? 'indefinido' : s.toLowerCase();
        return val == status;
      }).length;
      options.add(
        _StatusOption(
          value: status,
          label: status == 'indefinido' ? 'Indefinido' : status.toUpperCase(),
          count: count,
          color: Colors.blueGrey,
        ),
      );
    }

    return options;
  }

  List<Campeonato> get _campeonatosFiltrados {
    if (_statusSelecionado == 'TODOS') return _campeonatos;
    return _campeonatos.where((c) {
      final s = c.status?.trim() ?? '';
      final val = s.isEmpty ? 'indefinido' : s.toLowerCase();
      return val == _statusSelecionado;
    }).toList();
  }

  int get _totalPaginas {
    if (_campeonatosFiltrados.isEmpty) return 1;
    return (_campeonatosFiltrados.length / _itensPorPagina).ceil();
  }

  List<Campeonato> get _campeonatosPaginados {
    final inicio = _paginaAtual * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(
      0,
      _campeonatosFiltrados.length,
    );
    if (inicio >= _campeonatosFiltrados.length) {
      return const <Campeonato>[];
    }
    return _campeonatosFiltrados.sublist(inicio, fim);
  }

  void _selecionarStatus(String status) {
    if (_statusSelecionado == status) return;
    setState(() {
      _statusSelecionado = status;
      _paginaAtual = 0;
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAMPEONATOS',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Gerenciamento',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarCampeonatos,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: const Color(0xFFF85C39),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Novo Campeonato',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _campeonatos.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildStatusFilterBar(),
                Expanded(
                  child: _campeonatosFiltrados.isEmpty
                      ? _buildEmptyState(
                          title: 'Nenhum campeonato neste status',
                          subtitle: 'Tente outro filtro para ver resultados.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemCount: _campeonatosPaginados.length,
                          itemBuilder: (context, index) {
                            final delay = index * 0.08;
                            final animation = CurvedAnimation(
                              parent: _animController,
                              curve: Interval(
                                delay.clamp(0.0, 0.9),
                                (delay + 0.5).clamp(0.1, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: _buildCampeonatoCard(
                                  _campeonatosPaginados[index],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_campeonatosFiltrados.isNotEmpty) _buildPaginationBar(),
              ],
            ),
    );
  }

  Widget _buildCampeonatoCard(Campeonato c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirFormulario(campeonato: c),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Escudo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1.5,
                    ),
                    image: c.escudoUrl != null && c.escudoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(c.escudoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: c.escudoUrl == null || c.escudoUrl!.isEmpty
                      ? Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade700,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (c.nivel != null && c.nivel!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c.nivel!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (c.dataInicio != null)
                            Text(
                              '${c.dataInicio!.day.toString().padLeft(2, '0')}/${c.dataInicio!.month.toString().padLeft(2, '0')}/${c.dataInicio!.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                      onPressed: () => _abrirFormulario(campeonato: c),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                      onPressed: () => _deletarCampeonato(c.id, c.nome),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? title, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 72, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            title ?? 'Nenhum campeonato',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ?? 'Toque em "Novo" para criar o primeiro',
            style: const TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterBar() {
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
              const Text(
                'Filtrar por status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${_campeonatosFiltrados.length} resultado(s)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _statusOptions[index];
                final isSelected = item.value == _statusSelecionado;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text('${item.label} (${item.count})'),
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
                  onSelected: (_) => _selecionarStatus(item.value),
                );
              },
            ),
          ),
        ],
      ),
    );
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
