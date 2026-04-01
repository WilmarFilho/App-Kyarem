import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../../../services/admin_api_service.dart';

class PartidaFormScreen extends StatefulWidget {
  final Partida? partida;

  const PartidaFormScreen({super.key, this.partida});

  @override
  State<PartidaFormScreen> createState() => _PartidaFormScreenState();
}

class _PartidaFormScreenState extends State<PartidaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminApiService _apiService = AdminApiService();

  late TextEditingController _localController;
  late TextEditingController _categoriaController;
  late TextEditingController _faseController;
  late TextEditingController _dataController;
  late TextEditingController _horaController;

  List<Campeonato> _campeonatos = [];
  List<dynamic> _modalidades = [];
  List<Equipe> _equipes = [];

  String? _selectedCampeonatoId;
  String? _selectedModalidadeId;
  String? _selectedEquipeAId;
  String? _selectedEquipeBId;

  bool _isLoadingBase = true;
  bool _isLoadingModalidades = false;
  bool _isLoadingEquipes = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.partida?.local ?? '');
    _categoriaController = TextEditingController(
      text: widget.partida?.categoria ?? '',
    );
    _faseController = TextEditingController(text: widget.partida?.fase ?? '');

    if (widget.partida?.agendadaPara != null) {
      final dt = widget.partida!.agendadaPara!.toLocal();
      _dataController = TextEditingController(
        text:
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
      );
      _horaController = TextEditingController(
        text:
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      );
    } else {
      _dataController = TextEditingController();
      _horaController = TextEditingController();
    }

    _carregarDadosBase();
  }

  @override
  void dispose() {
    _localController.dispose();
    _categoriaController.dispose();
    _faseController.dispose();
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosBase() async {
    setState(() => _isLoadingBase = true);

    // 1. Carrega campeonatos (sempre necessário)
    final campeonatosResult = await _apiService.listarCampeonatos();

    if (!mounted) return;
    setState(() {
      _campeonatos = campeonatosResult;
    });

    // 2. Se for edição, resolve campeonatoId via GET /modalidades/{id}
    if (widget.partida != null) {
      final modalidadeId = widget.partida!.modalidadeId;
      if (modalidadeId.isNotEmpty) {
        final modData = await _apiService.buscarModalidade(modalidadeId);
        if (modData != null) {
          final campId = modData['campeonatoId']?.toString();
          if (campId != null && campId.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              _selectedCampeonatoId = campId;
              // Pré-seleciona as equipes já conhecidas
              final eAId = widget.partida!.equipeAId;
              final eBId = widget.partida!.equipeBId;
              _selectedEquipeAId = eAId.isNotEmpty ? eAId : null;
              _selectedEquipeBId = eBId.isNotEmpty ? eBId : null;
            });

            // Carrega modalidades do campeonato e depois as equipes
            await _carregarModalidadesComPreselecao(campId, modalidadeId);
          }
        }
      }
    }

    if (mounted) setState(() => _isLoadingBase = false);
  }

  /// Carrega as modalidades do campeonato e, após, pré-seleciona a modalidade
  /// e carrega as equipes dessa modalidade.
  Future<void> _carregarModalidadesComPreselecao(
    String campeonatoId,
    String modalidadeIdAlvo,
  ) async {
    setState(() => _isLoadingModalidades = true);
    final modalidadesResult = await _apiService.listarModalidades(campeonatoId);

    if (!mounted) return;
    setState(() {
      _modalidades = modalidadesResult;
      // Pré-seleciona a modalidade se ela existir na lista
      final existe = _modalidades.any((m) => m['id'] == modalidadeIdAlvo);
      _selectedModalidadeId = existe ? modalidadeIdAlvo : null;
      _isLoadingModalidades = false;
    });

    if (_selectedModalidadeId != null) {
      await _carregarEquipes(_selectedModalidadeId!);
    }
  }

  Future<void> _carregarModalidades(String campeonatoId) async {
    if (campeonatoId.isEmpty) return;
    setState(() {
      _isLoadingModalidades = true;
      _modalidades = [];
    });
    final modalidadesResult = await _apiService.listarModalidades(campeonatoId);

    if (!mounted) return;
    setState(() {
      _modalidades = modalidadesResult;
      // Reseta seleções dependentes se a modalidade atual não existe no novo campeonato
      if (_selectedModalidadeId != null &&
          !_modalidades.any((m) => m['id'] == _selectedModalidadeId)) {
        _selectedModalidadeId = null;
        _selectedEquipeAId = null;
        _selectedEquipeBId = null;
        _equipes = [];
      }
      _isLoadingModalidades = false;
    });

    if (_selectedModalidadeId != null) {
      await _carregarEquipes(_selectedModalidadeId!);
    }
  }

  Future<void> _carregarEquipes(String modalidadeId) async {
    setState(() {
      _isLoadingEquipes = true;
      _equipes = [];
    });
    final equipesResult = await _apiService.listarEquipes(
      modalidadeId: modalidadeId,
    );

    if (!mounted) return;
    setState(() {
      _equipes = equipesResult;
      // Mantém seleção se a equipe ainda está na lista
      if (_selectedEquipeAId != null &&
          !_equipes.any((e) => e.id == _selectedEquipeAId)) {
        _selectedEquipeAId = null;
      }
      if (_selectedEquipeBId != null &&
          !_equipes.any((e) => e.id == _selectedEquipeBId)) {
        _selectedEquipeBId = null;
      }
      _isLoadingEquipes = false;
    });
  }

  void _onCampeonatoChanged(String? newId) {
    setState(() {
      _selectedCampeonatoId = newId;
      _selectedModalidadeId = null;
      _selectedEquipeAId = null;
      _selectedEquipeBId = null;
      _modalidades = [];
      _equipes = [];
    });
    if (newId != null) _carregarModalidades(newId);
  }

  void _onModalidadeChanged(String? newId) {
    setState(() {
      _selectedModalidadeId = newId;
      _selectedEquipeAId = null;
      _selectedEquipeBId = null;
      _equipes = [];
    });
    if (newId != null) _carregarEquipes(newId);
  }

  /// Retorna [value] somente se existir em [validIds], senão null.
  /// Evita o crash do DropdownButton quando value não está nos items.
  String? _safeValue(String? value, List<String> validIds) {
    if (value == null || value.isEmpty) return null;
    return validIds.contains(value) ? value : null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModalidadeId == null ||
        _selectedEquipeAId == null ||
        _selectedEquipeBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione Modalidade e as duas Equipes.'),
        ),
      );
      return;
    }

    if (_selectedEquipeAId == _selectedEquipeBId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipe A e B devem ser diferentes.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? agendadaPara;
    if (_dataController.text.isNotEmpty && _horaController.text.isNotEmpty) {
      // Converte para UTC antes de enviar
      final local = DateTime.parse(
        '${_dataController.text}T${_horaController.text}:00',
      );
      agendadaPara = local.toUtc().toIso8601String();
    }

    final data = {
      'modalidadeId': _selectedModalidadeId,
      'equipeAId': _selectedEquipeAId,
      'equipeBId': _selectedEquipeBId,
      'local': _localController.text,
      'categoria': _categoriaController.text,
      'fase': _faseController.text,
      'agendadoPara': agendadaPara,
    };

    bool sucesso = false;
    if (widget.partida == null) {
      final res = await _apiService.criarPartida(data);
      sucesso = res != null;
    } else {
      final res = await _apiService.atualizarPartida(widget.partida!.id, data);
      sucesso = res != null;
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar Partida.')),
        );
      }
    }
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      _dataController.text =
          '${selecionada.year}-${selecionada.month.toString().padLeft(2, '0')}-${selecionada.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selecionarHora() async {
    final horaReq = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (horaReq != null && mounted) {
      _horaController.text =
          '${horaReq.hour.toString().padLeft(2, '0')}:${horaReq.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.partida != null;
    final title = isEditing ? 'Editar Partida' : 'Nova Partida';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
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
            if (isEditing)
              const Text(
                'Campos preenchidos automaticamente',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF85C39), Color(0xFFE64A19)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isLoadingBase
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFF85C39)),
                  const SizedBox(height: 16),
                  Text(
                    isEditing
                        ? 'Carregando dados da partida...'
                        : 'Carregando...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── CABEÇALHO SEÇÃO ──
                      _buildSectionHeader(
                        Icons.emoji_events,
                        'Campeonato e Modalidade',
                      ),
                      const SizedBox(height: 12),

                      // ── CAMPEONATO ──
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Campeonato'),
                        value: _safeValue(
                          _selectedCampeonatoId,
                          _campeonatos.map((c) => c.id).toList(),
                        ),
                        items: _campeonatos.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nome),
                          );
                        }).toList(),
                        onChanged: _onCampeonatoChanged,
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),

                      // ── MODALIDADE ──
                      _isLoadingModalidades
                          ? _buildLoadingRow('Carregando modalidades...')
                          : DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Modalidade'),
                              value: _safeValue(
                                _selectedModalidadeId,
                                _modalidades
                                    .map<String>((m) => m['id'] as String)
                                    .toList(),
                              ),
                              items: _modalidades.map((m) {
                                return DropdownMenuItem<String>(
                                  value: m['id'],
                                  child: Text(m['nome'] ?? ''),
                                );
                              }).toList(),
                              onChanged: _onModalidadeChanged,
                              validator: (v) =>
                                  v == null ? 'Obrigatório' : null,
                              hint: Text(
                                _selectedCampeonatoId == null
                                    ? 'Selecione o Campeonato primeiro'
                                    : 'Selecione a Modalidade',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                      const SizedBox(height: 22),
                      _buildSectionHeader(Icons.groups, 'Times / Equipes'),
                      const SizedBox(height: 12),

                      // ── EQUIPE A ──
                      _isLoadingEquipes
                          ? _buildLoadingRow('Carregando equipes...')
                          : DropdownButtonFormField<String>(
                              decoration: _inputDecoration(
                                'Equipe A (Mandante)',
                              ),
                              value: _safeValue(
                                _selectedEquipeAId,
                                _equipes.map((e) => e.id).toList(),
                              ),
                              items: _equipes.map((e) {
                                return DropdownMenuItem<String>(
                                  value: e.id,
                                  child: Text(
                                    '${e.atletica?.sigla ?? ''} · ${e.nome}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedEquipeAId = v),
                              validator: (v) =>
                                  v == null ? 'Obrigatório' : null,
                              hint: Text(
                                _selectedModalidadeId == null
                                    ? 'Selecione a Modalidade primeiro'
                                    : 'Selecione a Equipe A',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                      const SizedBox(height: 14),

                      // ── EQUIPE B ──
                      _isLoadingEquipes
                          ? const SizedBox.shrink()
                          : DropdownButtonFormField<String>(
                              decoration: _inputDecoration(
                                'Equipe B (Visitante)',
                              ),
                              value: _safeValue(
                                _selectedEquipeBId,
                                _equipes.map((e) => e.id).toList(),
                              ),
                              items: _equipes.map((e) {
                                return DropdownMenuItem<String>(
                                  value: e.id,
                                  child: Text(
                                    '${e.atletica?.sigla ?? ''} · ${e.nome}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedEquipeBId = v),
                              validator: (v) =>
                                  v == null ? 'Obrigatório' : null,
                              hint: Text(
                                _selectedModalidadeId == null
                                    ? 'Selecione a Modalidade primeiro'
                                    : 'Selecione a Equipe B',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                      const SizedBox(height: 22),
                      _buildSectionHeader(Icons.schedule, 'Data e Horário'),
                      const SizedBox(height: 12),

                      // ── DATA E HORA ──
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dataController,
                              decoration: _inputDecoration('Data').copyWith(
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                              ),
                              readOnly: true,
                              onTap: _selecionarData,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _horaController,
                              decoration: _inputDecoration('Hora').copyWith(
                                suffixIcon: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                              ),
                              readOnly: true,
                              onTap: _selecionarHora,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildSectionHeader(
                        Icons.info_outline,
                        'Informações extras',
                      ),
                      const SizedBox(height: 12),

                      // ── LOCAL ──
                      TextFormField(
                        controller: _localController,
                        decoration: _inputDecoration(
                          'Local (Ginásio, Campo...)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),

                      // ── CATEGORIA + FASE ──
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoriaController,
                              decoration: _inputDecoration(
                                'Categoria (ex: Livre)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _faseController,
                              decoration: _inputDecoration('Fase (ex: Final)'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ── BOTÃO SALVAR ──
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
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isEditing
                                      ? 'Salvar Alterações'
                                      : 'Criar Partida',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
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

  Widget _buildSectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF85C39)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF85C39),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: const Color(0xFFF85C39).withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  Widget _buildLoadingRow(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            msg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
