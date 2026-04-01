import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../../../services/admin_api_service.dart';
import 'equipe_form_screen.dart';
import 'inscritos_equipe_screen.dart';

class EquipesAdminScreen extends StatefulWidget {
  const EquipesAdminScreen({super.key});

  @override
  State<EquipesAdminScreen> createState() => _EquipesAdminScreenState();
}

class _EquipesAdminScreenState extends State<EquipesAdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  List<Equipe> _equipes = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _carregarEquipes();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarEquipes() async {
    setState(() => _isLoading = true);
    final lista = await _apiService.listarEquipes();
    setState(() {
      _equipes = lista;
      _isLoading = false;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _deletarEquipe(String id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir Time?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Isso removerá o time "$nome" e todos os atletas inscritos.\nDeseja continuar?',
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
      final sucesso = await _apiService.excluirEquipe(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sucesso ? 'Time excluído!' : 'Erro ao excluir.'),
            backgroundColor: sucesso ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (sucesso) _carregarEquipes();
      }
    }
  }

  void _abrirFormulario({Equipe? equipe}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EquipeFormScreen(equipe: equipe)),
    );
    if (result == true) _carregarEquipes();
  }

  void _abrirInscritos(Equipe equipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InscritosEquipeScreen(equipe: equipe)),
    );
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TIMES',
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
            onPressed: _carregarEquipes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Time',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF85C39)),
              )
            : _equipes.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _equipes.length,
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
                      child: _buildEquipeCard(_equipes[index]),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEquipeCard(Equipe e) {
    final escudoUrl = e.atleticaEscudoUrl ?? e.atletica?.escudoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
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
          onTap: () => _abrirInscritos(e),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Escudo da atlética
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    image: escudoUrl != null && escudoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(escudoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: escudoUrl == null || escudoUrl.isEmpty
                      ? const Icon(
                          Icons.groups,
                          color: Color(0xFF7C3AED),
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
                        e.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.atletica?.nome ?? 'Sem Atlética',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (e.modalidade?.nome != null &&
                          e.modalidade!.nome.isNotEmpty)
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e.modalidade!.nome,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Ações
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.group_add,
                        color: Color(0xFF2E9E56),
                        size: 22,
                      ),
                      onPressed: () => _abrirInscritos(e),
                      tooltip: 'Atletas inscritos',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                      onPressed: () => _abrirFormulario(equipe: e),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                      onPressed: () => _deletarEquipe(e.id, e.nome),
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
          Icon(Icons.groups_outlined, size: 72, color: Colors.black38),
          const SizedBox(height: 16),
          const Text(
            'Nenhum Time',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em "Novo Time" para criar',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
