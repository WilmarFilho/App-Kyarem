class AtleticaMembro {
  final String id;
  final String atleticaId;
  final String userId;
  final String? nomeExibicao;
  final String? email;
  final String? telefone;
  final String? fotoUrl;
  final String papelCodigo;
  final String status;
  final String criadoEm;

  AtleticaMembro({
    required this.id,
    required this.atleticaId,
    required this.userId,
    this.nomeExibicao,
    this.email,
    this.telefone,
    this.fotoUrl,
    required this.papelCodigo,
    required this.status,
    required this.criadoEm,
  });

  factory AtleticaMembro.fromJson(Map<String, dynamic> json) {
    return AtleticaMembro(
      id: json['id'],
      atleticaId: json['atleticaId'],
      userId: json['userId'],
      nomeExibicao: json['nomeExibicao'],
      email: json['email'],
      telefone: json['telefone'],
      fotoUrl: json['fotoUrl'],
      papelCodigo: json['papelCodigo'],
      status: json['status'],
      criadoEm: json['criadoEm'],
    );
  }

  String get papelLabel {
    switch (papelCodigo.toUpperCase()) {
      case 'ATHLETE':
        return 'Atleta';
      case 'DIRECTOR':
        return 'Diretor';
      case 'PRESIDENT':
        return 'Presidente';
      case 'COACH':
        return 'Técnico';
      default:
        return papelCodigo;
    }
  }
}
