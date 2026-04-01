import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import '../../../services/admin_api_service.dart';
import '../../widgets/layout/gradient_background.dart';

class CampeonatoFormScreen extends StatefulWidget {
  final Campeonato? campeonato;

  const CampeonatoFormScreen({super.key, this.campeonato});

  @override
  State<CampeonatoFormScreen> createState() => _CampeonatoFormScreenState();
}

class _CampeonatoFormScreenState extends State<CampeonatoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  
  late TextEditingController _nomeController;
  late TextEditingController _nivelController;
  late TextEditingController _dataInicioController;
  late TextEditingController _dataFimController;
  late TextEditingController _escudoUrlController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.campeonato?.nome ?? '');
    _nivelController = TextEditingController(text: widget.campeonato?.nivel ?? '');
    _dataInicioController = TextEditingController(text: _formatDate(widget.campeonato?.dataInicio));
    _dataFimController = TextEditingController(text: _formatDate(widget.campeonato?.dataFim));
    _escudoUrlController = TextEditingController(text: widget.campeonato?.escudoUrl ?? '');
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'nome': _nomeController.text,
      'nivelCampeonato': _nivelController.text,
      'dataInicio': _dataInicioController.text.isNotEmpty ? _dataInicioController.text : null,
      'dataFim': _dataFimController.text.isNotEmpty ? _dataFimController.text : null,
      'escudoUrl': _escudoUrlController.text,
    };

    bool sucesso = false;
    if (widget.campeonato == null) {
      final res = await _apiService.criarCampeonato(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarCampeonato(widget.campeonato!.id, data);
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar.')));
      }
    }
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      controller.text = _formatDate(selecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.campeonato == null ? 'Novo Campeonato' : 'Editar Campeonato';

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
            child: SingleChildScrollView(
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
                        decoration: const InputDecoration(labelText: 'Nome do Campeonato'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nivelController,
                        decoration: const InputDecoration(labelText: 'Nível (ex: Ouro, A, etc)'),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _dataInicioController,
                        decoration: const InputDecoration(
                          labelText: 'Data de Início (YYYY-MM-DD)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selecionarData(_dataInicioController),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _dataFimController,
                        decoration: const InputDecoration(
                          labelText: 'Data de Fim (YYYY-MM-DD)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selecionarData(_dataFimController),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _escudoUrlController,
                        decoration: const InputDecoration(labelText: 'URL do Logo/Escudo (HTTPS)'),
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
