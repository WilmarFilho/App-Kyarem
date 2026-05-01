import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/atletica_membro_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

class AtleticaDetalheScreen extends StatefulWidget {
  final Atletica atletica;

  const AtleticaDetalheScreen({super.key, required this.atletica});

  @override
  State<AtleticaDetalheScreen> createState() => _AtleticaDetalheScreenState();
}

class _AtleticaDetalheScreenState extends State<AtleticaDetalheScreen> {
  final AdminApiService _api = AdminApiService();
  bool _isLoading = true;
  List<AtleticaMembro> _membros = [];

  List<AtleticaMembro> get _presidentes => _membros
      .where((m) => m.papelCodigo.toUpperCase() == 'PRESIDENT')
      .toList();
  List<AtleticaMembro> get _dirigentes => _membros
      .where((m) => m.papelCodigo.toUpperCase() == 'DIRECTOR')
      .toList();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final membros = await _api.listarMembrosAtletica(widget.atletica.id);
    if (!mounted) return;
    setState(() {
      _membros = membros;
      _isLoading = false;
    });
  }

  Future<void> _abrirFluxoAdicionar(String papelCodigo) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final label = papelCodigo == 'PRESIDENT' ? 'presidente' : 'dirigente';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar ${label[0].toUpperCase()}${label.substring(1)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_search, color: Color(0xFFF85C39)),
                  title: const Text('Associar usuário existente'),
                  onTap: () => Navigator.pop(context, 'existing'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_add_alt_1, color: Color(0xFFF85C39)),
                  title: const Text('Criar usuário e associar'),
                  onTap: () => Navigator.pop(context, 'create'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || acao == null) return;
    if (acao == 'existing') {
      await _associarExistente(papelCodigo);
    } else {
      await _criarEAssociar(papelCodigo);
    }
  }

  Future<void> _associarExistente(String papelCodigo) async {
    final usuarios = await _api.listarProfiles();
    if (!mounted) return;
    String? selectedUserId;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Associar usuário'),
          content: DropdownButtonFormField<String>(
            value: selectedUserId,
            decoration: const InputDecoration(labelText: 'Usuário'),
            items: usuarios.map((user) {
              final id = user['id']?.toString() ?? '';
              final nome = user['nomeExibicao']?.toString() ?? 'Usuário';
              return DropdownMenuItem<String>(
                value: id,
                child: Text(nome),
              );
            }).toList(),
            onChanged: (value) => setStateModal(() => selectedUserId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Associar'),
            ),
          ],
        ),
      ),
    );

    if (confirmou != true || selectedUserId == null || !mounted) return;
    final membro = await _api.associarMembroAtletica(
      atleticaId: widget.atletica.id,
      userId: selectedUserId!,
      papelCodigo: papelCodigo,
    );
    if (!mounted) return;
    if (membro != null) {
      await _carregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível associar o usuário.')),
      );
    }
  }

  Future<void> _criarEAssociar(String papelCodigo) async {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    try {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Criar usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senhaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha inicial'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Criar e associar'),
            ),
          ],
        ),
      );

      if (confirmou != true || !mounted) return;
      final membro = await _api.criarEAssociarMembroAtletica(
        atleticaId: widget.atletica.id,
        nomeExibicao: nomeCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        senha: senhaCtrl.text.trim(),
        papelCodigo: papelCodigo,
      );
      if (!mounted) return;
      if (membro != null) {
        await _carregar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar o usuário.')),
        );
      }
    } finally {
      nomeCtrl.dispose();
      emailCtrl.dispose();
      senhaCtrl.dispose();
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
        title: const Text(
          'Atlética',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                _buildSection(
                  title: 'Presidência',
                  members: _presidentes,
                  actionLabel: 'Adicionar presidente',
                  onAdd: () => _abrirFluxoAdicionar('PRESIDENT'),
                ),
                const SizedBox(height: 18),
                _buildSection(
                  title: 'Diretoria',
                  members: _dirigentes,
                  actionLabel: 'Adicionar dirigente',
                  onAdd: () => _abrirFluxoAdicionar('DIRECTOR'),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
            backgroundImage: widget.atletica.escudoUrl != null &&
                    widget.atletica.escudoUrl!.isNotEmpty
                ? NetworkImage(widget.atletica.escudoUrl!)
                : null,
            child: widget.atletica.escudoUrl == null || widget.atletica.escudoUrl!.isEmpty
                ? Text(
                    widget.atletica.sigla?.isNotEmpty == true
                        ? widget.atletica.sigla!.substring(0, 1).toUpperCase()
                        : widget.atletica.nome.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF85C39),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.atletica.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (widget.atletica.sigla?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.atletica.sigla!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<AtleticaMembro> members,
    required String actionLabel,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Text(
              'Nenhum vínculo cadastrado ainda.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...members.map(_buildMemberTile),
        ],
      ),
    );
  }

  Widget _buildMemberTile(AtleticaMembro member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: member.fotoUrl != null && member.fotoUrl!.isNotEmpty
                ? NetworkImage(member.fotoUrl!)
                : null,
            child: member.fotoUrl == null || member.fotoUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nomeExibicao,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (member.email?.isNotEmpty == true)
                  Text(
                    member.email!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF85C39).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.papelLabel,
              style: const TextStyle(
                color: Color(0xFFF85C39),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
