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
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  List<Atletica> _atleticas = [];
  bool _isLoading = true;
  late AnimationController _animController;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova atlética',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _atleticas.length,
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
                    child: _buildCard(_atleticas[index]),
                  ),
                );
              },
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
}
