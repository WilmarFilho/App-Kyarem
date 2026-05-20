import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../../../services/admin_api_service.dart';
import 'partida_form_screen.dart';

class PartidasAdminScreen extends StatefulWidget {
  final bool canEdit;
  final String? atleticaId;
  final PartidaService? partidaService;
  final AdminApiService? adminApiService;

  const PartidasAdminScreen({
    super.key,
    this.canEdit = true,
    this.atleticaId,
    this.partidaService,
    this.adminApiService,
  });

  @override
  State<PartidasAdminScreen> createState() => _PartidasAdminScreenState();
}

class _PartidasAdminScreenState extends State<PartidasAdminScreen>
    with SingleTickerProviderStateMixin {
  static const int _itensPorPagina = 8;

  late final PartidaService _partidaService =
      widget.partidaService ?? PartidaService();
  late final AdminApiService _adminApiService =
      widget.adminApiService ?? AdminApiService();
  List<Partida> _partidas = [];
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
    _carregarPartidas();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarPartidas() async {
    setState(() => _isLoading = true);
    final lista = await _partidaService.listarTodasPartidas();

    // Se filtro por atlética informado, aplica localmente
    final filtradas = widget.atleticaId != null
        ? lista
              .where(
                (p) =>
                    p.equipeA?.atleticaId == widget.atleticaId ||
                    p.equipeB?.atleticaId == widget.atleticaId,
              )
              .toList()
        : lista;

    setState(() {
      _partidas = filtradas;
      _isLoading = false;
      _paginaAtual = 0;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _deletarPartida(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir Partida?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Essa ação não pode ser desfeita.'),
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
      final sucesso = await _adminApiService.excluirPartida(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sucesso ? 'Partida excluída!' : 'Erro ao excluir.'),
            backgroundColor: sucesso ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (sucesso) _carregarPartidas();
      }
    }
  }

  void _abrirFormulario({Partida? partida}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PartidaFormScreen(partida: partida)),
    );
    if (result == true) _carregarPartidas();
  }

  /// Só partidas com status 'agendada' podem ser editadas/excluídas e apenas pelo criador.
  bool _podeEditar(Partida p) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return p.status.toLowerCase() == 'agendada' && p.criadoPor == currentUserId;
  }

  /// Mensagem explicativa quando a edição não é permitida.
  String _motivoBloqueio(Partida p) {
    final s = p.status.toLowerCase();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (p.criadoPor != currentUserId) {
      return 'Você não pode editar partidas criadas por outros árbitros.';
    }
    if (s == 'finalizada' || s == 'fechada') {
      return 'Partida encerrada não pode ser editada.';
    }
    if (s == 'agendada') return '';
    return 'Partida em andamento não pode ser editada.';
  }

  void _tentarEditar(Partida p) {
    if (_podeEditar(p)) {
      _abrirFormulario(partida: p);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_motivoBloqueio(p))),
            ],
          ),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case '1° tempo':
      case '1º tempo':
      case '2° tempo':
      case '2º tempo':
      case 'intervalo':
      case 'prorrogação':
      case 'acréscimo':
        return Colors.green;
      case 'pênaltis':
        return const Color(0xFFF85C39);
      case 'finalizada':
        return Colors.grey;
      case 'fechada':
        return Colors.blueGrey;
      case 'pausada':
        return Colors.orange;
      default:
        return const Color(0xFF2563EB); // agendada
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case '1° tempo':
      case '1º tempo':
        return '1° Tempo';
      case '2° tempo':
      case '2º tempo':
        return '2° Tempo';
      case 'intervalo':
        return 'Intervalo';
      case 'prorrogação':
        return 'Prorrogação';
      case 'acréscimo':
        return 'Acréscimo';
      case 'pênaltis':
        return 'Pênaltis';
      case 'pausada':
        return 'Pausada';
      case 'finalizada':
        return 'Finalizada';
      case 'fechada':
        return 'Fechada';
      case 'agendada':
        return 'Agendada';
      default:
        return status;
    }
  }

  String get _screenTitle {
    if (!widget.canEdit && widget.atleticaId != null) return 'MINHAS PARTIDAS';
    if (!widget.canEdit) return 'PARTIDAS';
    return 'PARTIDAS';
  }

  String get _screenSubtitle {
    if (!widget.canEdit) return 'Somente leitura';
    return 'Gerenciamento';
  }

  List<_StatusOption> get _statusOptions {
    final options = <_StatusOption>[
      _StatusOption(
        value: 'TODAS',
        label: 'Todas',
        count: _partidas.length,
        color: const Color(0xFFF85C39),
      ),
    ];

    final statusOrdem = <String>[
      'agendada',
      '1Â° tempo',
      'intervalo',
      '2Â° tempo',
      'prorrogação',
      'acréscimo',
      'pausada',
      'pênaltis',
      'finalizada',
      'fechada',
    ];

    for (final status in statusOrdem) {
      final count = _partidas
          .where((partida) => _statusKey(partida.status) == status)
          .length;
      options.add(
        _StatusOption(
          value: status,
          label: _statusLabel(status),
          count: count,
          color: const Color(0xFFF85C39),
        ),
      );
    }

    return options;
  }

  List<Partida> get _partidasFiltradas {
    if (_statusSelecionado == 'TODAS') return _partidas;
    return _partidas
        .where((partida) => _statusKey(partida.status) == _statusSelecionado)
        .toList();
  }

  String _statusKey(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case '1º tempo':
        return '1° tempo';
      case '2º tempo':
        return '2° tempo';
      default:
        return normalized;
    }
  }

  int get _totalPaginas {
    if (_partidasFiltradas.isEmpty) return 1;
    return (_partidasFiltradas.length / _itensPorPagina).ceil();
  }

  List<Partida> get _partidasPaginadas {
    final inicio = _paginaAtual * _itensPorPagina;
    final fim = (inicio + _itensPorPagina).clamp(0, _partidasFiltradas.length);
    if (inicio >= _partidasFiltradas.length) {
      return const <Partida>[];
    }
    return _partidasFiltradas.sublist(inicio, fim);
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _screenTitle,
              style: const TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                Text(
                  _screenSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                if (!widget.canEdit) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ðŸ‘ Leitura',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      // FAB só aparece dentro do body após carregar
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _partidas.isEmpty
          ? Stack(
              children: [
                _buildEmptyState(),
                if (widget.canEdit)
                  Positioned(right: 16, bottom: 88, child: _buildFab()),
              ],
            )
          : Stack(
              children: [
                Column(
                  children: [
                    _buildStatusFilterBar(),
                    Expanded(
                      child: _partidasFiltradas.isEmpty
                          ? _buildEmptyState(
                              title: 'Nenhuma partida nesse status',
                              subtitle:
                                  'Tente outro filtro para ver mais resultados.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                100,
                              ),
                              itemCount: _partidasPaginadas.length,
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
                                    child: _buildPartidaCard(
                                      _partidasPaginadas[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_partidasFiltradas.isNotEmpty) _buildPaginationBar(),
                  ],
                ),
                if (widget.canEdit)
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
            'Nova Partida',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
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
                '${_partidasFiltradas.length} resultado(s)',
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

  Widget _buildPartidaCard(Partida p) {
    final nomeA = p.equipeA?.nome ?? 'Time A';
    final nomeB = p.equipeB?.nome ?? 'Time B';
    final modNome = p.modalidade?.nome ?? '';
    final statusColor = _statusColor(p.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
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
          // Em modo edição: abre formulário. Em leitura: expansão de detalhes (TODO futuro)
          onTap: widget.canEdit ? () => _tentarEditar(p) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho: status + modalidade + ações (só se canEdit)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(p.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (modNome.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        modNome,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Ações só visíveis para quem pode editar
                    if (widget.canEdit) ...[
                      // Editar â€” só se agendada
                      Tooltip(
                        message: _podeEditar(p)
                            ? 'Editar partida'
                            : _motivoBloqueio(p),
                        child: IconButton(
                          icon: Icon(
                            _podeEditar(p)
                                ? Icons.edit_rounded
                                : Icons.lock_outline,
                            color: _podeEditar(p)
                                ? Colors.blue.shade400
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () => _tentarEditar(p),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Excluir â€” só se agendada
                      Tooltip(
                        message: _podeEditar(p)
                            ? 'Excluir partida'
                            : 'Só partidas agendadas podem ser excluídas',
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            color: _podeEditar(p)
                                ? Colors.red.shade400
                                : Colors.grey.shade300,
                            size: 20,
                          ),
                          onPressed: _podeEditar(p)
                              ? () => _deletarPartida(p.id)
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Placar central com escudos
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildEscudo(
                            p.equipeA?.atleticaEscudoUrl,
                            statusColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nomeA,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Atlética do time A
                          if (p.equipeA?.atletica?.nome != null)
                            Text(
                              p.equipeA!.atletica!.nome,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(
                            '${p.placarA} Ã— ${p.placarB}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          if (p.agendadaPara != null)
                            Column(
                              children: [
                                Text(
                                  '${p.agendadaPara!.day.toString().padLeft(2, '0')}/${p.agendadaPara!.month.toString().padLeft(2, '0')}/${p.agendadaPara!.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  '${p.agendadaPara!.toLocal().hour.toString().padLeft(2, '0')}h${p.agendadaPara!.toLocal().minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildEscudo(
                            p.equipeB?.atleticaEscudoUrl,
                            Colors.grey.shade400,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nomeB,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (p.equipeB?.atletica?.nome != null)
                            Text(
                              p.equipeB!.atletica!.nome,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.local != null && p.local!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.local!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (p.fase != null && p.fase!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.fase!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEscudo(String? url, Color fallbackColor) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url), radius: 20);
    }
    return CircleAvatar(
      backgroundColor: fallbackColor.withValues(alpha: 0.1),
      radius: 20,
      child: Icon(Icons.sports_soccer, color: fallbackColor, size: 18),
    );
  }

  Widget _buildEmptyState({String? title, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title ??
                (widget.atleticaId != null
                    ? 'Nenhuma partida da sua atlética'
                    : 'Nenhuma Partida'),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle ??
                (widget.canEdit
                    ? 'Toque em "Nova Partida" para criar'
                    : 'Nenhuma partida agendada ainda'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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

  const _StatusOption({
    required this.value,
    required this.label,
    required this.count,
    required this.color,
  });
}
