class ModalidadeCatalogo {
  final String id;
  final String nome;
  final String genero;

  ModalidadeCatalogo({
    required this.id,
    required this.nome,
    required this.genero,
  });

  factory ModalidadeCatalogo.fromJson(Map<String, dynamic> json) {
    return ModalidadeCatalogo(
      id: json['id'],
      nome: json['nome'],
      genero: json['genero'],
    );
  }
}
