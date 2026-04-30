/*

import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../App_Administrativo/lib/services/admin_api_service.dart';
import 'atletica_form_screen.dart';

class AtleticasAdminScreen extends StatefulWidget {
  final String? minhaAtleticaId;
  final AdminApiService? apiService;

  const AtleticasAdminScreen({super.key, this.minhaAtleticaId, this.apiService});

  @override
  State<AtleticasAdminScreen> createState() => _AtleticasAdminScreenState();
}

class _AtleticasAdminScreenState extends State<AtleticasAdminScreen>
    with SingleTickerProviderStateMixin {
  late final AdminApiService _apiService = widget.apiService ?? AdminApiService();
  List<Atletica> _atleticas = [];
  bool _isLoading = true;
  late AnimationController _animController;

  bool get _modoPresidente => widget.minhaAtleticaId != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _carregarAtleticas();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarAtleticas() async {
    setState(() => _isLoading = true);

    List<Atletica> lista;
    if (_modoPresidente) {
      // Busca somente a atlética do presidente
      final atletica = await _apiService.buscarAtletica(
        widget.minhaAtleticaId!,
      );
      lista = atletica != null ? [atletica] : [];
    } else {
      lista = await _apiService.listarAtleticas();
    }

    setState(() {
      _atleticas = lista;
      _isLoading = false;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _deletarAtletica(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir Atlética?',
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
      final sucesso = await _apiService.excluirAtletica(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sucesso ? 'Atlética excluída!' : 'Erro ao excluir.'),
            backgroundColor: sucesso ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (sucesso) _carregarAtleticas();
      }
    }
  }

  void _abrirFormulario({Atletica? atletica}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AtleticaFormScreen(atletica: atletica)),
    );
    if (result == true) _carregarAtleticas();
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
              _modoPresidente ? 'MINHA ATLÉTICA' : 'ATLÉTICAS',
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
                  _modoPresidente ? 'Edição permitida' : 'Gerenciamento',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                if (_modoPresidente) ...[
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
                      '✏️ Sua atlética',
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
            onPressed: _carregarAtleticas,
          ),
        ],
      ),
      // FAB só aparece para admin/delegado, não para presidente
      floatingActionButton: _modoPresidente
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: const Color(0xFFF85C39),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nova',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF85C39)),
              )
            : _atleticas.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _atleticas.length,
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
                      child: _buildAtleticaCard(_atleticas[index]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAtleticaCard(Atletica a) {
    final cor = a.corPrincipal != null
        ? Color(
            int.tryParse('0xFF${a.corPrincipal!.replaceAll('#', '')}') ??
                0xFF2563EB,
          )
        : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.15),
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
          onTap: () => _abrirFormulario(atletica: a),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Escudo com cor da atlética
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    image: a.escudoUrl != null && a.escudoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(a.escudoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: a.escudoUrl == null || a.escudoUrl!.isEmpty
                      ? Icon(Icons.shield, color: cor, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (a.sigla != null && a.sigla!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                a.sigla!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (a.corPrincipal != null &&
                              a.corPrincipal!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: cor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Editar: disponível para todos (admin e presidente)
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                      onPressed: () => _abrirFormulario(atletica: a),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    // Excluir: apenas para admin/delegado, não para presidente
                    if (!_modoPresidente) ...[
                      const SizedBox(height: 8),
                      IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red.shade400,
                          size: 22,
                        ),
                        onPressed: () => _deletarAtletica(a.id, a.nome),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
    if (_modoPresidente) {
      // Estado especial para presidente sem atlética configurada
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 72, color: Colors.black38),
            const SizedBox(height: 16),
            const Text(
              'Atlética não encontrada',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seu perfil ainda não está vinculado\na uma atlética. Contate o administrador.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 72, color: Colors.black38),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma Atlética',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em "Nova" para cadastrar',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


*/
