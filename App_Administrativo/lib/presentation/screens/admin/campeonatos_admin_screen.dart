import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import '../../../services/admin_api_service.dart';
import 'campeonato_form_screen.dart';

class CampeonatosAdminScreen extends StatefulWidget {
  const CampeonatosAdminScreen({super.key});

  @override
  State<CampeonatosAdminScreen> createState() => _CampeonatosAdminScreenState();
}

class _CampeonatosAdminScreenState extends State<CampeonatosAdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  List<Campeonato> _campeonatos = [];
  bool _isLoading = true;
  late AnimationController _animController;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _campeonatos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _campeonatos.length,
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
                    child: _buildCampeonatoCard(_campeonatos[index]),
                  ),
                );
              },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined, size: 72, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'Nenhum campeonato',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em "Novo" para criar o primeiro',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
