class ModalidadeCatalogo {
  final String id;
  final String esporteId;
  final String? esporteNome;
  final String nome;
  final String slug;
  final String genero;
  final String motorRegras;
  final bool ativo;

  const ModalidadeCatalogo({
    required this.id,
    required this.esporteId,
    this.esporteNome,
    required this.nome,
    required this.slug,
    required this.genero,
    required this.motorRegras,
    required this.ativo,
  });

  factory ModalidadeCatalogo.fromMap(Map<String, dynamic> map) {
    return ModalidadeCatalogo(
      id: map['id']?.toString() ?? '',
      esporteId: map['esporteId']?.toString() ?? map['esporte_id']?.toString() ?? '',
      esporteNome: map['esporteNome']?.toString() ?? map['esporte_nome']?.toString(),
      nome: map['nome']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      genero: map['genero']?.toString() ?? '',
      motorRegras: map['motorRegras']?.toString() ?? map['motor_regras']?.toString() ?? '',
      ativo: map['ativo'] == null ? true : map['ativo'] == true,
    );
  }
}
