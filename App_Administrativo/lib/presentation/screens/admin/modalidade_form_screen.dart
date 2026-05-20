import 'dart:convert';

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
  final Map<String, Map<String, dynamic>> _defaultRulesByMotor = const {
    'GENERICO_V1': {
      'tempoPartidaMinutos': 20,
      'periodos': 2,
      'cronometroParado': true,
      'tipoPontuacao': 'GOLS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'FUTSAL_V1': {
      'tempoPartidaMinutos': 20,
      'periodos': 2,
      'cronometroParado': true,
      'tipoPontuacao': 'GOLS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': 5,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'VOLEI_V1': {
      'tempoPartidaMinutos': 0,
      'periodos': 3,
      'cronometroParado': false,
      'tipoPontuacao': 'SETS',
      'setsParaVencer': 3,
      'pontosPorSet': 25,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'BASQUETE_V1': {
      'tempoPartidaMinutos': 40,
      'periodos': 4,
      'cronometroParado': true,
      'tipoPontuacao': 'PONTOS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'HANDEBOL_V1': {
      'tempoPartidaMinutos': 60,
      'periodos': 2,
      'cronometroParado': true,
      'tipoPontuacao': 'GOLS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'SOCIETY_V1': {
      'tempoPartidaMinutos': 50,
      'periodos': 2,
      'cronometroParado': false,
      'tipoPontuacao': 'GOLS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
    'FUTEBOL_CAMPO_V1': {
      'tempoPartidaMinutos': 90,
      'periodos': 2,
      'cronometroParado': false,
      'tipoPontuacao': 'GOLS',
      'setsParaVencer': null,
      'pontosPorSet': null,
      'faltasColetivasLimite': null,
      'permiteProrrogacao': false,
      'permitePenaltis': false,
      'eventosPermitidos': null,
    },
  };
  final Map<String, List<_MotorOption>> _motorOptionsBySport = const {
    'futsal': [_MotorOption('FUTSAL_V1', 'Futsal')],
    'volei': [_MotorOption('VOLEI_V1', 'Volei')],
    'basquete': [_MotorOption('BASQUETE_V1', 'Basquete')],
    'handebol': [_MotorOption('HANDEBOL_V1', 'Handebol')],
    'futebol': [
      _MotorOption('SOCIETY_V1', 'Society'),
      _MotorOption('FUTEBOL_CAMPO_V1', 'Futebol de campo'),
    ],
    'default': [
      _MotorOption('GENERICO_V1', 'Generico'),
      _MotorOption('FUTSAL_V1', 'Futsal'),
      _MotorOption('VOLEI_V1', 'Volei'),
      _MotorOption('BASQUETE_V1', 'Basquete'),
      _MotorOption('HANDEBOL_V1', 'Handebol'),
      _MotorOption('SOCIETY_V1', 'Society'),
      _MotorOption('FUTEBOL_CAMPO_V1', 'Futebol de campo'),
    ],
  };

  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  List<Esporte> _esportes = [];
  String? _selectedEsporteId;
  String? _selectedMotorRegras;
  bool _ativo = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String _slug = '';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.modalidade?.nome ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.modalidade?.genero ?? '',
    );
    _selectedMotorRegras = widget.modalidade?.motorRegras;
    _selectedEsporteId = widget.modalidade?.esporteId;
    _ativo = widget.modalidade?.ativo ?? true;
    _slug = widget.modalidade?.slug ?? '';
    _nomeController.addListener(_sincronizarSlugAutomatico);
    _sincronizarSlugAutomatico();
    _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final esportes = await _api.listarEsportes();
    if (!mounted) return;
    final esporteInicial =
        _selectedEsporteId ?? (esportes.isNotEmpty ? esportes.first.id : null);
    setState(() {
      _esportes = esportes;
      _selectedEsporteId = esporteInicial;
      _selectedMotorRegras = _resolverMotorInicial(
        esporteId: esporteInicial,
        currentMotor: _selectedMotorRegras,
      );
      _isLoading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() ||
        _selectedEsporteId == null ||
        _selectedMotorRegras == null) {
      return;
    }
    setState(() => _isSaving = true);
    final payload = {
      'esporteId': _selectedEsporteId,
      'nome': _nomeController.text.trim(),
      'slug': _slug,
      'genero': _descricaoController.text.trim(),
      'motorRegras': _selectedMotorRegras,
      'motorConfigsDefault': _buildMotorConfigsDefault(_selectedMotorRegras),
      'ativo': _ativo,
    };

    final result = widget.modalidade == null
        ? await _api.criarModalidadeCatalogo(payload)
        : await _api.atualizarModalidadeCatalogo(
            widget.modalidade!.id,
            payload,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result != null) {
      Navigator.pop(context, result);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Erro ao salvar modalidade.')));
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Esporte base',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              _mostrarModalSelecao(
                                context: context,
                                titulo: 'Selecione o Esporte',
                                opcoes: _esportes
                                    .map(
                                      (e) => _OpcaoSelect(
                                        valor: e.id,
                                        rotulo: e.nome,
                                      ),
                                    )
                                    .toList(),
                                selecionado: _selectedEsporteId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEsporteId = value;
                                    _selectedMotorRegras =
                                        _resolverMotorInicial(
                                          esporteId: value,
                                          currentMotor: _selectedMotorRegras,
                                        );
                                  });
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _esportes
                                            .cast<Esporte?>()
                                            .firstWhere(
                                              (e) =>
                                                  e?.id == _selectedEsporteId,
                                              orElse: () => null,
                                            )
                                            ?.nome ??
                                        'Selecione',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nomeController,
                        decoration: _inputDecoration(
                          'Nome da modalidade',
                          helper: 'Ex.: Futsal, Society, Volei de Areia.',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obrigatorio'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descricaoController,
                        decoration: _inputDecoration(
                          'Descricao',
                          helper:
                              'Texto livre para explicar a modalidade no catalogo.',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Obrigatorio'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildSectionTitle('Configuracao da sumula'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modelo de jogo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              _mostrarModalSelecao(
                                context: context,
                                titulo: 'Selecione o Modelo',
                                opcoes: _motorOptionsForSelectedSport
                                    .map(
                                      (m) => _OpcaoSelect(
                                        valor: m.value,
                                        rotulo: m.label,
                                      ),
                                    )
                                    .toList(),
                                selecionado: _selectedMotorRegras,
                                onChanged: (value) => setState(
                                  () => _selectedMotorRegras = value,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _motorOptionsForSelectedSport
                                            .cast<_MotorOption?>()
                                            .firstWhere(
                                              (m) =>
                                                  m?.value ==
                                                  _selectedMotorRegras,
                                              orElse: () => null,
                                            )
                                            ?.label ??
                                        'Selecione',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _selectedMotorRegras == null
                              ? null
                              : () => _mostrarPreviewRegras(
                                  _selectedMotorRegras!,
                                ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver regras que serao preenchidas'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: _ativo,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: const Color(0xFFF85C39),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isEditing
                                      ? 'Salvar alterações'
                                      : 'Criar modalidade',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  List<_MotorOption> get _motorOptionsForSelectedSport {
    final esporte = _esportes.cast<Esporte?>().firstWhere(
      (item) => item?.id == _selectedEsporteId,
      orElse: () => null,
    );
    final key = _normalizarEsporte(esporte?.nome);
    return _motorOptionsBySport[key] ?? _motorOptionsBySport['default']!;
  }

  String? _resolverMotorInicial({
    required String? esporteId,
    required String? currentMotor,
  }) {
    final options = _optionsByEsporteId(esporteId);
    if (currentMotor != null &&
        options.any((item) => item.value == currentMotor)) {
      return currentMotor;
    }
    return options.first.value;
  }

  List<_MotorOption> _optionsByEsporteId(String? esporteId) {
    final esporte = _esportes.cast<Esporte?>().firstWhere(
      (item) => item?.id == esporteId,
      orElse: () => null,
    );
    final key = _normalizarEsporte(esporte?.nome);
    return _motorOptionsBySport[key] ?? _motorOptionsBySport['default']!;
  }

  void _sincronizarSlugAutomatico() {
    final generated = _slugify(_nomeController.text);
    if (_slug != generated) {
      setState(() => _slug = generated);
    }
  }

  String _slugify(String value) {
    var text = value.toLowerCase().trim();
    const replacements = {
      r'[áàãâä]': 'a',
      r'[éèêë]': 'e',
      r'[íìîï]': 'i',
      r'[óòõôö]': 'o',
      r'[úùûü]': 'u',
      r'[ç]': 'c',
    };
    replacements.forEach((pattern, replacement) {
      text = text.replaceAll(RegExp(pattern), replacement);
    });
    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    text = text.replaceAll(RegExp(r'^-+|-+$'), '');
    return text;
  }

  String _normalizarEsporte(String? nome) {
    final text = _slugify(nome ?? '');
    if (text.contains('futsal')) return 'futsal';
    if (text.contains('volei')) return 'volei';
    if (text.contains('basquete')) return 'basquete';
    if (text.contains('handebol')) return 'handebol';
    if (text.contains('futebol')) return 'futebol';
    return 'default';
  }

  Map<String, dynamic>? _buildMotorConfigsDefault(String? motor) {
    if (motor == null) return null;
    final defaults = _defaultRulesByMotor[motor];
    if (defaults == null) return null;
    return Map<String, dynamic>.from(defaults);
  }

  void _mostrarPreviewRegras(String motor) {
    final regras = _buildMotorConfigsDefault(motor) ?? const {};
    final descricao = _motorOptionsForSelectedSport
        .cast<_MotorOption?>()
        .firstWhere((m) => m?.value == motor, orElse: () => null)
        ?.label;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Regras base do modelo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              descricao == null ? motor : '$descricao ($motor)',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (regras.isEmpty)
              const Text(
                'Esse modelo nao possui regras padrao mapeadas na tela.',
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(regras),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
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

  void _mostrarModalSelecao({
    required BuildContext context,
    required String titulo,
    required List<_OpcaoSelect> opcoes,
    required String? selecionado,
    required ValueChanged<String?> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: opcoes.length,
                itemBuilder: (context, index) {
                  final opcao = opcoes[index];
                  final isSelected = opcao.valor == selecionado;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF85C39).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFF85C39),
                      ),
                    ),
                    title: Text(
                      opcao.rotulo,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFFF85C39))
                        : null,
                    onTap: () {
                      onChanged(opcao.valor);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OpcaoSelect {
  final String valor;
  final String rotulo;
  const _OpcaoSelect({required this.valor, required this.rotulo});
}

class _MotorOption {
  final String value;
  final String label;

  const _MotorOption(this.value, this.label);
}
