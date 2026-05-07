import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../../services/admin_api_service.dart';
import '../../../services/partida_service.dart';
import '../../widgets/layout/gradient_background.dart';

class ArbitroDetalheScreen extends StatefulWidget {
  final Arbitro arbitro;
  final bool canEdit;

  const ArbitroDetalheScreen({
    super.key,
    required this.arbitro,
    this.canEdit = false,
  });

  @override
  State<ArbitroDetalheScreen> createState() => _ArbitroDetalheScreenState();
}

class _ArbitroDetalheScreenState extends State<ArbitroDetalheScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _api = AdminApiService();
  final PartidaService _partidaService = PartidaService();

  List<PartidaDoArbitro> _partidas = [];
  bool _isLoading = true;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _carregar();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final lista = await _api.listarPartidasDoArbitro(widget.arbitro.id);
    if (!mounted) return;
    setState(() {
      _partidas = lista;
      _isLoading = false;
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  List<PartidaDoArbitro> get _ativas =>
      _partidas.where((p) => p.isAtiva).toList();
  List<PartidaDoArbitro> get _encerradas =>
      _partidas.where((p) => p.isEncerrada).toList();

  // ── Desvincular via swipe ──────────────────────────────────────────────

  Future<void> _desvincular(PartidaDoArbitro pa) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Desvincular árbitro?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remover "${widget.arbitro.nome}" da partida ${pa.equipeANome ?? '?'} × ${pa.equipeBNome ?? '?'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Desvincular',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true && mounted) {
      final ok = await _api.desvincularArbitro(pa.partidaId, pa.vinculoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Árbitro desvinculado!' : 'Erro ao desvincular.'),
          backgroundColor: ok ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (ok) _carregar();
    }
  }

  // ── Bottom sheet: designar nova partida ──────────────────────────────

  Future<void> _abrirDesignarPartida() async {
    // Busca todas partidas agendadas
    final todasPartidas = await _partidaService.listarTodasPartidas();
    final agendadas = todasPartidas
        .where((p) => p.status.toLowerCase() == 'agendada')
        .toList();

    // Remove as que o árbitro já está vinculado
    final jaVinculadas = _partidas.map((pa) => pa.partidaId).toSet();
    final disponiveis = agendadas
        .where((p) => !jaVinculadas.contains(p.id))
        .toList();

    if (!mounted) return;

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma partida agendada disponível.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DesignarPartidaSheet(
        arbitro: widget.arbitro,
        disponiveis: disponiveis,
        onDesignar: (partidaId, funcao) async {
          Navigator.pop(ctx);
          final ok = await _api.vincularArbitro(
            partidaId,
            widget.arbitro.id,
            funcao,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Árbitro designado com sucesso!' : 'Erro ao designar.',
              ),
              backgroundColor: ok ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          if (ok) _carregar();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detalhes do Árbitro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _abrirDesignarPartida,
              backgroundColor: const Color(0xFFF85C39),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Designar Partida',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? Stack(
              children: [
                const GradientBackground(),
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ],
            )
          : Column(
              children: [
                // ── HEADER gradiente + card de perfil flutuante ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -56,
                      left: 16,
                      right: 16,
                      child: _buildPerfil(),
                    ),
                  ],
                ),

                const SizedBox(height: 64),

                // ── CONTEÚDO em fundo cinza claro ──
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSecao(
                            icon: Icons.play_circle_outline,
                            label: 'Ativas / Agendadas',
                            cor: Colors.green.shade600,
                            partidas: _ativas,
                            emptyMsg: 'Sem partidas ativas ou agendadas',
                          ),
                          const SizedBox(height: 20),
                          _buildSecao(
                            icon: Icons.check_circle_outline,
                            label: 'Encerradas',
                            cor: Colors.grey.shade600,
                            partidas: _encerradas,
                            emptyMsg: 'Sem partidas encerradas',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPerfil() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF85C39).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatarGrande(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.arbitro.nome,
                  style: const TextStyle(
                    color: Color(0xFF1a1a2e),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.arbitro.telefone != null &&
                    widget.arbitro.telefone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.arbitro.telefone!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statBadge(
                      '${_ativas.length}',
                      'Ativas',
                      Colors.green.shade600,
                      Colors.green.shade50,
                    ),
                    const SizedBox(width: 8),
                    _statBadge(
                      '${_encerradas.length}',
                      'Encerradas',
                      Colors.grey.shade600,
                      Colors.grey.shade100,
                    ),
                    const SizedBox(width: 8),
                    _statBadge(
                      '${_partidas.length}',
                      'Total',
                      const Color(0xFFF85C39),
                      const Color(0xFFF85C39).withValues(alpha: 0.08),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(
    String valor,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrande() {
    final a = widget.arbitro;
    if (a.fotoUrl != null && a.fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(a.fotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 34,
      backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
      child: Text(
        a.nome.isNotEmpty ? a.nome[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF85C39),
        ),
      ),
    );
  }

  Widget _buildSecao({
    required IconData icon,
    required String label,
    required Color cor,
    required List<PartidaDoArbitro> partidas,
    required String emptyMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: cor),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1a1a2e),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${partidas.length}',
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (partidas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                emptyMsg,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          )
        else
          ...partidas.map((pa) => _buildPartidaTile(pa, cor)),
      ],
    );
  }

  Widget _buildPartidaTile(PartidaDoArbitro pa, Color cor) {
    final nomeA = pa.equipeANome ?? 'Time A';
    final nomeB = pa.equipeBNome ?? 'Time B';

    return Dismissible(
      key: Key(pa.vinculoId),
      direction: widget.canEdit
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        await _desvincular(pa);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.link_off, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + modalidade + função
              Row(
                children: [
                  _statusBadge(pa.status),
                  const SizedBox(width: 6),
                  if (pa.modalidadeNome != null)
                    Expanded(
                      child: Text(
                        pa.modalidadeNome!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 4),
                  _funcaoBadge(pa.funcao),
                ],
              ),
              const SizedBox(height: 12),

              // Times + placar/data
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nomeA,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1a1a2e),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pa.isAtiva && pa.status.toLowerCase() != 'agendada'
                          ? '${pa.placarA} × ${pa.placarB}'
                          : pa.agendadaPara != null
                          ? _formatarData(pa.agendadaPara!)
                          : 'vs',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1a2e),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      nomeB,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1a1a2e),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Local + fase
              if ((pa.local != null && pa.local!.isNotEmpty) ||
                  (pa.fase != null && pa.fase!.isNotEmpty)) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (pa.local != null && pa.local!.isNotEmpty) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pa.local!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                      if (pa.fase != null && pa.fase!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.flag_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pa.fase!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (widget.canEdit && pa.isAtiva) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.swipe_left_outlined,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Deslize para desvincular',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    String label;
    Color cor;
    switch (status.toLowerCase()) {
      case 'agendada':
        label = 'Agendada';
        cor = const Color(0xFF2563EB);
        break;
      case 'finalizada':
        label = 'Finalizada';
        cor = Colors.grey.shade600;
        break;
      case 'fechada':
        label = 'Fechada';
        cor = Colors.grey.shade700;
        break;
      default:
        label = 'Ao Vivo';
        cor = Colors.green.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _funcaoBadge(String funcao) {
    final label = _rotuloFuncao(funcao);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF85C39).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF85C39).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFF85C39),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}h${local.minute.toString().padLeft(2, '0')}';
  }

  String _rotuloFuncao(String funcao) {
    switch (funcao.trim().toUpperCase()) {
      case 'PRINCIPAL':
        return 'Árbitro principal';
      case 'AUXILIAR':
        return 'Árbitro auxiliar';
      case 'MESARIO':
        return 'Mesário';
      case 'DELEGADO':
        return 'Delegado';
      case 'CRONOMETRISTA':
        return 'Cronometrista';
      default:
        return funcao;
    }
  }
}

// ── Bottom Sheet de Designação ──────────────────────────────────────────────

class _DesignarPartidaSheet extends StatefulWidget {
  final Arbitro arbitro;
  final List<Partida> disponiveis;
  final void Function(String partidaId, String funcao) onDesignar;

  const _DesignarPartidaSheet({
    required this.arbitro,
    required this.disponiveis,
    required this.onDesignar,
  });

  @override
  State<_DesignarPartidaSheet> createState() => _DesignarPartidaSheetState();
}

class _DesignarPartidaSheetState extends State<_DesignarPartidaSheet> {
  Partida? _partidaSelecionada;
  String _funcao = 'PRINCIPAL';
  final TextEditingController _buscaCtrl = TextEditingController();
  List<Partida> _filtradas = [];

  static const List<_FuncaoArbitragemOption> _funcoes = [
    _FuncaoArbitragemOption(
      value: 'PRINCIPAL',
      label: 'Árbitro principal',
      subtitle: 'Responsável pela condução principal da partida.',
      icon: Icons.workspace_premium_outlined,
    ),
    _FuncaoArbitragemOption(
      value: 'AUXILIAR',
      label: 'Árbitro auxiliar',
      subtitle: 'Apoia decisões e controle lateral da partida.',
      icon: Icons.assistant_direction_outlined,
    ),
    _FuncaoArbitragemOption(
      value: 'MESARIO',
      label: 'Mesário',
      subtitle: 'Registra eventos e acompanha a súmula.',
      icon: Icons.fact_check_outlined,
    ),
    _FuncaoArbitragemOption(
      value: 'DELEGADO',
      label: 'Delegado',
      subtitle: 'Supervisiona a operação e a organização da partida.',
      icon: Icons.verified_user_outlined,
    ),
    _FuncaoArbitragemOption(
      value: 'CRONOMETRISTA',
      label: 'Cronometrista',
      subtitle: 'Controla tempo, pausas e retomadas do jogo.',
      icon: Icons.timer_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filtradas = widget.disponiveis;
    _buscaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _buscaCtrl.text.trim().toLowerCase();
    setState(() {
      _filtradas = q.isEmpty
          ? widget.disponiveis
          : widget.disponiveis.where((p) {
              final a = p.equipeA?.nome.toLowerCase() ?? '';
              final b = p.equipeB?.nome.toLowerCase() ?? '';
              final mod = p.modalidade?.nome.toLowerCase() ?? '';
              return a.contains(q) || b.contains(q) || mod.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_ind_outlined,
                    color: Color(0xFFF85C39),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Designar Partida',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          widget.arbitro.nome,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Busca
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _buscaCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar partida...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF85C39)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF85C39).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF85C39).withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Função na partida',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A3A24),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _funcoes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final item = _funcoes[index];
                          final isSelected = item.value == _funcao;
                          return ChoiceChip(
                            selected: isSelected,
                            label: Text(item.label),
                            avatar: Icon(
                              item.icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFF85C39),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF8A3A24),
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: const Color(0xFFF85C39),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFF85C39)
                                  : const Color(
                                      0xFFF85C39,
                                    ).withValues(alpha: 0.20),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (_) {
                              setState(() => _funcao = item.value);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _buildFuncaoPreview(
                        _funcoes.firstWhere((item) => item.value == _funcao),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de partidas
            Expanded(
              child: _filtradas.isEmpty
                  ? const Center(child: Text('Nenhuma partida disponível'))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: _filtradas.length,
                      itemBuilder: (_, i) {
                        final p = _filtradas[i];
                        final selecionada = _partidaSelecionada?.id == p.id;
                        final nomeA = p.equipeA?.nome ?? 'Time A';
                        final nomeB = p.equipeB?.nome ?? 'Time B';
                        return GestureDetector(
                          onTap: () => setState(() => _partidaSelecionada = p),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selecionada
                                  ? const Color(
                                      0xFFF85C39,
                                    ).withValues(alpha: 0.08)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selecionada
                                    ? const Color(0xFFF85C39)
                                    : Colors.grey.shade200,
                                width: selecionada ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (selecionada)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFF85C39),
                                    size: 18,
                                  )
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.grey.shade400,
                                    size: 18,
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$nomeA × $nomeB',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (p.modalidade?.nome != null)
                                        Text(
                                          p.modalidade!.nome,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      if (p.agendadaPara != null)
                                        Text(
                                          _fmt(p.agendadaPara!),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Botão confirmar
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _partidaSelecionada == null
                      ? null
                      : () =>
                            widget.onDesignar(_partidaSelecionada!.id, _funcao),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF85C39),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Confirmar Designação',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} ${l.hour.toString().padLeft(2, '0')}h${l.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFuncaoPreview(_FuncaoArbitragemOption funcao) {
    return Container(
      key: ValueKey(funcao.value),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF85C39).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(funcao.icon, color: const Color(0xFFF85C39), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  funcao.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2430),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  funcao.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FuncaoArbitragemOption {
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;

  const _FuncaoArbitragemOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}
