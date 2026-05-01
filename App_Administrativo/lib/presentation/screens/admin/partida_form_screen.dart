import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import '../../widgets/custom_selector_field.dart';
import '../../widgets/layout/admin_layout_scaffold.dart';
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
  final List<_ArbitroVinculoDraft> _arbitrosSelecionados = [];

  late TextEditingController _localController;
  late TextEditingController _categoriaController;
  late TextEditingController _faseController;
  late TextEditingController _dataController;
  late TextEditingController _horaController;

  List<Campeonato> _campeonatos = [];
  List<dynamic> _modalidades = [];
  List<Equipe> _equipes = [];
  List<Arbitro> _arbitros = [];

  String? _selectedCampeonatoId;
  String? _selectedModalidadeId;
  String? _selectedEquipeAId;
  String? _selectedEquipeBId;

  bool _isLoadingBase = true;
  bool _isLoadingModalidades = false;
  bool _isLoadingEquipes = false;
  bool _isLoadingArbitros = false;
  bool _isSaving = false;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

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

    final campeonatosFuture = _apiService.listarCampeonatos();
    final arbitrosFuture = _apiService.listarArbitros();
    final campeonatosResult = await campeonatosFuture;
    final arbitrosResult = await arbitrosFuture;

    if (!mounted) return;
    setState(() {
      _campeonatos = campeonatosResult;
      _arbitros = arbitrosResult;
    });

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
              final eAId = widget.partida!.equipeAId;
              final eBId = widget.partida!.equipeBId;
              _selectedEquipeAId = eAId.isNotEmpty ? eAId : null;
              _selectedEquipeBId = eBId.isNotEmpty ? eBId : null;
            });
            await _carregarModalidadesComPreselecao(campId, modalidadeId);
          }
        }
      }
    }

    if (mounted) setState(() => _isLoadingBase = false);
  }

  Future<void> _carregarModalidadesComPreselecao(
    String campeonatoId,
    String modalidadeIdAlvo,
  ) async {
    setState(() => _isLoadingModalidades = true);
    final modalidadesResult = await _apiService.listarModalidades(campeonatoId);

    if (!mounted) return;
    setState(() {
      _modalidades = modalidadesResult;
      final existe = _modalidades.any(
        (m) => m['id']?.toString() == modalidadeIdAlvo,
      );
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
      if (_selectedModalidadeId != null &&
          !_modalidades.any((m) => m['id']?.toString() == _selectedModalidadeId)) {
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
    if (_selectedCampeonatoId == null) {
      if (mounted) {
        setState(() => _isLoadingEquipes = false);
      }
      return;
    }
    final equipesResult = await _apiService.listarEquipes(
      campeonatoId: _selectedCampeonatoId,
    );

    if (!mounted) return;
    setState(() {
      _equipes = equipesResult
          .where((e) => e.campeonatoModalidadeId == modalidadeId)
          .toList();
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

  Future<void> _recarregarArbitros() async {
    setState(() => _isLoadingArbitros = true);
    final arbitrosResult = await _apiService.listarArbitros();
    if (!mounted) return;
    setState(() {
      _arbitros = arbitrosResult;
      _isLoadingArbitros = false;
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

  String? _safeValue(String? value, List<String> validIds) {
    if (value == null || value.isEmpty) return null;
    return validIds.contains(value) ? value : null;
  }

  List<Arbitro> get _arbitrosDisponiveis {
    final idsSelecionados = _arbitrosSelecionados.map((a) => a.arbitro.id).toSet();
    return _arbitros.where((a) {
      if (a.id == _currentUserId) return false;
      return !idsSelecionados.contains(a.id);
    }).toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  Future<void> _adicionarArbitro() async {
    if (_isLoadingArbitros) return;

    if (_arbitros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum árbitro disponível no quadro de arbitragem.'),
        ),
      );
      return;
    }

    final disponiveis = _arbitrosDisponiveis;
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os árbitros disponíveis já foram adicionados.'),
        ),
      );
      return;
    }

    final selecionado = await showModalBottomSheet<_ArbitroVinculoDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelecionarArbitroSheet(arbitros: disponiveis),
    );

    if (selecionado != null && mounted) {
      setState(() => _arbitrosSelecionados.add(selecionado));
    }
  }

  void _removerArbitro(String arbitroId) {
    setState(() {
      _arbitrosSelecionados.removeWhere((item) => item.arbitro.id == arbitroId);
    });
  }

  Future<_SavePartidaResult> _persistirPartida(Map<String, dynamic> data) async {
    if (widget.partida == null) {
      final res = await _apiService.criarPartida(data);
      return _SavePartidaResult(
        sucesso: res != null,
        partidaId: res?['id']?.toString(),
      );
    }

    final res = await _apiService.atualizarPartida(widget.partida!.id, data);
    return _SavePartidaResult(
      sucesso: res != null,
      partidaId: widget.partida!.id,
    );
  }

  Future<_ArbitroAssociationResult> _associarArbitrosExtras(String partidaId) async {
    if (_arbitrosSelecionados.isEmpty) {
      return const _ArbitroAssociationResult();
    }

    final falhas = <String>[];
    for (final item in _arbitrosSelecionados) {
      final ok = await _apiService.vincularArbitro(
        partidaId,
        item.arbitro.id,
        item.funcaoApi,
      );
      if (!ok) falhas.add(item.arbitro.nome);
    }

    return _ArbitroAssociationResult(falhas: falhas);
  }

  String _mensagemErroPermissao() {
    if (widget.partida == null) {
      return 'Não foi possível criar a partida.';
    }
    return 'Não foi possível salvar. Apenas o árbitro criador da partida ou um admin pode editar e associar árbitros.';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModalidadeId == null ||
        _selectedEquipeAId == null ||
        _selectedEquipeBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a modalidade e os dois times inscritos.'),
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

    final saveResult = await _persistirPartida(data);
    final partidaId = saveResult.partidaId;
    final sucesso = saveResult.sucesso && partidaId != null && partidaId.isNotEmpty;

    _ArbitroAssociationResult associacaoResult = const _ArbitroAssociationResult();
    if (sucesso) {
      associacaoResult = await _associarArbitrosExtras(partidaId);
    }

    setState(() => _isSaving = false);

    if (sucesso) {
      if (associacaoResult.temFalhas && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Partida salva, mas não foi possível associar: ${associacaoResult.falhas.join(', ')}. Apenas o criador/admin pode ajustar a equipe de arbitragem.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mensagemErroPermissao())),
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

  Future<void> _showSelectionModal<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(labelBuilder(item)),
                      onTap: () {
                        onSelected(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
            Text(
              isEditing
                  ? 'Edição sujeita à regra do árbitro criador'
                  : 'O criador entra automaticamente na arbitragem',
              style: const TextStyle(
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
        actions: [
          IconButton(
            onPressed: _isLoadingArbitros ? null : _recarregarArbitros,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar árbitros',
          ),
        ],
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
                        : 'Carregando formulário...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
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
                      _buildSectionHeader(
                        Icons.emoji_events,
                        'Campeonato e Modalidade da Partida',
                      ),
                      const SizedBox(height: 12),
                      CustomSelectorField<String>(
                        label: 'Campeonato',
                        hint: 'Selecione o campeonato',
                        value: _safeValue(
                          _selectedCampeonatoId,
                          _campeonatos.map((c) => c.id).toList(),
                        ),
                        valueText: _selectedCampeonatoId == null
                            ? null
                            : _campeonatos.firstWhere((c) => c.id == _selectedCampeonatoId, orElse: () => _campeonatos.first).nome,
                        onTap: () => _showSelectionModal<Campeonato>(
                          title: 'Selecione o Campeonato',
                          items: _campeonatos,
                          labelBuilder: (c) => c.nome,
                          onSelected: (c) => _onCampeonatoChanged(c.id),
                        ),
                        validator: (v) => _selectedCampeonatoId == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomSelectorField<String>(
                        label: 'Modalidade do campeonato',
                        hint: _selectedCampeonatoId == null
                            ? 'Selecione o campeonato primeiro'
                            : 'Selecione a modalidade vinculada ao campeonato',
                        isLoading: _isLoadingModalidades,
                        value: _safeValue(
                          _selectedModalidadeId,
                          _modalidades.map<String>((m) => m['id'].toString()).toList(),
                        ),
                        valueText: _selectedModalidadeId == null
                            ? null
                            : _modalidades.firstWhere((m) => m['id'].toString() == _selectedModalidadeId, orElse: () => {})['nomeExibicao']?.toString() ??
                              _modalidades.firstWhere((m) => m['id'].toString() == _selectedModalidadeId, orElse: () => {})['nome']?.toString() ??
                              _modalidades.firstWhere((m) => m['id'].toString() == _selectedModalidadeId, orElse: () => {})['modalidadeNome']?.toString(),
                        onTap: () => _showSelectionModal<Map<String, dynamic>>(
                          title: 'Selecione a Modalidade',
                          items: _modalidades,
                          labelBuilder: (m) => (m['nomeExibicao'] ?? m['nome'] ?? m['modalidadeNome'] ?? '').toString(),
                          onSelected: (m) => _onModalidadeChanged(m['id']?.toString()),
                        ),
                        validator: (v) => _selectedModalidadeId == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 22),
                      _buildSectionHeader(Icons.groups, 'Times / Equipes'),
                      const SizedBox(height: 12),
                      CustomSelectorField<String>(
                        label: 'Time inscrito A',
                        hint: _selectedModalidadeId == null
                            ? 'Selecione a modalidade do campeonato primeiro'
                            : 'Selecione o time inscrito A',
                        isLoading: _isLoadingEquipes,
                        value: _safeValue(
                          _selectedEquipeAId,
                          _equipes.map((e) => e.id).toList(),
                        ),
                        valueText: _selectedEquipeAId == null
                            ? null
                            : () {
                                final e = _equipes.firstWhere((eq) => eq.id == _selectedEquipeAId, orElse: () => _equipes.first);
                                return '${e.atletica?.sigla ?? ''} · ${e.nome}';
                              }(),
                        onTap: () => _showSelectionModal<Equipe>(
                          title: 'Selecione o Time A',
                          items: _equipes,
                          labelBuilder: (e) => '${e.atletica?.sigla ?? ''} · ${e.nome}',
                          onSelected: (e) => setState(() => _selectedEquipeAId = e.id),
                        ),
                        validator: (v) => _selectedEquipeAId == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomSelectorField<String>(
                        label: 'Time inscrito B',
                        hint: _selectedModalidadeId == null
                            ? 'Selecione a modalidade do campeonato primeiro'
                            : 'Selecione o time inscrito B',
                        isLoading: _isLoadingEquipes,
                        value: _safeValue(
                          _selectedEquipeBId,
                          _equipes.map((e) => e.id).toList(),
                        ),
                        valueText: _selectedEquipeBId == null
                            ? null
                            : () {
                                final e = _equipes.firstWhere((eq) => eq.id == _selectedEquipeBId, orElse: () => _equipes.first);
                                return '${e.atletica?.sigla ?? ''} · ${e.nome}';
                              }(),
                        onTap: () => _showSelectionModal<Equipe>(
                          title: 'Selecione o Time B',
                          items: _equipes,
                          labelBuilder: (e) => '${e.atletica?.sigla ?? ''} · ${e.nome}',
                          onSelected: (e) => setState(() => _selectedEquipeBId = e.id),
                        ),
                        validator: (v) => _selectedEquipeBId == null ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 22),
                      _buildSectionHeader(
                        Icons.assignment_ind_outlined,
                        'Equipe de Arbitragem',
                      ),
                      const SizedBox(height: 12),
                      _buildArbitragemInfoCard(isEditing),
                      const SizedBox(height: 12),
                      if (_isLoadingArbitros)
                        _buildLoadingRow('Carregando árbitros...')
                      else
                        _buildArbitrosSelecionados(),
                      const SizedBox(height: 22),
                      _buildSectionHeader(Icons.schedule, 'Data e Horário'),
                      const SizedBox(height: 12),
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
                      TextFormField(
                        controller: _localController,
                        decoration: _inputDecoration(
                          'Local (Ginásio, Campo...)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 14),
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

  Widget _buildArbitragemInfoCard(bool isEditing) {
    final descricao = isEditing
        ? 'A edição da partida e a associação de novos árbitros passam pela validação do backend. Apenas o árbitro criador ou um admin pode concluir essas mudanças.'
        : 'Quem cria a partida entra automaticamente como árbitro criador. Depois disso, você pode adicionar outros árbitros para apitar a mesma partida.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF85C39).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF85C39).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFF85C39),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descricao,
              style: const TextStyle(
                color: Color(0xFF8A3A25),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArbitrosSelecionados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Árbitro criador',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.partida == null
                    ? 'Será definido automaticamente com o usuário logado ao criar a partida.'
                    : 'Permanece definido no backend. Use esta tela para complementar a equipe de arbitragem.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
              ),
            ],
          ),
        ),
        if (_arbitrosSelecionados.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._arbitrosSelecionados.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
                    child: Text(
                      item.arbitro.nome.isNotEmpty
                          ? item.arbitro.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFFF85C39),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.arbitro.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.funcaoLabel,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removerArbitro(item.arbitro.id),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remover árbitro',
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _adicionarArbitro,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF85C39),
            side: const BorderSide(color: Color(0xFFF85C39)),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar outro árbitro'),
        ),
      ],
    );
  }
}

class _ArbitroVinculoDraft {
  final Arbitro arbitro;
  final String funcaoApi;

  const _ArbitroVinculoDraft({
    required this.arbitro,
    required this.funcaoApi,
  });

  String get funcaoLabel {
    switch (funcaoApi) {
      case 'PRINCIPAL':
        return 'Árbitro principal';
      case 'AUXILIAR':
        return 'Árbitro auxiliar';
      case 'MESARIO':
        return 'Mesário';
      default:
        return funcaoApi;
    }
  }
}

class _SavePartidaResult {
  final bool sucesso;
  final String? partidaId;

  const _SavePartidaResult({required this.sucesso, this.partidaId});
}

class _ArbitroAssociationResult {
  final List<String> falhas;

  const _ArbitroAssociationResult({this.falhas = const []});

  bool get temFalhas => falhas.isNotEmpty;
}

class _SelecionarArbitroSheet extends StatefulWidget {
  final List<Arbitro> arbitros;

  const _SelecionarArbitroSheet({required this.arbitros});

  @override
  State<_SelecionarArbitroSheet> createState() => _SelecionarArbitroSheetState();
}

class _SelecionarArbitroSheetState extends State<_SelecionarArbitroSheet> {
  final TextEditingController _buscaController = TextEditingController();
  static const Map<String, String> _funcoes = {
    'PRINCIPAL': 'Árbitro principal',
    'AUXILIAR': 'Árbitro auxiliar',
    'MESARIO': 'Mesário',
  };

  late List<Arbitro> _filtrados;
  Arbitro? _selecionado;
  String _funcao = 'AUXILIAR';

  @override
  void initState() {
    super.initState();
    _filtrados = widget.arbitros;
    _buscaController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final termo = _buscaController.text.trim().toLowerCase();
    setState(() {
      _filtrados = termo.isEmpty
          ? widget.arbitros
          : widget.arbitros.where((arbitro) {
              final nome = arbitro.nome.toLowerCase();
              final telefone = arbitro.telefone?.toLowerCase() ?? '';
              return nome.contains(termo) || telefone.contains(termo);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      color: Color(0xFFF85C39),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adicionar árbitro à partida',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar árbitro...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF85C39)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: DropdownButtonFormField<String>(
                  value: _funcao,
                  decoration: InputDecoration(
                    labelText: 'Função na partida',
                    floatingLabelStyle: const TextStyle(color: Color(0xFFF85C39)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFF85C39),
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: _funcoes.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _funcao = value ?? _funcao);
                  },
                ),
              ),
              Expanded(
                child: _filtrados.isEmpty
                    ? const Center(child: Text('Nenhum árbitro encontrado'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, index) {
                          final arbitro = _filtrados[index];
                          final isSelected = _selecionado?.id == arbitro.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selecionado = arbitro),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF85C39).withValues(alpha: 0.08)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF85C39)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFF85C39)
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      arbitro.nome.isNotEmpty
                                          ? arbitro.nome[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Color(0xFFF85C39),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          arbitro.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (arbitro.telefone != null &&
                                            arbitro.telefone!.isNotEmpty)
                                          Text(
                                            arbitro.telefone!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? const Color(0xFFF85C39)
                                        : Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selecionado == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              _ArbitroVinculoDraft(
                                arbitro: _selecionado!,
                                funcaoApi: _funcao,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF85C39),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Adicionar à partida',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
