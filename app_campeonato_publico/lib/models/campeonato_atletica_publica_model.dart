class CampeonatoAtleticaPublica {
  final String campeonatoAtleticaId;
  final String campeonatoId;
  final String atleticaId;
  final String nome;
  final String? sigla;
  final String? escudoUrl;
  final DateTime? criadoEm;

  CampeonatoAtleticaPublica({
    required this.campeonatoAtleticaId,
    required this.campeonatoId,
    required this.atleticaId,
    required this.nome,
    this.sigla,
    this.escudoUrl,
    this.criadoEm,
  });

  factory CampeonatoAtleticaPublica.fromMap(Map<String, dynamic> map) {
    return CampeonatoAtleticaPublica(
      campeonatoAtleticaId:
          (map['campeonato_atletica_id'] ?? map['campeonatoAtleticaId'] ?? '')
              .toString(),
      campeonatoId:
          (map['campeonato_id'] ?? map['campeonatoId'] ?? '').toString(),
      atleticaId: (map['atletica_id'] ?? map['atleticaId'] ?? '').toString(),
      nome: (map['atletica_nome'] ?? map['nome'] ?? 'Atlética').toString(),
      sigla: (map['atletica_sigla'] ?? map['sigla'])?.toString(),
      escudoUrl:
          (map['atletica_escudo_url'] ??
                  map['escudo_url'] ??
                  map['escudoUrl'])
              ?.toString(),
      criadoEm: _parseDate(map['criado_em'] ?? map['criadoEm']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class AtleticaStatsResumo {
  final int jogos;
  final int vitorias;
  final int empates;
  final int derrotas;
  final int golsPro;
  final int golsContra;

  const AtleticaStatsResumo({
    this.jogos = 0,
    this.vitorias = 0,
    this.empates = 0,
    this.derrotas = 0,
    this.golsPro = 0,
    this.golsContra = 0,
  });

  int get saldo => golsPro - golsContra;
}
