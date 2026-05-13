class Arbitro {
  final String id;
  final String nome;
  final String? fotoUrl;

  Arbitro({required this.id, required this.nome, this.fotoUrl});

  factory Arbitro.fromMap(Map<String, dynamic> map) {
    return Arbitro(
      id: map['id'],
      nome: map['nome'],
      fotoUrl: map['foto_url'],
    );
  }
}