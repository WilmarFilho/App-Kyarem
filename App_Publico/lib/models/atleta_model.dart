class Atleta {
  final String id;
  final String atleticaId; // Nome da variável
  final String nome;
  final DateTime? criadoEm;
  final String? nomeAtletica;
  final String? fotoUrl;

  Atleta({
    required this.id,
    required this.atleticaId,
    required this.nome,
    this.criadoEm,
    this.nomeAtletica,
    this.fotoUrl,
  });

  factory Atleta.fromMap(Map<String, dynamic> map) {
    return Atleta(
      id: map['id'],
      atleticaId:
          map['atletica_id'], // Aqui mapeia a chave do banco (com underline) para a variável (sem underline)
      nome: map['nome'],
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'])
          : null,
      nomeAtletica: map['atleticas']?['nome'],
      fotoUrl: map['foto_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'atletica_id': atleticaId, 'nome': nome, 'foto_url': fotoUrl};
  }
}
