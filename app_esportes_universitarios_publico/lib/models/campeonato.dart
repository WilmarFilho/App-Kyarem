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
}

class CampeonatoModalidade {
  final String id;
  final String campeonatoId;
  final String modalidadeId;
  final String modalidadeNome;
  final String? genero;
  final String status;

  CampeonatoModalidade({
    required this.id,
    required this.campeonatoId,
    required this.modalidadeId,
    required this.modalidadeNome,
    this.genero,
    required this.status,
  });

  factory CampeonatoModalidade.fromJson(Map<String, dynamic> json) {
    return CampeonatoModalidade(
      id: json['id'],
      campeonatoId: json['campeonatoId'] ?? '',
      // O backend retorna modalidadeCatalogoId no ModalidadeResponse
      modalidadeId: json['modalidadeCatalogoId'] ?? json['modalidadeId'] ?? '',
      modalidadeNome: json['nome'] ?? json['modalidadeNome'] ?? '',
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
