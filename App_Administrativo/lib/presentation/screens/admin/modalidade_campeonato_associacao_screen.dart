import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

class ModalidadeCampeonatoAssociacaoScreen extends StatefulWidget {
  final ModalidadeCatalogo modalidade;
  final List<Campeonato> campeonatosDisponiveis;

  const ModalidadeCampeonatoAssociacaoScreen({
    super.key,
    required this.modalidade,
    required this.campeonatosDisponiveis,
  });

  @override
  State<ModalidadeCampeonatoAssociacaoScreen> createState() =>
      _ModalidadeCampeonatoAssociacaoScreenState();
}

class _ModalidadeCampeonatoAssociacaoScreenState
    extends State<ModalidadeCampeonatoAssociacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = AdminApiService();

  late final TextEditingController _nomeExibicaoController;
  late final TextEditingController _categoriaController;

  int _step = 0;
  bool _isSaving = false;
  bool _isLoadingEventos = true;

  String? _campeonatoId;
  String _genero = 'Misto';
  String _status = 'Ativa';

  int _tempoPartidaMinutos = 20;
  int _periodos = 2;
  bool _cronometroParado = true;
  String _tipoPontuacao = 'GOLS';
  int? _setsParaVencer;
  int? _pontosPorSet;
  int? _faltasColetivasLimite = 5;
  bool _permiteProrrogacao = false;
  bool _permitePenaltis = false;
  final List<String> _eventosExtrasSelecionados = [];

  late final List<_PresetOption> _faseOptions;
  late String _selectedFasePreset;
  List<Map<String, dynamic>> _tiposEvento = [];

  @override
  void initState() {
    super.initState();
    _nomeExibicaoController = TextEditingController(
      text: widget.modalidade.nome,
    );
    _categoriaController = TextEditingController();
    _campeonatoId = widget.campeonatosDisponiveis.isNotEmpty
        ? widget.campeonatosDisponiveis.first.id
        : null;
    _applyCatalogRules(widget.modalidade.regrasBaseJson);
    _faseOptions = _buildFaseOptions();
    _selectedFasePreset = _faseOptions.first.id;
    _carregarTiposEvento();
  }

  @override
  void dispose() {
    _nomeExibicaoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _carregarTiposEvento() async {
    final eventos = await _api.listarTiposEventosModalidadeCatalogo(
      widget.modalidade.id,
    );
    if (!mounted) return;
    setState(() {
      _tiposEvento = eventos;
      _isLoadingEventos = false;
    });
  }

  void _applyCatalogRules(Map<String, dynamic>? rules) {
    final source = rules ?? const <String, dynamic>{};
    _tempoPartidaMinutos = _readInt(source['tempoPartidaMinutos']) ?? 20;
    _periodos = _readInt(source['periodos']) ?? 2;
    _cronometroParado = source['cronometroParado'] == true;
    _tipoPontuacao = source['tipoPontuacao']?.toString() ?? 'GOLS';
    _setsParaVencer = _readIntNullable(source['setsParaVencer']);
    _pontosPorSet = _readIntNullable(source['pontosPorSet']);
    _faltasColetivasLimite = _readIntNullable(source['faltasColetivasLimite']);
    _permiteProrrogacao = source['permiteProrrogacao'] == true;
    _permitePenaltis = source['permitePenaltis'] == true;
  }

  List<_PresetOption> _buildFaseOptions() {
    return const [
      _PresetOption(
        id: 'grupos',
        label: 'Fase única em grupos',
        payload: {
          'modelo': 'GRUPOS',
          'grupos': 1,
          'classificadosPorGrupo': 0,
          'mataMataAposGrupos': false,
        },
      ),
      _PresetOption(
        id: 'grupos_mata_mata',
        label: 'Grupos + mata-mata',
        payload: {
          'modelo': 'GRUPOS_MATA_MATA',
          'grupos': 4,
          'classificadosPorGrupo': 2,
          'mataMataAposGrupos': true,
        },
      ),
      _PresetOption(
        id: 'mata_mata',
        label: 'Mata-mata simples',
        payload: {
          'modelo': 'MATA_MATA',
          'idaEVolta': false,
          'terceiroLugar': false,
        },
      ),
      _PresetOption(
        id: 'mata_mata_ida_volta',
        label: 'Mata-mata ida e volta',
        payload: {
          'modelo': 'MATA_MATA',
          'idaEVolta': true,
          'terceiroLugar': false,
        },
      ),
    ];
  }

  Map<String, dynamic> get _regrasPayload {
    return {
      'tempoPartidaMinutos': _tempoPartidaMinutos,
      'periodos': _periodos,
      'cronometroParado': _cronometroParado,
      'tipoPontuacao': _tipoPontuacao,
      'setsParaVencer': _setsParaVencer,
      'pontosPorSet': _pontosPorSet,
      'faltasColetivasLimite': _faltasColetivasLimite,
      'permiteProrrogacao': _permiteProrrogacao,
      'permitePenaltis': _permitePenaltis,
      'eventosPermitidos': _eventosExtrasSelecionados.isEmpty
          ? null
          : _eventosExtrasSelecionados,
    };
  }

  Map<String, dynamic> get _fasePayload =>
      _faseOptions.firstWhere((item) => item.id == _selectedFasePreset).payload;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_campeonatoId == null || _campeonatoId!.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final result = await _api.associarModalidadeAoCampeonato({
        'campeonatoId': _campeonatoId,
        'modalidadeCatalogoId': widget.modalidade.id,
        'nomeExibicao': _nomeExibicaoController.text.trim(),
        'categoria': _categoriaController.text.trim().isEmpty
            ? null
            : _categoriaController.text.trim(),
        'genero': _genero,
        'regrasJson': _regrasPayload,
        'formatoFasesJson': _fasePayload,
        'status': _status,
      });
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
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
          'Associar Modalidade',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStepperHeader(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    const titles = ['1. Associação', '2. Regras', '3. Formato'];

    return Row(
      children: List.generate(titles.length, (index) {
        final selected = index == _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == titles.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF85C39) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              titles[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildAssociationStep();
      case 1:
        return _buildRulesStep();
      default:
        return _buildFormatStep();
    }
  }

  Widget _buildAssociationStep() {
    return _buildCard(
      title: 'Dados da associação',
      subtitle: 'Como a modalidade vai aparecer no campeonato.',
      child: Column(
        children: [
          _buildSelectorField(
            label: 'Campeonato',
            value: widget.campeonatosDisponiveis
                .firstWhere(
                  (item) => item.id == _campeonatoId,
                  orElse: () => widget.campeonatosDisponiveis.first,
                )
                .nome,
            onTap: () => _showOptionSheet(
              title: 'Selecione o campeonato',
              options: widget.campeonatosDisponiveis
                  .map((item) => _SheetOption(item.id, item.nome))
                  .toList(),
              selected: _campeonatoId,
              onSelected: (value) => setState(() => _campeonatoId = value),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nomeExibicaoController,
            decoration: _inputDecoration('Nome exibido no campeonato'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 24),

          _buildSelectorField(
            label: 'Gênero da disputa',
            value: _labelGenero(_genero),
            onTap: () => _showOptionSheet(
              title: 'Selecione o gênero',
              options: const [
                _SheetOption('Masculino', 'Masculino'),
                _SheetOption('Feminino', 'Feminino'),
                _SheetOption('Misto', 'Misto'),
              ],
              selected: _genero,
              onSelected: (value) => setState(() => _genero = value ?? _genero),
            ),
          ),
          const SizedBox(height: 24),
          _buildSelectorField(
            label: 'Status',
            value: _status,
            onTap: () => _showOptionSheet(
              title: 'Selecione o status',
              options: const [
                _SheetOption('Ativa', 'Ativa'),
                _SheetOption('Inativa', 'Inativa'),
                _SheetOption('Suspensa', 'Suspensa'),
              ],
              selected: _status,
              onSelected: (value) => setState(() => _status = value ?? _status),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _categoriaController,
            decoration: _inputDecoration('Categoria'),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesStep() {
    return _buildCard(
      title: 'Regras do campeonato',
      subtitle:
          'Essas regras vão preencher `regras_json` e sobrescrever o padrão do catálogo quando necessário.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Tempo por partida (min)',
                  initialValue: _tempoPartidaMinutos.toString(),
                  onChanged: (value) =>
                      _tempoPartidaMinutos = int.tryParse(value) ?? 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  label: 'Períodos',
                  initialValue: _periodos.toString(),
                  onChanged: (value) => _periodos = int.tryParse(value) ?? 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSelectorField(
            label: 'Tipo de pontuação',
            value: _tipoPontuacao,
            onTap: () => _showOptionSheet(
              title: 'Selecione o tipo de pontuação',
              options: const [
                _SheetOption('GOLS', 'GOLS'),
                _SheetOption('PONTOS', 'PONTOS'),
                _SheetOption('SETS', 'SETS'),
              ],
              selected: _tipoPontuacao,
              onSelected: (value) =>
                  setState(() => _tipoPontuacao = value ?? _tipoPontuacao),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _cronometroParado,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFF85C39),
            title: const Text('Cronômetro parado'),
            onChanged: (value) => setState(() => _cronometroParado = value),
          ),
          if (_tipoPontuacao == 'SETS') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'Sets para vencer',
                    initialValue: _setsParaVencer?.toString(),
                    onChanged: (value) =>
                        _setsParaVencer = _readIntNullable(value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    label: 'Pontos por set',
                    initialValue: _pontosPorSet?.toString(),
                    onChanged: (value) =>
                        _pontosPorSet = _readIntNullable(value),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            _numberField(
              label: 'Limite de faltas coletivas',
              initialValue: _faltasColetivasLimite?.toString(),
              onChanged: (value) =>
                  _faltasColetivasLimite = _readIntNullable(value),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            value: _permiteProrrogacao,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFF85C39),
            title: const Text('Permite prorrogação'),
            onChanged: (value) => setState(() => _permiteProrrogacao = value),
          ),
          SwitchListTile(
            value: _permitePenaltis,
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFF85C39),
            title: const Text('Permite pênaltis'),
            onChanged: (value) => setState(() => _permitePenaltis = value),
          ),
          const SizedBox(height: 8),

          if (_isLoadingEventos)
            const LinearProgressIndicator(color: Color(0xFFF85C39))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tiposEvento.map((evento) {
                final code = evento['codigo']?.toString() ?? '';
                final label = evento['nome']?.toString() ?? code;
                final selected = _eventosExtrasSelecionados.contains(code);
                return FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _eventosExtrasSelecionados.add(code);
                      } else {
                        _eventosExtrasSelecionados.remove(code);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  _showJsonPreview('Prévia de regras_json', _regrasPayload),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Visualizar payload de regras'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatStep() {
    return Column(
      children: [
        _buildCard(
          title: 'Formato de fases',
          subtitle:
              'Selecione um modelo para preencher `formato_fases_json` com uma estrutura inicial.',
          child: Column(
            children: [
              ..._faseOptions.map(
                (option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFFF85C39),
                  title: Text(option.label),
                  value: option.id,
                  groupValue: _selectedFasePreset,
                  onChanged: (value) =>
                      setState(() => _selectedFasePreset = value ?? option.id),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showJsonPreview(
                    'Prévia de formato_fases_json',
                    _fasePayload,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Visualizar payload de fases'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Revisão final',
          subtitle: 'Confira o que será salvo na associação.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryLine('Campeonato', _selectedCampeonatoLabel),
              _summaryLine('Nome exibido', _nomeExibicaoController.text.trim()),
              _summaryLine(
                'Categoria',
                _categoriaController.text.trim().isEmpty
                    ? 'Sem categoria'
                    : _categoriaController.text.trim(),
              ),
              _summaryLine('Gênero', _labelGenero(_genero)),
              _summaryLine('Status', _status),
              _summaryLine(
                'Preset de fases',
                _faseOptions
                    .firstWhere((item) => item.id == _selectedFasePreset)
                    .label,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: [
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.arrow_drop_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    String? initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label),
      onChanged: onChanged,
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _prevStep,
                child: const Text('Voltar'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : (_step == 2 ? _salvar : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85C39),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _step == 2 ? 'Salvar associação' : 'Continuar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptionSheet({
    required String title,
    required List<_SheetOption> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
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
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.value == selected;
                  return ListTile(
                    title: Text(
                      option.label,
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
                      onSelected(option.value);
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

  void _showJsonPreview(String title, Map<String, dynamic> payload) {
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
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(payload),
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

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String get _selectedCampeonatoLabel {
    return widget.campeonatosDisponiveis
        .firstWhere(
          (item) => item.id == _campeonatoId,
          orElse: () => widget.campeonatosDisponiveis.first,
        )
        .nome;
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

  String _labelGenero(String value) {
    switch (value.toUpperCase()) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMININO':
        return 'Feminino';
      default:
        return 'Misto';
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int? _readIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return _readInt(value);
  }
}

class _SheetOption {
  final String value;
  final String label;

  const _SheetOption(this.value, this.label);
}

class _PresetOption {
  final String id;
  final String label;
  final Map<String, dynamic> payload;

  const _PresetOption({
    required this.id,
    required this.label,
    required this.payload,
  });
}
