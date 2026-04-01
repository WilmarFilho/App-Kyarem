import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
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

  List<Atletica> _atleticas = [];
  List<Campeonato> _campeonatos = [];
  List<dynamic> _modalidades = [];

  String? _selectedAtleticaId;
  String? _selectedCampeonatoId;
  String? _selectedModalidadeId;

  bool _isLoading = true;
  bool _isLoadingModalidades = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.equipe?.nome ?? '');
    _selectedAtleticaId = widget.equipe?.atletica?.id;
    _selectedCampeonatoId = widget.equipe?.campeonato?.id;
    _selectedModalidadeId = widget.equipe?.modalidade?.id;

    _carregarDadosBase();
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
        if (_selectedModalidadeId != null && !_modalidades.any((m) => m['id'] == _selectedModalidadeId)) {
          _selectedModalidadeId = null;
        }

        _isLoadingModalidades = false;
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAtleticaId == null || _selectedCampeonatoId == null || _selectedModalidadeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione Atlética, Campeonato e Modalidade.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar Time.')));
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF85C39)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
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
                          return DropdownMenuItem(value: a.id, child: Text(a.nome, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedAtleticaId = v),
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
                          return DropdownMenuItem(value: c.id, child: Text(c.nome));
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
                          return DropdownMenuItem<String>(value: m['id'], child: Text(m['nome']));
                        }).toList(),
                        onChanged: _isLoadingModalidades ? null : (v) => setState(() => _selectedModalidadeId = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                        hint: Text(_isLoadingModalidades 
                                     ? 'Carregando modalidades...' 
                                     : (_campeonatos.isEmpty || _selectedCampeonatoId == null 
                                         ? 'Selecione o Campeonato primeiro' 
                                         : 'Selecione a Modalidade')),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF85C39),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
