import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'atletica_detalhe_screen.dart';
import 'atletica_form_screen.dart';

class AtleticasAdminScreen extends StatefulWidget {
  final AdminApiService? apiService;

  const AtleticasAdminScreen({super.key, this.apiService});

  @override
  State<AtleticasAdminScreen> createState() => _AtleticasAdminScreenState();
}

class _AtleticasAdminScreenState extends State<AtleticasAdminScreen>
    with SingleTickerProviderStateMixin {
  static const int _itensPorPagina = 8;
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  List<Atletica> _atleticas = [];
  bool _isLoading = true;
  late AnimationController _animController;
  String _statusSelecionado = 'TODAS';
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
    final lista = await _api.listarAtleticas();
    if (!mounted) return;
    setState(() {
      _atleticas = lista;
      _isLoading = false;
      _paginaAtual = 0;
      _statusSelecionado = 'TODAS';
    });
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _abrirFormulario({Atletica? atletica}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AtleticaFormScreen(atletica: atletica),
      ),
    );
    if (result == true) {
      await _carregar();
    }
  }

  Future<void> _abrirDetalhe(Atletica atletica) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AtleticaDetalheScreen(atletica: atletica),
      ),
    );
    await _carregar();
  }

  Future<void> _deletar(Atletica atletica) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir atlética?'),
        content: Text('Deseja excluir "${atletica.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    final ok = await _api.excluirAtletica(atletica.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Atlética excluída.' : 'Erro ao excluir.')),
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
        count: _atleticas.length,
        color: const Color(0xFFF85C39),
      ),
    ];

    final statusUnicos = _atleticas
        .map((a) {
          final s = a.status?.trim() ?? '';
          return s.isEmpty ? 'indefinido' : s.toLowerCase();
        })
        .toSet()
        .toList()
      ..sort();

    for (final status in statusUnicos) {
      final count = _atleticas.where((a) {
        final s = a.status?.trim() ?? '';
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

  List<Atletica> get _atleticasFiltradas {
    if (_statusSelecionado == 'TODAS') return _atleticas;
    return _atleticas.where((a) {
      final s = a.status?.trim() ?? '';
      final val = s.isEmpty ? 'indefinido' : s.toLowerCase();
      return val == _statusSelecionado;
    }).toList();
  }

  int get _totalPaginas {
    if (_atleticasFiltradas.isEmpty) return 1;
    return (_atleticasFiltradas.length / _itensPorPagina).ceil();
  }

  List<Atletica> get _atleticasPaginadas {
    final inicio = _paginaAtual * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(
      0,
      _atleticasFiltradas.length,
    );
    if (inicio >= _atleticasFiltradas.length) {
      return const <Atletica>[];
    }
    return _atleticasFiltradas.sublist(inicio, fim);
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
              'ATLÉTICAS',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            Text(
              'Gestão administrativa',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: const Color(0xFFF85C39),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nova atlética',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _atleticas.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma atlética cadastrada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          : Column(
              children: [
                _buildStatusFilterBar(),
                Expanded(
                  child: _atleticasFiltradas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma atlética neste filtro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          itemCount: _atleticasPaginadas.length,
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
                                child: _buildCard(_atleticasPaginadas[index]),
                              ),
                            );
                          },
                        ),
                ),
                if (_atleticasFiltradas.isNotEmpty) _buildPaginationBar(),
              ],
            ),
    );
  }

  Widget _buildCard(Atletica atletica) {
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
          backgroundImage: atletica.escudoUrl != null && atletica.escudoUrl!.isNotEmpty
              ? NetworkImage(atletica.escudoUrl!)
              : null,
          child: atletica.escudoUrl == null || atletica.escudoUrl!.isEmpty
              ? Text(
                  atletica.sigla?.isNotEmpty == true
                      ? atletica.sigla!.substring(0, 1).toUpperCase()
                      : atletica.nome.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFF85C39),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          atletica.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(atletica.sigla ?? 'Sem sigla'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _abrirFormulario(atletica: atletica),
              icon: Icon(Icons.edit_rounded, color: Colors.blue.shade400),
            ),
            IconButton(
              onPressed: () => _deletar(atletica),
              icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
            ),
          ],
        ),
        onTap: () => _abrirDetalhe(atletica),
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
                '${_atleticasFiltradas.length} resultado(s)',
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
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
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
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
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
