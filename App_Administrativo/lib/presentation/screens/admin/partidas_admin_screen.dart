import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/partida_service.dart';
import '../../../services/admin_api_service.dart';
import 'partida_form_screen.dart';

class PartidasAdminScreen extends StatefulWidget {
  /// Se false, oculta botões de criação/edição/exclusão (modo somente leitura).
  final bool canEdit;

  /// Quando informado, filtra as partidas para mostrar apenas as da atlética.
  /// Usado pelo presidente_atletica para ver apenas as partidas do seu time.
  final String? atleticaId;

  const PartidasAdminScreen({super.key, this.canEdit = true, this.atleticaId});

  @override
  State<PartidasAdminScreen> createState() => _PartidasAdminScreenState();
}

class _PartidasAdminScreenState extends State<PartidasAdminScreen>
    with SingleTickerProviderStateMixin {
  final PartidaService _partidaService = PartidaService();
  final AdminApiService _adminApiService = AdminApiService();
  List<Partida> _partidas = [];
  bool _isLoading = true;
  late AnimationController _animController;

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

  /// Só partidas com status 'agendada' podem ser editadas/excluídas.
  bool _podeEditar(Partida p) => p.status.toLowerCase() == 'agendada';

  /// Mensagem explicativa quando a edição não é permitida.
  String _motivoBloqueio(Partida p) {
    final s = p.status.toLowerCase();
    if (s == 'finalizada' || s == 'fechada')
      return 'Partida encerrada não pode ser editada.';
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
      case '2° tempo':
      case 'intervalo':
      case 'prorrogação':
      case 'acréscimo':
        return Colors.green;
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
        return '1° Tempo';
      case '2° tempo':
        return '2° Tempo';
      case 'intervalo':
        return 'Intervalo';
      case 'prorrogação':
        return 'Prorrogação';
      case 'acréscimo':
        return 'Acréscimo';
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
                      '👁 Leitura',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarPartidas,
          ),
        ],
      ),
      // FAB só aparece se tiver permissão de edição
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: const Color(0xFFF85C39),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nova Partida',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _partidas.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _partidas.length,
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
                    child: _buildPartidaCard(_partidas[index]),
                  ),
                );
              },
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
                      // Editar — só se agendada
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
                      // Excluir — só se agendada
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
                            '${p.placarA} × ${p.placarB}',
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

  Widget _buildEmptyState() {
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
            widget.atleticaId != null
                ? 'Nenhuma partida da sua atlética'
                : 'Nenhuma Partida',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.canEdit
                ? 'Toque em "Nova Partida" para criar'
                : 'Nenhuma partida agendada ainda',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
