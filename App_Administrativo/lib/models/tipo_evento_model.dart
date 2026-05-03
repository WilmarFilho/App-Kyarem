class TipoEventoEsporte {
  final String id;
  final String modalidadeCatalogoId;
  final String codigo;
  final String nome;
  final String escopo;
  final bool impactaPlacar;
  final int? pontosPro;
  final int? pontosContra;
  final int? ordemExibicao;
  final int? idx;

  TipoEventoEsporte({
    required this.id,
    this.modalidadeCatalogoId = '',
    this.codigo = '',
    required this.nome,
    this.escopo = 'ATLETA',
    this.impactaPlacar = false,
    this.pontosPro,
    this.pontosContra,
    this.ordemExibicao,
    this.idx,
  });

  factory TipoEventoEsporte.fromMap(Map<String, dynamic> json) {
    final ordem = json['ordemExibicao'] ?? json['ordem_exibicao'] ?? json['idx'];
    return TipoEventoEsporte(
      id: json['id'] as String? ?? '',
      modalidadeCatalogoId:
          (json['modalidadeCatalogoId'] ?? json['modalidade_catalogo_id'] ?? '')
              .toString(),
      codigo: (json['codigo'] ?? json['nome'] ?? '').toString(),
      nome: json['nome'] as String? ?? '',
      escopo: (json['escopo'] ?? 'ATLETA').toString(),
      impactaPlacar: json['impactaPlacar'] == true || json['impacta_placar'] == true,
      pontosPro: json['pontosPro'] is num
          ? (json['pontosPro'] as num).toInt()
          : int.tryParse(json['pontosPro']?.toString() ?? ''),
      pontosContra: json['pontosContra'] is num
          ? (json['pontosContra'] as num).toInt()
          : int.tryParse(json['pontosContra']?.toString() ?? ''),
      ordemExibicao: ordem is num ? ordem.toInt() : int.tryParse(ordem?.toString() ?? ''),
      idx: json['idx'] is num ? (json['idx'] as num).toInt() : int.tryParse(json['idx']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modalidadeCatalogoId': modalidadeCatalogoId,
      'codigo': codigo,
      'nome': nome,
      'escopo': escopo,
      'impactaPlacar': impactaPlacar,
      'pontosPro': pontosPro,
      'pontosContra': pontosContra,
      'ordemExibicao': ordemExibicao,
      if (idx != null) 'idx': idx,
    };
  }

  String get nomeFormatado {
    if (nome.isEmpty) return "";

    String formatada = nome.replaceAll('_', ' ').toLowerCase();
    return formatada.replaceFirst(formatada[0], formatada[0].toUpperCase());
  }

  bool get isEventoDePartida => escopo.toUpperCase() == 'PARTIDA';
  bool get isEventoDeEquipe => escopo.toUpperCase() == 'EQUIPE';
  bool get isEventoDeAtleta => escopo.toUpperCase() == 'ATLETA';

  factory TipoEventoEsporte.fromJson(Map<String, dynamic> json) => TipoEventoEsporte.fromMap(json);
}
