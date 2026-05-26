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
    _TipoEventoSugestao(
      codigo: 'INICIO_1_TEMPO',
      nome: 'Início 1º Tempo',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'FIM_1_TEMPO',
      nome: 'Fim 1º Tempo',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'INICIO_2_TEMPO',
      nome: 'Início 2º Tempo',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'FIM_2_TEMPO',
      nome: 'Fim 2º Tempo',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'GOL',
      nome: 'Gol',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosPro: 1,
    ),
    _TipoEventoSugestao(
      codigo: 'GOL_CONTRA',
      nome: 'Gol Contra',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosContra: 1,
    ),
    _TipoEventoSugestao(
      codigo: 'CARTAO_AMARELO',
      nome: 'Cartão Amarelo',
      escopo: 'ATLETA',
    ),
    _TipoEventoSugestao(
      codigo: 'CARTAO_VERMELHO',
      nome: 'Cartão Vermelho',
      escopo: 'ATLETA',
    ),
    _TipoEventoSugestao(
      codigo: 'SUBSTITUICAO',
      nome: 'Substituição',
      escopo: 'ATLETA',
    ),
    _TipoEventoSugestao(
      codigo: 'TIMEOUT',
      nome: 'Pedido de Tempo',
      escopo: 'EQUIPE',
    ),
  ],
  'VOLEI_V1': [
    _TipoEventoSugestao(
      codigo: 'INICIO_SET',
      nome: 'Início Set',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(codigo: 'FIM_SET', nome: 'Fim Set', escopo: 'PARTIDA'),
    _TipoEventoSugestao(
      codigo: 'PONTO',
      nome: 'Ponto',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosPro: 1,
    ),
    _TipoEventoSugestao(
      codigo: 'ERRO_SAQUE',
      nome: 'Erro de Saque',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosContra: 1,
    ),
    _TipoEventoSugestao(
      codigo: 'SUBSTITUICAO',
      nome: 'Substituição',
      escopo: 'ATLETA',
    ),
    _TipoEventoSugestao(
      codigo: 'TIMEOUT',
      nome: 'Pedido de Tempo',
      escopo: 'EQUIPE',
    ),
  ],
  'BASQUETE_V1': [
    _TipoEventoSugestao(
      codigo: 'INICIO_1_QUARTO',
      nome: 'Início 1º Quarto',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'FIM_1_QUARTO',
      nome: 'Fim 1º Quarto',
      escopo: 'PARTIDA',
    ),
    _TipoEventoSugestao(
      codigo: 'CESTA_1',
      nome: 'Cesta (1 pt)',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosPro: 1,
    ),
    _TipoEventoSugestao(
      codigo: 'CESTA_2',
      nome: 'Cesta (2 pts)',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosPro: 2,
    ),
    _TipoEventoSugestao(
      codigo: 'CESTA_3',
      nome: 'Cesta (3 pts)',
      escopo: 'ATLETA',
      impactaPlacar: true,
      pontosPro: 3,
    ),
    _TipoEventoSugestao(codigo: 'FALTA', nome: 'Falta', escopo: 'ATLETA'),
    _TipoEventoSugestao(
      codigo: 'TIMEOUT',
      nome: 'Pedido de Tempo',
      escopo: 'EQUIPE',
    ),
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

  InputDecoration _customDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFFF85C39))
          : null,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF85C39), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sugestoes = _sugestoesPorMotor[widget.motorRegras] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Novo Tipo de Evento',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Bebas Neue',
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: const Color(0xFFF85C39),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sugestoes.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF85C39),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sugestões Inteligentes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: sugestoes.map((s) {
                        return GestureDetector(
                          onTap: () => _preencherSugestao(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFFF85C39,
                                ).withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              s.nome,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF85C39),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                Text(
                  'Informações Básicas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _codigoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _customDecoration(
                    'Código (ex: GOL, INICIO_PARTIDA)',
                    icon: Icons.code,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nomeController,
                  decoration: _customDecoration(
                    'Nome para exibição (ex: Gol)',
                    icon: Icons.text_fields,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo obrigatório' : null,
                ),

                const SizedBox(height: 32),
                Text(
                  'Escopo do Evento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEscopoSelector(),

                const SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Impacta no placar?',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Altera a pontuação da partida',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        value: _impactaPlacar,
                        activeColor: const Color(0xFFF85C39),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onChanged: (v) => setState(() => _impactaPlacar = v),
                      ),
                      if (_impactaPlacar) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pontosProController,
                                  keyboardType: TextInputType.number,
                                  decoration: _customDecoration(
                                    'Pontos Pró',
                                    icon: Icons.add_circle_outline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _pontosContraController,
                                  keyboardType: TextInputType.number,
                                  decoration: _customDecoration(
                                    'Pontos Contra',
                                    icon: Icons.remove_circle_outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextFormField(
                  controller: _ordemExibicaoController,
                  keyboardType: TextInputType.number,
                  decoration: _customDecoration(
                    'Ordem de Exibição (Opcional)',
                    icon: Icons.sort,
                  ),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF85C39),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(
                        0xFFF85C39,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'SALVAR EVENTO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEscopoSelector() {
    final Map<String, Map<String, dynamic>> opcoes = {
      'ATLETA': {
        'label': 'Atleta',
        'icon': Icons.person,
        'desc': 'Ação individual',
      },
      'EQUIPE': {
        'label': 'Equipe',
        'icon': Icons.groups,
        'desc': 'Ação do time',
      },
      'PARTIDA': {
        'label': 'Partida',
        'icon': Icons.sports,
        'desc': 'Controle de jogo',
      },
    };

    return Row(
      children: opcoes.entries.map((entry) {
        final key = entry.key;
        final data = entry.value;
        final isSelected = _escopoSelecionado == key;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _escopoSelecionado = key;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: key != 'PARTIDA' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF85C39) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF85C39)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF85C39).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['desc'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
