class AtleticaMembro {
  final String id;
  final String atleticaId;
  final String userId;
  final String nomeExibicao;
  final String? email;
  final String? telefone;
  final String? fotoUrl;
  final String papelCodigo;
  final String status;

  const AtleticaMembro({
    required this.id,
    required this.atleticaId,
    required this.userId,
    required this.nomeExibicao,
    this.email,
    this.telefone,
    this.fotoUrl,
    required this.papelCodigo,
    required this.status,
  });

  String get papelLabel {
    switch (papelCodigo.toUpperCase()) {
      case 'PRESIDENT':
        return 'Presidente';
      case 'DIRECTOR':
        return 'Dirigente';
      default:
        return papelCodigo;
    }
  }

  String get statusNormalizado => status.trim().toUpperCase();

  String get statusLabel {
    switch (statusNormalizado) {
      case 'CONVOCADO':
        return 'Convocado';
      case 'ATIVO':
        return 'Ativo';
      case 'RECUSADO':
        return 'Recusado';
      case 'INATIVO':
        return 'Inativo';
      default:
        return status;
    }
  }

  factory AtleticaMembro.fromMap(Map<String, dynamic> map) {
    return AtleticaMembro(
      id: map['id']?.toString() ?? '',
      atleticaId: map['atleticaId']?.toString() ?? map['atletica_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      nomeExibicao: map['nomeExibicao']?.toString() ?? map['nome_exibicao']?.toString() ?? 'Usuário',
      email: map['email']?.toString(),
      telefone: map['telefone']?.toString(),
      fotoUrl: map['fotoUrl']?.toString() ?? map['foto_url']?.toString(),
      papelCodigo: map['papelCodigo']?.toString() ?? map['papel_codigo']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }
}
