class Campeonato {
  final String id;
  final String nome;
  final String? nivel;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? escudoUrl;
  final String? status;

  Campeonato({
    required this.id,
    required this.nome,
    this.nivel,
    this.dataInicio,
    this.dataFim,
    this.escudoUrl,
    this.status,
  });

  factory Campeonato.fromMap(Map<String, dynamic> map) {
    return Campeonato(
      id: map['id'] ?? '',
      nome: map['nome'] ?? 'Sem nome',
      
      // Suporta 'nivel' (API) ou 'nivel_campeonato' (Supabase)
      nivel: map['nivel'] ?? map['nivelCampeonato'] ?? map['nivel_campeonato'],
      
      // Tratamento de data para 'dataInicio' (API) ou 'data_inicio' (Supabase)
      dataInicio: _parseDate(map['dataInicio'] ?? map['data_inicio']),
      
      // Tratamento de data para 'dataFim' (API) ou 'data_fim' (Supabase)
      dataFim: _parseDate(map['dataFim'] ?? map['data_fim']),
      escudoUrl: map['escudoUrl'] ?? map['escudo_url'],
      status: map['status'],
    );
  }

  // Função auxiliar estática para evitar erro de parse caso a data venha mal formatada ou nula
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    return DateTime.tryParse(date.toString());
  }
}