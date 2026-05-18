class TimeAtletica {
  final String id;
  final String atleticaId;
  final String? atleticaNome;
  final String nome;
  final String modalidadeCatalogoId;
  final String? modalidadeNome;
  final String? genero;

  TimeAtletica({
    required this.id,
    required this.atleticaId,
    this.atleticaNome,
    required this.nome,
    required this.modalidadeCatalogoId,
    this.modalidadeNome,
    this.genero,
  });

  factory TimeAtletica.fromJson(Map<String, dynamic> json) {
    return TimeAtletica(
      id: json['id'],
      atleticaId: json['atleticaId'],
      atleticaNome: json['atleticaNome'],
      nome: json['nome'],
      modalidadeCatalogoId: json['modalidadeCatalogoId'],
      modalidadeNome: json['modalidadeNome'],
      genero: json['genero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'atleticaId': atleticaId,
      'atleticaNome': atleticaNome,
      'nome': nome,
      'modalidadeCatalogoId': modalidadeCatalogoId,
      'modalidadeNome': modalidadeNome,
      'genero': genero,
    };
  }
}
