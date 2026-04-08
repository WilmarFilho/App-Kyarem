import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/equipe_staff_model.dart';
import '../../../services/admin_api_service.dart';

class EquipeFormScreen extends StatefulWidget {
  final Equipe? equipe;

  const EquipeFormScreen({super.key, this.equipe});

  @override
  State<EquipeFormScreen> createState() => _EquipeFormScreenState();
}

class _EquipeFormScreenState extends State<EquipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();

  late TextEditingController _nomeController;
  late TextEditingController _staffNomeController;
  late TextEditingController _staffCargoController;

  List<Atletica> _atleticas = [];
  List<Campeonato> _campeonatos = [];
  List<dynamic> _modalidades = [];
  List<EquipeStaff> _staff = [];

  String? _selectedAtleticaId;
  String? _selectedCampeonatoId;
  String? _selectedModalidadeId;

  bool _isLoading = true;
  bool _isLoadingModalidades = false;
  bool _isSaving = false;
  bool _isLoadingStaff = false;
  bool _isSavingStaff = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.equipe?.nome ?? '');
    _staffNomeController = TextEditingController();
    _staffCargoController = TextEditingController();
    _selectedAtleticaId = widget.equipe?.atletica?.id;
    _selectedCampeonatoId = widget.equipe?.campeonato?.id;
    _selectedModalidadeId = widget.equipe?.modalidade?.id;

    _carregarDadosBase();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _staffNomeController.dispose();
    _staffCargoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosBase() async {
    setState(() => _isLoading = true);

    final atleticasResult = await _apiService.listarAtleticas();
    final campeonatosResult = await _apiService.listarCampeonatos();

    if (mounted) {
      setState(() {
        _atleticas = atleticasResult;
        _campeonatos = campeonatosResult;
      });
    }

    if (_selectedCampeonatoId != null) {
      await _carregarModalidades(_selectedCampeonatoId!);
    }

    if (widget.equipe != null) {
      await _carregarStaff();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarModalidades(String campeonatoId) async {
    final modalidadesResult = await _apiService.listarModalidades(campeonatoId);
    if (mounted) {
      setState(() {
        _modalidades = modalidadesResult;

        // Valida se a modalidade selecionada ainda existe na nova lista
        if (_selectedModalidadeId != null &&
            !_modalidades.any((m) => m['id'] == _selectedModalidadeId)) {
          _selectedModalidadeId = null;
        }

        _isLoadingModalidades = false;
      });
    }
  }

  Future<void> _carregarStaff() async {
    final equipeId = widget.equipe?.id;
    if (equipeId == null || equipeId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingStaff = true);
    }

    final staff = await _apiService.listarEquipeStaff(equipeId);

    if (mounted) {
      setState(() {
        _staff = staff;
        _isLoadingStaff = false;
      });
    }
  }

  void _onCampeonatoChanged(String? newId) {
    setState(() {
      _selectedCampeonatoId = newId;
      _selectedModalidadeId = null;
      _modalidades = [];
      _isLoadingModalidades = true;
    });
    if (newId != null) {
      _carregarModalidades(newId);
    } else {
      setState(() => _isLoadingModalidades = false);
    }
  }

  Future<void> _adicionarStaff() async {
    final equipeId = widget.equipe?.id;
    final nome = _staffNomeController.text.trim();
    final cargo = _staffCargoController.text.trim();

    if (equipeId == null || equipeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salve a equipe antes de cadastrar membros do staff.'),
        ),
      );
      return;
    }

    if (nome.isEmpty || cargo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e cargo do membro.')),
      );
      return;
    }

    setState(() => _isSavingStaff = true);

    final staffCriado = await _apiService.criarEquipeStaff({
      'equipe_id': equipeId,
      'nome': nome,
      'cargo': cargo,
    });

    if (!mounted) return;

    setState(() => _isSavingStaff = false);

    if (staffCriado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar membro do staff.')),
      );
      return;
    }

    _staffNomeController.clear();
    _staffCargoController.clear();
    FocusScope.of(context).unfocus();

    await _carregarStaff();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membro do staff cadastrado com sucesso.')),
    );
  }

  Future<void> _removerStaff(EquipeStaff membro) async {
    final remover = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text('Deseja remover ${membro.nome} do staff da equipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (remover != true) return;

    final equipeId = widget.equipe?.id;
    if (equipeId == null || equipeId.isEmpty) return;

    final sucesso = await _apiService.removerEquipeStaff(equipeId, membro.id);

    if (!mounted) return;

    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao remover membro do staff.')),
      );
      return;
    }

    await _carregarStaff();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membro removido com sucesso.')),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAtleticaId == null ||
        _selectedCampeonatoId == null ||
        _selectedModalidadeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione Atlética, Campeonato e Modalidade.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'atleticaId': _selectedAtleticaId,
      'campeonatoId': _selectedCampeonatoId,
      'modalidadeId': _selectedModalidadeId,
      'nomeEquipe': _nomeController.text,
    };

    bool sucesso = false;
    if (widget.equipe == null) {
      final res = await _apiService.criarEquipe(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarEquipe(widget.equipe!.id, data);
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao salvar Time.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.equipe == null ? 'NOVO TIME' : 'EDITAR TIME';

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
              title,
              style: const TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const Text(
              'Gerenciamento',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF85C39)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(22.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Time/Equipe',
                            prefixIcon: Icon(Icons.group),
                          ),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Atlética',
                            prefixIcon: Icon(Icons.shield),
                          ),
                          value: _selectedAtleticaId,
                          items: _atleticas.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                a.nome,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedAtleticaId = v),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Campeonato',
                            prefixIcon: Icon(Icons.emoji_events),
                          ),
                          value: _selectedCampeonatoId,
                          items: _campeonatos.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nome),
                            );
                          }).toList(),
                          onChanged: _onCampeonatoChanged,
                          validator: (v) => v == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Modalidade',
                            prefixIcon: Icon(Icons.sports),
                          ),
                          value: _selectedModalidadeId,
                          items: _modalidades.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'],
                              child: Text(m['nome']),
                            );
                          }).toList(),
                          onChanged: _isLoadingModalidades
                              ? null
                              : (v) =>
                                    setState(() => _selectedModalidadeId = v),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                          hint: Text(
                            _isLoadingModalidades
                                ? 'Carregando modalidades...'
                                : (_campeonatos.isEmpty ||
                                        _selectedCampeonatoId == null
                                    ? 'Selecione o Campeonato primeiro'
                                    : 'Selecione a Modalidade'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        _buildStaffSection(),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF85C39),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Salvar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStaffSection() {
    final isEditing = widget.equipe != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Color(0xFFF85C39)),
              SizedBox(width: 8),
              Text(
                'Staff da equipe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isEditing
                ? 'Cadastre comissao tecnica, coordenacao e demais membros vinculados a esta equipe.'
                : 'Depois de salvar a equipe, voce podera cadastrar os membros do staff aqui.',
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          if (isEditing) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _staffNomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do membro',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _staffCargoController,
              decoration: const InputDecoration(
                labelText: 'Cargo',
                prefixIcon: Icon(Icons.work_outline),
              ),
              onFieldSubmitted: (_) {
                if (!_isSavingStaff) {
                  _adicionarStaff();
                }
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSavingStaff ? null : _adicionarStaff,
                icon: _isSavingStaff
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(
                  _isSavingStaff ? 'Cadastrando...' : 'Cadastrar membro',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF85C39),
                  side: const BorderSide(color: Color(0xFFF85C39)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Membros cadastrados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_isLoadingStaff)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_isLoadingStaff && _staff.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Nenhum membro do staff cadastrado para esta equipe.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (_staff.isNotEmpty)
              ..._staff.map(
                (membro) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFDE7E1),
                        child: Text(
                          membro.nome.isNotEmpty
                              ? membro.nome[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFFF85C39),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        membro.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(membro.cargo),
                      trailing: IconButton(
                        tooltip: 'Remover membro',
                        onPressed: () => _removerStaff(membro),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
