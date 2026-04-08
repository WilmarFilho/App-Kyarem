import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import '../../../services/admin_api_service.dart';
import 'arbitro_detalhe_screen.dart';

class ArbitrosAdminScreen extends StatefulWidget {
  final bool canEdit;
  final AdminApiService? apiService;
  const ArbitrosAdminScreen({super.key, this.canEdit = false, this.apiService});

  @override
  State<ArbitrosAdminScreen> createState() => _ArbitrosScreenState();
}

class _ArbitrosScreenState extends State<ArbitrosAdminScreen>
    with SingleTickerProviderStateMixin {
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Arbitro> _todos = [];
  List<Arbitro> _filtrados = [];
  bool _isLoading = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _searchCtrl.addListener(_filtrar);
    _carregar();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final lista = await _api.listarArbitros();
    if (!mounted) return;
    setState(() {
      _todos = lista;
      _filtrados = lista;
      _isLoading = false;
    });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _filtrar() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? _todos
          : _todos.where((a) => a.nome.toLowerCase().contains(q)).toList();
    });
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
            const Text(
              'ÁRBITROS',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Gestão de arbitragem',
                  style: TextStyle(
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
            onPressed: _carregar,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── BARRA DE BUSCA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Color(0xFF1a1a2e)),
                  decoration: InputDecoration(
                    hintText: 'Buscar árbitro...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── LISTA ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF85C39),
                      ),
                    )
                  : _filtrados.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filtrados.length,
                      itemBuilder: (context, index) {
                        final delay = index * 0.07;
                        final anim = CurvedAnimation(
                          parent: _animCtrl,
                          curve: Interval(
                            delay.clamp(0.0, 0.9),
                            (delay + 0.5).clamp(0.1, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(anim),
                            child: _buildCard(_filtrados[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Arbitro arbitro) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArbitroDetalheScreen(arbitro: arbitro, canEdit: widget.canEdit),
          ),
        );
        _carregar();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(arbitro),
              const SizedBox(width: 14),
              // Nome
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arbitro.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (arbitro.telefone != null &&
                        arbitro.telefone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              arbitro.telefone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Seta + Badge de árbitro
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF85C39).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.gavel,
                          size: 12,
                          color: Color(0xFFF85C39),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Árbitro',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF85C39),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Arbitro a) {
    if (a.fotoUrl != null && a.fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(a.fotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
      child: Text(
        a.nome.isNotEmpty ? a.nome[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF85C39),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Nenhum árbitro encontrado'
                : 'Nenhum árbitro cadastrado',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Árbitros com role="arbitro" aparecerão aqui',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
