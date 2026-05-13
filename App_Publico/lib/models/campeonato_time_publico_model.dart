class CampeonatoTimePublico {
  final String campeonatoTimeId;
  final String campeonatoId;
  final String campeonatoAtleticaId;
  final String atleticaId;
  final String campeonatoModalidadeId;
  final String nomeEquipe;
  final String? modalidadeNome;
  final String? modalidadeGenero;
  final String status;

  CampeonatoTimePublico({
    required this.campeonatoTimeId,
    required this.campeonatoId,
    required this.campeonatoAtleticaId,
    required this.atleticaId,
    required this.campeonatoModalidadeId,
    required this.nomeEquipe,
    this.modalidadeNome,
    this.modalidadeGenero,
    required this.status,
  });

  factory CampeonatoTimePublico.fromMap(Map<String, dynamic> map) {
    return CampeonatoTimePublico(
      campeonatoTimeId:
          (map['campeonato_time_id'] ?? map['campeonatoTimeId'] ?? '')
              .toString(),
      campeonatoId:
          (map['campeonato_id'] ?? map['campeonatoId'] ?? '').toString(),
      campeonatoAtleticaId:
          (map['campeonato_atletica_id'] ??
                  map['campeonatoAtleticaId'] ??
                  '')
              .toString(),
      atleticaId: (map['atletica_id'] ?? map['atleticaId'] ?? '').toString(),
      campeonatoModalidadeId:
          (map['campeonato_modalidade_id'] ??
                  map['campeonatoModalidadeId'] ??
                  '')
              .toString(),
      nomeEquipe:
          (map['nome_equipe'] ?? map['nomeEquipe'] ?? 'Equipe').toString(),
      modalidadeNome:
          (map['modalidade_nome'] ?? map['modalidadeNome'])?.toString(),
      modalidadeGenero:
          (map['modalidade_genero'] ?? map['modalidadeGenero'])?.toString(),
      status: (map['status'] ?? '').toString(),
    );
  }
}
