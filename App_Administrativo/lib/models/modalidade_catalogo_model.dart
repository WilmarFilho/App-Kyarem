class ModalidadeCatalogo {
  final String id;
  final String esporteId;
  final String? esporteNome;
  final String nome;
  final String slug;
  final String genero;
  final String motorRegras;
  final Map<String, dynamic>? regrasBaseJson;
  final bool ativo;

  const ModalidadeCatalogo({
    required this.id,
    required this.esporteId,
    this.esporteNome,
    required this.nome,
    required this.slug,
    required this.genero,
    required this.motorRegras,
    this.regrasBaseJson,
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
      regrasBaseJson: map['regrasBaseJson'] is Map<String, dynamic>
          ? map['regrasBaseJson'] as Map<String, dynamic>
          : map['motorConfigsDefault'] is Map<String, dynamic>
          ? map['motorConfigsDefault'] as Map<String, dynamic>
          : null,
      ativo: map['ativo'] == null ? true : map['ativo'] == true,
    );
  }
}
