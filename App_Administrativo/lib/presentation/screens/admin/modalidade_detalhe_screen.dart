import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_campeonato_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';
import 'package:kyarem_eventos/services/admin_api_service.dart';

import 'modalidade_campeonato_associacao_screen.dart';
import 'modalidade_form_screen.dart';
import 'tipo_evento_form_screen.dart';

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
  List<Map<String, dynamic>> _tiposEventos = [];
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
      _api.listarTiposEventosModalidadeCatalogo(_modalidade.id),
    ]);
    if (!mounted) return;
    setState(() {
      _associacoes = results[0] as List<ModalidadeCampeonato>;
      _campeonatos = results[1] as List<Campeonato>;
      _tiposEventos = results[2] as List<Map<String, dynamic>>;
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

    final created = await Navigator.push<ModalidadeCampeonato>(
      context,
      MaterialPageRoute(
        builder: (_) => ModalidadeCampeonatoAssociacaoScreen(
          modalidade: _modalidade,
          campeonatosDisponiveis: disponiveis,
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

  Future<void> _abrirTipoEventoForm() async {
    final data = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TipoEventoFormScreen(
          modalidadeCatalogoId: _modalidade.id,
          motorRegras: _modalidade.motorRegras,
        ),
      ),
    );

    if (data != null && mounted) {
      setState(() => _isLoading = true);
      final created = await _api.criarTipoEvento(_modalidade.id, data);
      if (!mounted) return;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de evento criado com sucesso.')),
        );
        await _carregar();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar tipo de evento.')),
        );
      }
    }
  }

  Future<void> _excluirTipoEvento(String tipoEventoId, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tipo de evento?'),
        content: Text('Deseja excluir "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _isLoading = true);
    final ok = await _api.excluirTipoEvento(_modalidade.id, tipoEventoId);
    if (!mounted) return;
    if (ok) {
      await _carregar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo de evento excluído.')),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir tipo de evento.')),
      );
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _abrirAssociacao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF85C39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Campeonato'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _abrirTipoEventoForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Tipo Evento'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF85C39)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                _buildAssociacoesCard(),
                const SizedBox(height: 18),
                _buildTiposEventosCard(),
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
              if (_modalidade.genero.isNotEmpty) _buildPill(_modalidade.genero),
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
              'Não existe associação para essa modalidade.',
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
  Widget _buildTiposEventosCard() {
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
            'Tipos de Eventos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (_tiposEventos.isEmpty)
            Text(
              'Não há tipos de eventos para esta modalidade.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._tiposEventos.map(_buildTipoEventoTile),
        ],
      ),
    );
  }

  Widget _buildTipoEventoTile(Map<String, dynamic> te) {
    final nome = te['nome'] ?? 'Sem nome';
    final codigo = te['codigo'] ?? '';
    final escopo = te['escopo'] ?? 'ATLETA';
    final impacta = te['impactaPlacar'] == true;
    final pPro = te['pontosPro'];
    final pContra = te['pontosContra'];
    
    Color escopoColor = Colors.blue;
    if (escopo == 'PARTIDA') escopoColor = Colors.purple;
    if (escopo == 'EQUIPE') escopoColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: escopoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: escopoColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        escopo,
                        style: TextStyle(color: escopoColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(codigo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                if (impacta) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Impacta placar (Pró: ${pPro ?? 0}, Contra: ${pContra ?? 0})',
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ]
              ],
            ),
          ),
          IconButton(
            onPressed: () => _excluirTipoEvento(te['id'], nome),
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }
}
