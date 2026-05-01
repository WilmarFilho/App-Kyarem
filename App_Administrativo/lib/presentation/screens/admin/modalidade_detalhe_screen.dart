import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'modalidade_form_screen.dart';

class ModalidadeDetalheScreen extends StatefulWidget {
  final ModalidadeCatalogo modalidade;

  const ModalidadeDetalheScreen({super.key, required this.modalidade});

  @override
  State<ModalidadeDetalheScreen> createState() =>
      _ModalidadeDetalheScreenState();
}

class _ModalidadeDetalheScreenState extends State<ModalidadeDetalheScreen> {
  final AdminApiService _api = AdminApiService();
  late ModalidadeCatalogo _modalidade;
  List<ModalidadeCampeonato> _associacoes = [];
  List<Campeonato> _campeonatos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _modalidade = widget.modalidade;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _api.listarAssociacoesModalidadeCatalogo(_modalidade.id),
      _api.listarCampeonatos(),
    ]);
    if (!mounted) return;
    setState(() {
      _associacoes = results[0] as List<ModalidadeCampeonato>;
      _campeonatos = results[1] as List<Campeonato>;
      _isLoading = false;
    });
  }

  Future<void> _abrirEdicao() async {
    final updated = await Navigator.push<ModalidadeCatalogo>(
      context,
      MaterialPageRoute(
        builder: (_) => ModalidadeFormScreen(modalidade: _modalidade),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _modalidade = updated);
      await _carregar();
    }
  }

  Future<void> _abrirAssociacao() async {
    final vinculados = _associacoes.map((e) => e.campeonatoId).toSet();
    final disponiveis = _campeonatos
        .where((c) => !vinculados.contains(c.id))
        .toList();

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Essa modalidade ja esta associada a todos os campeonatos cadastrados.',
          ),
        ),
      );
      return;
    }

    String? campeonatoId = disponiveis.first.id;
    final nomeExibicaoCtrl = TextEditingController(text: _modalidade.nome);
    final categoriaCtrl = TextEditingController();
    String genero = _modalidade.genero;
    bool loading = false;

    try {
      final created = await showDialog<ModalidadeCampeonato?>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setStateModal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Associar ao campeonato'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campeonato',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: loading
                            ? null
                            : () {
                                _mostrarModalSelecao(
                                  context: context,
                                  titulo: 'Selecione o Campeonato',
                                  opcoes: disponiveis
                                      .map(
                                        (c) => _OpcaoSelect(
                                          valor: c.id,
                                          rotulo: c.nome,
                                        ),
                                      )
                                      .toList(),
                                  selecionado: campeonatoId,
                                  onChanged: (val) =>
                                      setStateModal(() => campeonatoId = val),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                disponiveis
                                    .firstWhere(
                                      (c) => c.id == campeonatoId,
                                      orElse: () => disponiveis.first,
                                    )
                                    .nome,
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
                  TextField(
                    controller: nomeExibicaoCtrl,
                    decoration: _inputDecoration('Nome exibido no campeonato'),
                    enabled: !loading,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: categoriaCtrl,
                    decoration: _inputDecoration('Categoria (opcional)'),
                    enabled: !loading,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gênero da disputa',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: loading
                            ? null
                            : () {
                                _mostrarModalSelecao(
                                  context: context,
                                  titulo: 'Selecione o Gênero',
                                  opcoes: const [
                                    _OpcaoSelect(
                                      valor: 'MASCULINO',
                                      rotulo: 'Masculino',
                                    ),
                                    _OpcaoSelect(
                                      valor: 'FEMININO',
                                      rotulo: 'Feminino',
                                    ),
                                    _OpcaoSelect(
                                      valor: 'MISTO',
                                      rotulo: 'Misto',
                                    ),
                                  ],
                                  selecionado: genero,
                                  onChanged: (val) => setStateModal(
                                    () => genero = val ?? genero,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _labelGenero(genero),
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
                ],
              ),
            ),
            actions: [
              if (!loading)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
              loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        if (campeonatoId == null || campeonatoId!.isEmpty)
                          return;
                        setStateModal(() => loading = true);
                        try {
                          final result = await _api
                              .associarModalidadeAoCampeonato({
                                'campeonatoId': campeonatoId,
                                'modalidadeCatalogoId': _modalidade.id,
                                'nomeExibicao':
                                    nomeExibicaoCtrl.text.trim().isEmpty
                                    ? _modalidade.nome
                                    : nomeExibicaoCtrl.text.trim(),
                                'categoria': categoriaCtrl.text.trim().isEmpty
                                    ? null
                                    : categoriaCtrl.text.trim(),
                                'genero': genero,
                                'status': 'ATIVA',
                              });
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext, result);
                        } catch (e) {
                          setStateModal(() => loading = false);
                          if (!context.mounted) return;
                          String errorMsg = e.toString().replaceAll(
                            'Exception: ',
                            '',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF85C39),
                      ),
                      child: const Text(
                        'Associar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      );

      if (created != null && mounted) {
        await _carregar();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modalidade associada ao campeonato.')),
        );
      }
    } finally {
      nomeExibicaoCtrl.dispose();
      categoriaCtrl.dispose();
    }
  }

  Future<void> _removerAssociacao(ModalidadeCampeonato associacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover associacao?'),
        content: Text(
          'Deseja remover "${associacao.campeonatoNome ?? 'Campeonato'}" desta modalidade?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    final ok = await _api.removerAssociacaoModalidade(associacao.id);
    if (!mounted) return;
    if (ok) {
      await _carregar();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Associacao removida.'
              : 'Nao foi possivel remover a associacao.',
        ),
      ),
    );
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
          'Modalidade',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _abrirEdicao,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirAssociacao,
        backgroundColor: const Color(0xFFF85C39),
        icon: const Icon(Icons.add_link, color: Colors.white),
        label: const Text(
          'Associar campeonato',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                _buildAssociacoesCard(),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _modalidade.nome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(_modalidade.esporteNome ?? 'Sem esporte'),
              _buildPill(_labelGenero(_modalidade.genero)),
              _buildPill(_labelMotor(_modalidade.motorRegras)),
              _buildPill(_modalidade.slug),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssociacoesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campeonatos associados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (_associacoes.isEmpty)
            Text(
              'Ainda nao existe nenhuma associacao para essa modalidade.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._associacoes.map(_buildAssociacaoTile),
        ],
      ),
    );
  }

  Widget _buildAssociacaoTile(ModalidadeCampeonato associacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF85C39).withValues(alpha: 0.12),
            child: const Icon(Icons.emoji_events, color: Color(0xFFF85C39)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  associacao.campeonatoNome ?? 'Campeonato',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  associacao.nomeExibicao?.isNotEmpty == true
                      ? associacao.nomeExibicao!
                      : _modalidade.nome,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (associacao.categoria?.isNotEmpty == true)
                  Text(
                    associacao.categoria!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(associacao.status ?? 'ATIVA'),
              IconButton(
                onPressed: () => _removerAssociacao(associacao),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF85C39).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF85C39),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF85C39).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFFF85C39),
          fontSize: 11,
          fontWeight: FontWeight.bold,
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

  String _labelMotor(String value) {
    const labels = {
      'FUTSAL_V1': 'Motor futsal',
      'VOLEI_V1': 'Motor volei',
      'BASQUETE_V1': 'Motor basquete',
      'HANDEBOL_V1': 'Motor handebol',
      'SOCIETY_V1': 'Motor society',
      'FUTEBOL_CAMPO_V1': 'Motor campo',
      'GENERICO_V1': 'Motor generico',
    };
    return labels[value] ?? value;
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
                        color: const Color(0xFFF85C39).withOpacity(0.1),
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
