class ModalidadeCampeonato {
  final String id;
  final String campeonatoId;
  final String? campeonatoNome;
  final String modalidadeCatalogoId;
  final String? esporteId;
  final String? esporteNome;
  final String? nomeCatalogo;
  final String? slug;
  final String? generoCatalogo;
  final String? nomeExibicao;
  final String? categoria;
  final String? genero;
  final int? tempoPartidaMinutos;
  final bool permiteProrrogacao;
  final bool permitePenaltis;
  final String? status;

  const ModalidadeCampeonato({
    required this.id,
    required this.campeonatoId,
    required this.modalidadeCatalogoId,
    this.campeonatoNome,
    this.esporteId,
    this.esporteNome,
    this.nomeCatalogo,
    this.slug,
    this.generoCatalogo,
    this.nomeExibicao,
    this.categoria,
    this.genero,
    this.tempoPartidaMinutos,
    this.permiteProrrogacao = false,
    this.permitePenaltis = false,
    this.status,
  });

  factory ModalidadeCampeonato.fromMap(Map<String, dynamic> map) {
    return ModalidadeCampeonato(
      id: map['id']?.toString() ?? '',
      campeonatoId: map['campeonatoId']?.toString() ?? '',
      campeonatoNome: map['campeonatoNome']?.toString(),
      modalidadeCatalogoId: map['modalidadeCatalogoId']?.toString() ?? '',
      esporteId: map['esporteId']?.toString(),
      esporteNome: map['esporteNome']?.toString(),
      nomeCatalogo: map['nome']?.toString(),
      slug: map['slug']?.toString(),
      generoCatalogo: map['generoCatalogo']?.toString(),
      nomeExibicao: map['nomeExibicao']?.toString(),
      categoria: map['categoria']?.toString(),
      genero: map['genero']?.toString(),
      tempoPartidaMinutos: map['tempoPartidaMinutos'] is num
          ? (map['tempoPartidaMinutos'] as num).toInt()
          : int.tryParse(map['tempoPartidaMinutos']?.toString() ?? ''),
      permiteProrrogacao: map['permiteProrrogacao'] == true,
      permitePenaltis: map['permitePenaltis'] == true,
      status: map['status']?.toString(),
    );
  }
}
