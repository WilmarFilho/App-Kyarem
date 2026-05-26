class PartidaFeedItem {
  final String id;
  final String modalidadeId;
  final String modalidadeNome;
  final String esporteNome;
  final String campeonatoId;
  final String campeonatoNome;
  final String? campeonatoEscudoUrl;
  final String timeA;
  final String timeB;
  final String? atleticaNomeA;
  final String? atleticaNomeB;
  final String? atleticaEscudoUrlA;
  final String? atleticaEscudoUrlB;
  final String status;
  final DateTime? agendadoPara;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final String? local;
  final String? categoria;
  final String? fase;
  final int placarA;
  final int placarB;

  const PartidaFeedItem({
    required this.id,
    required this.modalidadeId,
    required this.modalidadeNome,
    required this.esporteNome,
    required this.campeonatoId,
    required this.campeonatoNome,
    this.campeonatoEscudoUrl,
    required this.timeA,
    required this.timeB,
    this.atleticaNomeA,
    this.atleticaNomeB,
    this.atleticaEscudoUrlA,
    this.atleticaEscudoUrlB,
    required this.status,
    this.agendadoPara,
    this.iniciadaEm,
    this.encerradaEm,
    this.local,
    this.categoria,
    this.fase,
    required this.placarA,
    required this.placarB,
  });

  bool get isLive {
    final normalized = status.trim().toUpperCase();
    return normalized == 'EM_ANDAMENTO' ||
        normalized == 'INICIADA' ||
        normalized == 'AO_VIVO';
  }

  factory PartidaFeedItem.fromJson(Map<String, dynamic> json) {
    return PartidaFeedItem(
      id: json['id'] as String? ?? '',
      modalidadeId: json['modalidadeId'] as String? ?? '',
      modalidadeNome: json['modalidadeNome'] as String? ?? '',
      esporteNome: json['esporteNome'] as String? ?? '',
      campeonatoId: json['campeonatoId'] as String? ?? '',
      campeonatoNome: json['campeonatoNome'] as String? ?? '',
      campeonatoEscudoUrl: json['campeonatoEscudoUrl'] as String?,
      timeA: json['timeA'] as String? ?? 'Time A',
      timeB: json['timeB'] as String? ?? 'Time B',
      atleticaNomeA: json['atleticaNomeA'] as String?,
      atleticaNomeB: json['atleticaNomeB'] as String?,
      atleticaEscudoUrlA: json['atleticaEscudoUrlA'] as String?,
      atleticaEscudoUrlB: json['atleticaEscudoUrlB'] as String?,
      status: json['status'] as String? ?? 'AGENDADA',
      agendadoPara: json['agendadoPara'] != null
          ? DateTime.tryParse(json['agendadoPara'] as String)
          : null,
      iniciadaEm: json['iniciadaEm'] != null
          ? DateTime.tryParse(json['iniciadaEm'] as String)
          : null,
      encerradaEm: json['encerradaEm'] != null
          ? DateTime.tryParse(json['encerradaEm'] as String)
          : null,
      local: json['local'] as String?,
      categoria: json['categoria'] as String?,
      fase: json['fase'] as String?,
      placarA: json['placarA'] as int? ?? 0,
      placarB: json['placarB'] as int? ?? 0,
    );
  }

  /// Construído a partir de um registro retornado pelo endpoint /favorites
  /// O backend retorna apenas id e label; os demais campos ficam vazios
  /// até que a tela de detalhes carregue os dados completos.
  factory PartidaFeedItem.fromFavoriteJson(Map<String, dynamic> json) {
    return PartidaFeedItem(
      id: json['partidaId'] as String,
      modalidadeId: '',
      modalidadeNome: json['label'] as String? ?? 'Partida',
      esporteNome: '',
      campeonatoId: '',
      campeonatoNome: '',
      timeA: 'Time A',
      timeB: 'Time B',
      status: 'AGENDADA',
      placarA: 0,
      placarB: 0,
    );
  }
}
