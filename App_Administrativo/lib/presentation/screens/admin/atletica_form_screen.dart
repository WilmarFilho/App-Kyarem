import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../../../services/admin_api_service.dart';
import '../../widgets/layout/gradient_background.dart';

class AtleticaFormScreen extends StatefulWidget {
  final Atletica? atletica;

  const AtleticaFormScreen({super.key, this.atletica});

  @override
  State<AtleticaFormScreen> createState() => _AtleticaFormScreenState();
}

class _AtleticaFormScreenState extends State<AtleticaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();
  
  late TextEditingController _nomeController;
  late TextEditingController _siglaController;
  late TextEditingController _corPrincipalController;
  late TextEditingController _escudoUrlController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atletica?.nome ?? '');
    _siglaController = TextEditingController(text: widget.atletica?.sigla ?? '');
    _corPrincipalController = TextEditingController(text: widget.atletica?.corPrincipal ?? '');
    _escudoUrlController = TextEditingController(text: widget.atletica?.escudoUrl ?? '');
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'nome': _nomeController.text,
      'sigla': _siglaController.text,
      'corPrincipal': _corPrincipalController.text.isNotEmpty ? _corPrincipalController.text : null,
      'escudoUrl': _escudoUrlController.text,
      // presidenteId opcional por enquanto
    };

    bool sucesso = false;
    if (widget.atletica == null) {
      final res = await _apiService.criarAtletica(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarAtletica(widget.atletica!.id, data);
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar Atlética.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.atletica == null ? 'Nova Atlética' : 'Editar Atlética';

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
                        decoration: const InputDecoration(labelText: 'Nome da Atlética'),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _siglaController,
                        decoration: const InputDecoration(labelText: 'Sigla (ex: AAAC)'),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _corPrincipalController,
                        decoration: const InputDecoration(labelText: 'Cor Principal (ex: #FF0000)'),
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
