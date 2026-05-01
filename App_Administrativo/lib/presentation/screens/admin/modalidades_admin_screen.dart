import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'modalidade_form_screen.dart';

class ModalidadesAdminScreen extends StatefulWidget {
  final AdminApiService? apiService;

  const ModalidadesAdminScreen({super.key, this.apiService});

  @override
  State<ModalidadesAdminScreen> createState() => _ModalidadesAdminScreenState();
}

class _ModalidadesAdminScreenState extends State<ModalidadesAdminScreen>
    with SingleTickerProviderStateMixin {
  late final AdminApiService _api = widget.apiService ?? AdminApiService();
  List<ModalidadeCatalogo> _modalidades = [];
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
    final lista = await _api.listarModalidadesCatalogo();
    if (!mounted) return;
    setState(() {
      _modalidades = lista.cast<ModalidadeCatalogo>();
      _isLoading = false;
    });
    _animController
      ..reset()
      ..forward();
  }

  Future<void> _abrirFormulario({ModalidadeCatalogo? modalidade}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ModalidadeFormScreen(modalidade: modalidade),
      ),
    );
    if (result == true) {
      await _carregar();
    }
  }

  Future<void> _deletar(ModalidadeCatalogo modalidade) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir modalidade?'),
        content: Text('Deseja excluir "${modalidade.nome}"?'),
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
    final ok = await _api.excluirModalidadeCatalogo(modalidade.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Modalidade excluída.' : 'Erro ao excluir.')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova modalidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : _modalidades.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma modalidade cadastrada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _modalidades.length,
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
                    child: _buildCard(_modalidades[index]),
                  ),
                );
              },
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
        onTap: () => _abrirFormulario(modalidade: modalidade),
      ),
    );
  }
}
