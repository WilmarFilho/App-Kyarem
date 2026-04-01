import 'package:flutter/material.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../../services/admin_api_service.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';

class AtletaFormScreen extends StatefulWidget {
  final Atleta? atleta;
  final String? atleticaIdSugerida;

  const AtletaFormScreen({super.key, this.atleta, this.atleticaIdSugerida});

  @override
  State<AtletaFormScreen> createState() => _AtletaFormScreenState();
}

class _AtletaFormScreenState extends State<AtletaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  
  late TextEditingController _nomeController;
  late TextEditingController _documentoController;
  late TextEditingController _cursoController;
  late TextEditingController _fotoUrlController;

  String? _selectedAtleticaId;
  List<Atletica> _atleticas = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atleta?.nome ?? '');
    _documentoController = TextEditingController(text: widget.atleta?.documentoIdentificacao ?? '');
    _cursoController = TextEditingController(text: widget.atleta?.curso ?? '');
    _fotoUrlController = TextEditingController(text: widget.atleta?.fotoUrl ?? '');

    _selectedAtleticaId = widget.atleta?.atletica?.id ?? widget.atleticaIdSugerida;
    
    _carregarAtleticas();
  }

  Future<void> _carregarAtleticas() async {
    final list = await _apiService.listarAtleticas();
    if (mounted) {
      setState(() {
        _atleticas = list;
        _isLoading = false;
        
        if (_selectedAtleticaId != null && !_atleticas.any((a) => a.id == _selectedAtleticaId)) {
          _selectedAtleticaId = null; 
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAtleticaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma Atlética.')));
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'atleticaId': _selectedAtleticaId,
      'nome': _nomeController.text,
      'documentoIdentificacao': _documentoController.text,
      'curso': _cursoController.text.isNotEmpty ? _cursoController.text : null,
      'fotoUrl': _fotoUrlController.text,
    };

    bool sucesso = false;
    if (widget.atleta == null) {
      final res = await _apiService.criarAtleta(data);
      sucesso = res != null;
    } else {
      // API Backend tem atualizar atleta? 
      // Caso não tenha, teremos que implementar ou limitar a edição aqui. 
      // Por enquanto, o backend tem DELETE, e CREATE. Vou mandar CREATE pra simplificar ou fechar com msg "Edição não suportada".
      // Vamos simular erro se tentar editar e não tiver endpoint:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edição de atleta ainda não disponível.')));
      setState(() => _isSaving = false);
      return;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar Atleta.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.atleta == null ? 'Novo Atleta' : 'Editar Atleta';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                        decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _documentoController,
                        decoration: const InputDecoration(labelText: 'Documento (RG/RA/CPF)', prefixIcon: Icon(Icons.badge)),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Vínculo (Atlética)', prefixIcon: Icon(Icons.shield)),
                        value: _selectedAtleticaId,
                        items: _atleticas.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text(a.nome));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedAtleticaId = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _cursoController,
                        decoration: const InputDecoration(labelText: 'Curso (Opcional)', prefixIcon: Icon(Icons.school)),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _fotoUrlController,
                        decoration: const InputDecoration(labelText: 'URL da Foto (Opcional)', prefixIcon: Icon(Icons.link)),
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
        ],
      ),
    );
  }
}
