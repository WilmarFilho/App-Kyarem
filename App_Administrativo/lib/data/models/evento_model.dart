class Evento {
  final String id;
  final String sumulaId;
  final String atletaNome;
  final String tipo; // 'GOL', 'FALTA', 'AMARELO', 'VERMELHO'
  final String time; // 'A' ou 'B'
  final DateTime timestamp;
  final bool sincronizado;

  Evento({
    required this.id,
    required this.sumulaId,
    required this.atletaNome,
    required this.tipo,
    required this.time,
    required this.timestamp,
    this.sincronizado = false,
  });

  // Para converter o que vem do SQLite em Objeto
  factory Evento.fromMap(Map<String, dynamic> map) {
    return Evento(
      id: map['id'],
      sumulaId: map['sumula_id'],
      atletaNome: map['atleta_id'], // No banco salvamos o nome na coluna atleta_id
      tipo: map['tipo'],
      time: map['time'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      sincronizado: map['sincronizado'] == 1,
    );
  }

  // Para converter o Objeto em Map antes de salvar no SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sumula_id': sumulaId,
      'atleta_id': atletaNome,
      'tipo': tipo,
      'time': time,
      'timestamp': timestamp.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }
}