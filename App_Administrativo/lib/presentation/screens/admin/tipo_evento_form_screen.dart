import 'package:flutter/material.dart';

class _TipoEventoSugestao {
  final String codigo;
  final String nome;
  final String escopo;
  final bool impactaPlacar;
  final int? pontosPro;
  final int? pontosContra;

  const _TipoEventoSugestao({
    required this.codigo,
    required this.nome,
    required this.escopo,
    this.impactaPlacar = false,
    this.pontosPro,
    this.pontosContra,
  });
}

// MAPA DE SUGESTÕES — adicione novos esportes aqui
const Map<String, List<_TipoEventoSugestao>> _sugestoesPorMotor = {
  'FUTSAL_V1': [
    _TipoEventoSugestao(codigo: 'INICIO_1_TEMPO', nome: 'Início 1º Tempo', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'FIM_1_TEMPO', nome: 'Fim 1º Tempo', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'INICIO_2_TEMPO', nome: 'Início 2º Tempo', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'FIM_2_TEMPO', nome: 'Fim 2º Tempo', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'GOL', nome: 'Gol', escopo: 'ATLETA', impactaPlacar: true, pontosPro: 1),
    _TipoEventoSugestao(codigo: 'GOL_CONTRA', nome: 'Gol Contra', escopo: 'ATLETA', impactaPlacar: true, pontosContra: 1),
    _TipoEventoSugestao(codigo: 'CARTAO_AMARELO', nome: 'Cartão Amarelo', escopo: 'ATLETA'),
    _TipoEventoSugestao(codigo: 'CARTAO_VERMELHO', nome: 'Cartão Vermelho', escopo: 'ATLETA'),
    _TipoEventoSugestao(codigo: 'SUBSTITUICAO', nome: 'Substituição', escopo: 'ATLETA'),
    _TipoEventoSugestao(codigo: 'TIMEOUT', nome: 'Pedido de Tempo', escopo: 'EQUIPE'),
  ],
  'VOLEI_V1': [
    _TipoEventoSugestao(codigo: 'INICIO_SET', nome: 'Início Set', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'FIM_SET', nome: 'Fim Set', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'PONTO', nome: 'Ponto', escopo: 'ATLETA', impactaPlacar: true, pontosPro: 1),
    _TipoEventoSugestao(codigo: 'ERRO_SAQUE', nome: 'Erro de Saque', escopo: 'ATLETA', impactaPlacar: true, pontosContra: 1),
    _TipoEventoSugestao(codigo: 'SUBSTITUICAO', nome: 'Substituição', escopo: 'ATLETA'),
    _TipoEventoSugestao(codigo: 'TIMEOUT', nome: 'Pedido de Tempo', escopo: 'EQUIPE'),
  ],
  'BASQUETE_V1': [
    _TipoEventoSugestao(codigo: 'INICIO_1_QUARTO', nome: 'Início 1º Quarto', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'FIM_1_QUARTO', nome: 'Fim 1º Quarto', escopo: 'PARTIDA'),
    _TipoEventoSugestao(codigo: 'CESTA_1', nome: 'Cesta (1 pt)', escopo: 'ATLETA', impactaPlacar: true, pontosPro: 1),
    _TipoEventoSugestao(codigo: 'CESTA_2', nome: 'Cesta (2 pts)', escopo: 'ATLETA', impactaPlacar: true, pontosPro: 2),
    _TipoEventoSugestao(codigo: 'CESTA_3', nome: 'Cesta (3 pts)', escopo: 'ATLETA', impactaPlacar: true, pontosPro: 3),
    _TipoEventoSugestao(codigo: 'FALTA', nome: 'Falta', escopo: 'ATLETA'),
    _TipoEventoSugestao(codigo: 'TIMEOUT', nome: 'Pedido de Tempo', escopo: 'EQUIPE'),
  ],
};

class TipoEventoFormScreen extends StatefulWidget {
  final String modalidadeCatalogoId;
  final String motorRegras;

  const TipoEventoFormScreen({
    super.key,
    required this.modalidadeCatalogoId,
    required this.motorRegras,
  });

  @override
  State<TipoEventoFormScreen> createState() => _TipoEventoFormScreenState();
}

class _TipoEventoFormScreenState extends State<TipoEventoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _pontosProController = TextEditingController();
  final _pontosContraController = TextEditingController();
  final _ordemExibicaoController = TextEditingController();

  String _escopoSelecionado = 'ATLETA';
  bool _impactaPlacar = false;

  void _preencherSugestao(_TipoEventoSugestao sugestao) {
    setState(() {
      _codigoController.text = sugestao.codigo;
      _nomeController.text = sugestao.nome;
      _escopoSelecionado = sugestao.escopo;
      _impactaPlacar = sugestao.impactaPlacar;
      _pontosProController.text = sugestao.pontosPro?.toString() ?? '';
      _pontosContraController.text = sugestao.pontosContra?.toString() ?? '';
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'codigo': _codigoController.text.trim().toUpperCase(),
      'nome': _nomeController.text.trim(),
      'escopo': _escopoSelecionado,
      'impactaPlacar': _impactaPlacar,
      'pontosPro': int.tryParse(_pontosProController.text),
      'pontosContra': int.tryParse(_pontosContraController.text),
      'ordemExibicao': int.tryParse(_ordemExibicaoController.text),
    };

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final sugestoes = _sugestoesPorMotor[widget.motorRegras] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Novo Tipo de Evento', style: TextStyle(color: Colors.white, fontFamily: 'Bebas Neue', fontSize: 22)),
        backgroundColor: const Color(0xFFF85C39),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sugestoes.isNotEmpty) ...[
                const Text(
                  'Sugestões para esta modalidade',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF85C39)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sugestoes.map((s) {
                    return ActionChip(
                      label: Text(s.nome, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFF85C39)),
                      onPressed: () => _preencherSugestao(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código (ex: GOL, INICIO_PARTIDA)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome para exibição (ex: Gol, Início da Partida)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _escopoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Escopo do Evento',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ATLETA', child: Text('Ação de um Atleta (ex: Gol, Falta)')),
                  DropdownMenuItem(value: 'EQUIPE', child: Text('Ação de uma Equipe (ex: Timeout)')),
                  DropdownMenuItem(value: 'PARTIDA', child: Text('Controle de Partida (ex: Início/Fim de tempo)')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _escopoSelecionado = v;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Impacta no placar?'),
                subtitle: const Text('Este evento altera a pontuação do jogo'),
                value: _impactaPlacar,
                activeColor: const Color(0xFFF85C39),
                onChanged: (v) => setState(() => _impactaPlacar = v),
              ),
              if (_impactaPlacar) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pontosProController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pontos Pró',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _pontosContraController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pontos Contra',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _ordemExibicaoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordem de Exibição (opcional, para ordenação)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF85C39),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Salvar Tipo de Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
