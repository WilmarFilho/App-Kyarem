class Atleta {
  final String id;
  final String atleticaId;
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
    // Suporta tanto o formato legado (atleta direto com 'id')
    // quanto o formato do schema public:
    //   - perfis_atletas: 'atleta_id', 'nome_exibicao', 'foto_url', 'atletica_atual_id', 'atletica_atual_nome'
    //   - campeonato_atletas_publicos aninhado
    final id = (map['atleta_id'] ?? map['id'] ?? '').toString();
    final atleticaId = (
      map['atletica_id'] ??
      map['atletica_atual_id'] ??
      ''
    ).toString();
    final nome = (
      map['nome_exibicao'] ??
      map['nome'] ??
      'Atleta'
    ).toString();
    final nomeAtletica = (
      map['atletica_atual_nome'] ??
      map['atleticas']?['nome']
    )?.toString();
    final fotoUrl = (map['foto_url'] ?? map['avatar_url'])?.toString();
    final criadoEm = map['criado_em'] != null
        ? DateTime.tryParse(map['criado_em'].toString())
        : null;

    return Atleta(
      id: id,
      atleticaId: atleticaId,
      nome: nome,
      criadoEm: criadoEm,
      nomeAtletica: nomeAtletica,
      fotoUrl: fotoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {'atletica_id': atleticaId, 'nome': nome, 'foto_url': fotoUrl};
  }
}
