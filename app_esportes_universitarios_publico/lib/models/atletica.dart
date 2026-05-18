class Atletica {
  final String id;
  final String name;
  final String? sigla;
  final String? corPrincipal;
  final String? escudoUrl;
  final String status;

  Atletica({
    required this.id,
    required this.name,
    this.sigla,
    this.corPrincipal,
    this.escudoUrl,
    required this.status,
  });

  factory Atletica.fromJson(Map<String, dynamic> json) {
    return Atletica(
      id: json['id'] as String,
      name: json['nome'] as String,
      sigla: json['sigla'] as String?,
      corPrincipal: json['corPrincipal'] as String?,
      escudoUrl: json['escudoUrl'] as String?,
      status: json['status'] as String,
    );
  }

  /// Alias para compatibilidade — a API retorna o campo como 'nome'
  String get nome => name;
}


class MinhaAtletica {
  final String id;
  final String? atleticaId;
  final String? atleticaNome;
  final String? atleticaEscudoUrl;
  final String papelCodigo;
  final String status;

  MinhaAtletica({
    required this.id,
    this.atleticaId,
    this.atleticaNome,
    this.atleticaEscudoUrl,
    required this.papelCodigo,
    required this.status,
  });

  factory MinhaAtletica.fromJson(Map<String, dynamic> json) {
    return MinhaAtletica(
      id: json['id'] as String,
      atleticaId: json['atleticaId'] as String?,
      atleticaNome: json['atleticaNome'] as String?,
      atleticaEscudoUrl: json['atleticaEscudoUrl'] as String?,
      papelCodigo: json['papelCodigo'] as String,
      status: json['status'] as String,
    );
  }
}
