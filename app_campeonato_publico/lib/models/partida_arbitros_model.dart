class PartidaArbitro {
  final String id;
  final String partidaId;
  final String arbitroId;
  final String funcao; // Ex: Árbitro Principal, Mesário, Delegado
  
  // Dados extras carregados via Join (opcional, mas recomendado para a UI)
  final String? nomeArbitro;
  final String? fotoArbitro;

  PartidaArbitro({
    required this.id,
    required this.partidaId,
    required this.arbitroId,
    required this.funcao,
    this.nomeArbitro,
    this.fotoArbitro,
  });

  factory PartidaArbitro.fromMap(Map<String, dynamic> map) {
    return PartidaArbitro(
      id: map['id'],
      partidaId: map['partida_id'],
      arbitroId: map['arbitro_id'],
      funcao: map['funcao'],
      // Mapeamento dos dados vindos da tabela 'profiles' via join no Supabase
      nomeArbitro: map['profiles']?['nome_exibicao'],
      fotoArbitro: map['profiles']?['foto_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partida_id': partidaId,
      'arbitro_id': arbitroId,
      'funcao': funcao,
    };
  }
}