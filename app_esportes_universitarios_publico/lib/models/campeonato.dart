class Campeonato {
  final String id;
  final String nome;
  final String status;
  final String? edicao;
  final String? escudoUrl;
  final String? dataInicio;
  final String? dataFim;
  final List<CampeonatoModalidade> modalidades;

  Campeonato({
    required this.id,
    required this.nome,
    required this.status,
    this.edicao,
    this.escudoUrl,
    this.dataInicio,
    this.dataFim,
    this.modalidades = const [],
  });

  factory Campeonato.fromJson(Map<String, dynamic> json) {
    return Campeonato(
      id: json['id'],
      nome: json['nome'],
      status: json['status'],
      edicao: json['edicao'],
      escudoUrl: json['escudoUrl'],
      dataInicio: json['dataInicio'],
      dataFim: json['dataFim'],
      modalidades: [],
    );
  }

  /// Construído a partir de um registro retornado pelo endpoint /favorites
  factory Campeonato.fromFavoriteJson(Map<String, dynamic> json) {
    return Campeonato(
      id: json['campeonatoId'] as String,
      nome: json['label'] as String? ?? '',
      status: 'EM_ANDAMENTO',
    );
  }
}

class CampeonatoModalidade {
  final String id;
  final String campeonatoId;
  final String? campeonatoNome;
  final String modalidadeId;
  final String modalidadeNome;
  final String? esporteId;
  final String? esporteNome;
  final String? nomeExibicao;
  final String? genero;
  final String status;

  CampeonatoModalidade({
    required this.id,
    required this.campeonatoId,
    this.campeonatoNome,
    required this.modalidadeId,
    required this.modalidadeNome,
    this.esporteId,
    this.esporteNome,
    this.nomeExibicao,
    this.genero,
    required this.status,
  });

  factory CampeonatoModalidade.fromJson(Map<String, dynamic> json) {
    return CampeonatoModalidade(
      id: json['id'],
      campeonatoId: json['campeonatoId'] ?? '',
      campeonatoNome: json['campeonatoNome'],
      // O backend retorna modalidadeCatalogoId no ModalidadeResponse
      modalidadeId: json['modalidadeCatalogoId'] ?? json['modalidadeId'] ?? '',
      modalidadeNome: json['nome'] ?? json['modalidadeNome'] ?? '',
      esporteId: json['esporteId']?.toString(),
      esporteNome: json['esporteNome'],
      nomeExibicao: json['nomeExibicao'],
      genero: json['genero'] ?? json['generoCatalogo'],
      status: json['status'] ?? 'ATIVA',
    );
  }

  String get generoLabel {
    if (genero == 'M') return 'Masculino';
    if (genero == 'F') return 'Feminino';
    return 'Misto';
  }
}
