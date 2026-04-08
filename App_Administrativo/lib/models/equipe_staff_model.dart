class EquipeStaff {
  final String id;
  final String equipeId;
  final String nome;
  final String cargo;
  final DateTime? criadoEm;

  EquipeStaff({
    required this.id,
    required this.equipeId,
    required this.nome,
    required this.cargo,
    this.criadoEm,
  });

  factory EquipeStaff.fromMap(Map<String, dynamic> map) {
    return EquipeStaff(
      id: map['id']?.toString() ?? '',
      equipeId: map['equipe_id']?.toString() ?? map['equipeId']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      cargo: map['cargo']?.toString() ?? '',
      criadoEm: map['criado_em'] != null
          ? DateTime.tryParse(map['criado_em'].toString())
          : (map['criadoEm'] != null
              ? DateTime.tryParse(map['criadoEm'].toString())
              : null),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'equipe_id': equipeId,
      'nome': nome,
      'cargo': cargo,
    };
  }
}
