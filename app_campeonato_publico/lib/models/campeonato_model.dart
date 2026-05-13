class Campeonato {
  final String id;
  final String nome;
  final String? nivel;
  final DateTime? dataInicio;
  final String? escudoUrl;
  final DateTime? dataFim;

  Campeonato({
    required this.id,
    required this.nome,
    this.nivel,
    this.dataInicio,
    this.escudoUrl,
    this.dataFim,
  });

  factory Campeonato.fromMap(Map<String, dynamic> map) {
    return Campeonato(
      id: (map['campeonato_id'] ?? map['id'] ?? '').toString(),
      nome: (map['nome'] ?? 'Sem nome').toString(),
      escudoUrl: (map['escudo_url'] ?? map['escudoUrl'])?.toString(),
      // API: nivelCampeonato | Supabase: nivel_campeonato
      nivel: (map['nivelCampeonato'] ?? map['nivel_campeonato'])?.toString(),
      dataInicio: _parseDate(map['data_inicio'] ?? map['dataInicio']),
      dataFim: _parseDate(map['data_fim'] ?? map['dataFim']),
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}
