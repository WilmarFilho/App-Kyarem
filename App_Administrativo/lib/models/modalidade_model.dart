class Modalidade {
  final String id;
  final String campeonatoId;
  final String esporteId;
  final String genero; // 'M' ou 'F'
  final String? esporteNome; // Join com a tabela 'esportes'
  
  String get nome => esporteNome ?? '';

  Modalidade({
    required this.id,
    required this.campeonatoId,
    required this.esporteId,
    required this.genero,
    this.esporteNome,
  });

  factory Modalidade.fromMap(Map<String, dynamic> map) {
    return Modalidade(
      id: map['id'],
      campeonatoId: map['campeonato_id'],
      esporteId: map['esporte_id'],
      genero: map['genero'],
      esporteNome: map['esportes']?['nome'],
    );
  }
}