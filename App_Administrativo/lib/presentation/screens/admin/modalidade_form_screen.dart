import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/esporte_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

class ModalidadeFormScreen extends StatefulWidget {
  final ModalidadeCatalogo? modalidade;

  const ModalidadeFormScreen({super.key, this.modalidade});

  @override
  State<ModalidadeFormScreen> createState() => _ModalidadeFormScreenState();
}

class _ModalidadeFormScreenState extends State<ModalidadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _api = AdminApiService();

  late final TextEditingController _nomeController;
  late final TextEditingController _slugController;
  late final TextEditingController _motorController;
  List<Esporte> _esportes = [];
  String? _selectedEsporteId;
  String _genero = 'MISTO';
  bool _ativo = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.modalidade?.nome ?? '');
    _slugController = TextEditingController(text: widget.modalidade?.slug ?? '');
    _motorController = TextEditingController(
      text: widget.modalidade?.motorRegras ?? '',
    );
    _selectedEsporteId = widget.modalidade?.esporteId;
    _genero = widget.modalidade?.genero ?? 'MISTO';
    _ativo = widget.modalidade?.ativo ?? true;
    _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _slugController.dispose();
    _motorController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final esportes = await _api.listarEsportes();
    if (!mounted) return;
    setState(() {
      _esportes = esportes;
      _selectedEsporteId ??= esportes.isNotEmpty ? esportes.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _selectedEsporteId == null) {
      return;
    }
    setState(() => _isSaving = true);
    final payload = {
      'esporteId': _selectedEsporteId,
      'nome': _nomeController.text.trim(),
      'slug': _slugController.text.trim(),
      'genero': _genero,
      'motorRegras': _motorController.text.trim(),
      'ativo': _ativo,
    };

    final result = widget.modalidade == null
        ? await _api.criarModalidadeCatalogo(payload)
        : await _api.atualizarModalidadeCatalogo(widget.modalidade!.id, payload);

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result != null) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao salvar modalidade.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.modalidade != null;
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
        title: Text(
          isEditing ? 'Editar Modalidade' : 'Nova Modalidade',
          style: const TextStyle(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedEsporteId,
                        decoration: _inputDecoration('Esporte'),
                        items: _esportes.map((esporte) {
                          return DropdownMenuItem<String>(
                            value: esporte.id,
                            child: Text(esporte.nome),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedEsporteId = value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nomeController,
                        decoration: _inputDecoration('Nome'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _slugController,
                        decoration: _inputDecoration('Slug'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _genero,
                        decoration: _inputDecoration('Gênero'),
                        items: const [
                          DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                          DropdownMenuItem(value: 'FEMININO', child: Text('Feminino')),
                          DropdownMenuItem(value: 'MISTO', child: Text('Misto')),
                        ],
                        onChanged: (value) => setState(() => _genero = value ?? 'MISTO'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _motorController,
                        decoration: _inputDecoration('Motor de regras'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: _ativo,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF85C39),
                        title: const Text('Modalidade ativa'),
                        onChanged: (value) => setState(() => _ativo = value),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF85C39),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isEditing ? 'Salvar alterações' : 'Criar modalidade',
                                  style: const TextStyle(
                                    color: Colors.white,
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: Color(0xFFF85C39)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF85C39), width: 1.5),
      ),
    );
  }
}
