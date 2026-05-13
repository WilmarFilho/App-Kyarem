class Esporte {
  final String id;
  final String nome;
  final DateTime? criadoEm;

  Esporte({
    required this.id,
    required this.nome,
    this.criadoEm,
  });

  // Transforma o JSON do Supabase em um Objeto Dart
  factory Esporte.fromMap(Map<String, dynamic> map) {
    return Esporte(
      id: map['id'],
      nome: map['nome'],
      criadoEm: map['criado_em'] != null 
          ? DateTime.parse(map['criado_em']) 
          : null,
    );
  }

  // Transforma o Objeto Dart em JSON para enviar ao Supabase (se necessário)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }
}