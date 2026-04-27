class Modalidade {
  final String id;
  final String campeonatoId;
  final String modalidadeCatalogoId;
  final String esporteId;
  final String genero;
  final String? esporteNome;
  final String? nomeExibicao;
  final String? faseAtual;

  String get nome => nomeExibicao ?? esporteNome ?? '';

  Modalidade({
    required this.id,
    required this.campeonatoId,
    this.modalidadeCatalogoId = '',
    required this.esporteId,
    required this.genero,
    this.esporteNome,
    this.nomeExibicao,
    this.faseAtual,
  });

  factory Modalidade.fromMap(Map<String, dynamic> map) {
    return Modalidade(
      id: (map['id'] ?? '').toString(),
      campeonatoId: (map['campeonatoId'] ?? map['campeonato_id'] ?? '').toString(),
      modalidadeCatalogoId: (map['modalidadeCatalogoId'] ?? map['modalidade_catalogo_id'] ?? '').toString(),
      esporteId: (map['esporteId'] ?? map['esporte_id'] ?? '').toString(),
      genero: (map['genero'] ?? '').toString(),
      esporteNome: (map['esporteNome'] ?? map['esporte_nome'] ?? map['esportes']?['nome'])?.toString(),
      nomeExibicao: (map['nome'] ?? map['nomeExibicao'] ?? map['nome_exibicao'])?.toString(),
      faseAtual: (map['faseAtual'] ?? map['fase_atual'])?.toString(),
    );
  }
}
