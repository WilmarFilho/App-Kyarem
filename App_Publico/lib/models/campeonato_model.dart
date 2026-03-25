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
      id: (map['id'] ?? '').toString(),
      nome: (map['nome'] ?? 'Sem nome').toString(),
      escudoUrl: (map['escudoUrl'] ?? map['escudo_url'])?.toString(),
      // API: nivelCampeonato | Supabase: nivel_campeonato
      nivel: (map['nivelCampeonato'] ?? map['nivel_campeonato'])?.toString(),
      dataInicio: _parseDate(map['dataInicio'] ?? map['data_inicio']),
      dataFim: _parseDate(map['dataFim'] ?? map['data_fim']),
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}
