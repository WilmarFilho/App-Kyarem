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
}
