import 'package:kyarem_eventos/models/atletica_equipe_model.dart';

class Partida {
  final String id;
  final String modalidadeId;
  final String status;
  final String? statusAntesPausa;
  final String? sumulaPdfUrl;
  final int placarA;
  final int placarB;
  final String equipeAId;
  final String equipeBId;
  final String? local;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final DateTime? agendadaPara;
  final Equipe? equipeA;
  final Equipe? equipeB;

  Partida({
    required this.id,
    required this.modalidadeId,
    required this.status,
    this.statusAntesPausa,
    this.sumulaPdfUrl,
    required this.equipeAId,
    required this.equipeBId,
    this.placarA = 0,
    this.placarB = 0,
    this.local,
    this.iniciadaEm,
    this.encerradaEm,
    this.agendadaPara,
    this.equipeA,
    this.equipeB,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    // A API agrupa os dados detalhados dentro de snapshotSumula
    final sumula = map['snapshotSumula'] as Map<String, dynamic>?;

    return Partida(
      id: map['id'] ?? '',
      modalidadeId: map['modalidadeId'] ?? '',
      status: map['status'],
      statusAntesPausa:
          (map['statusAntesPausa'] ?? map['status_antes_pausa'])?.toString(),
      sumulaPdfUrl:
          (map['sumulaPdfUrl'] ?? map['sumula_pdf_url'])?.toString(),
      equipeAId: map['equipeAId'],
      equipeBId: map['equipeBId'],
      placarA: map['placarA'] ?? 0,
      placarB: map['placarB'] ?? 0,
      local: map['local'] ?? '',

      // Tratamento de Datas (API usa camelCase e ISO8601)
      iniciadaEm: map['iniciadaEm'] != null
          ? DateTime.tryParse(map['iniciadaEm'])
          : null,
      encerradaEm: map['encerradaEm'] != null
          ? DateTime.tryParse(map['encerradaEm'])
          : null,
      agendadaPara: map['agendadoPara'] != null
          ? DateTime.tryParse(map['agendadoPara'])
          : null,

      // Mapeamento das Equipes (Estão dentro de snapshotSumula)
      equipeA: sumula?['equipeA'] != null
          ? Equipe.fromMap(sumula!['equipeA'])
          : null,
      equipeB: sumula?['equipeB'] != null
          ? Equipe.fromMap(sumula!['equipeB'])
          : null,
    );
  }

  Partida copyWith({
    String? id,
    String? modalidadeId,
    String? status,
    String? statusAntesPausa,
    String? sumulaPdfUrl,
    int? placarA,
    int? placarB,
    String? equipeAId,
    String? equipeBId,
    String? local,
    DateTime? iniciadaEm,
    DateTime? encerradaEm,
    DateTime? agendadaPara,
    Equipe? equipeA,
    Equipe? equipeB,
  }) {
    return Partida(
      id: id ?? this.id,
      modalidadeId: modalidadeId ?? this.modalidadeId,
      status: status ?? this.status,
      statusAntesPausa: statusAntesPausa ?? this.statusAntesPausa,
      sumulaPdfUrl: sumulaPdfUrl ?? this.sumulaPdfUrl,
      placarA: placarA ?? this.placarA,
      placarB: placarB ?? this.placarB,
      equipeAId: equipeAId ?? this.equipeAId,
      equipeBId: equipeBId ?? this.equipeBId,
      local: local ?? this.local,
      iniciadaEm: iniciadaEm ?? this.iniciadaEm,
      encerradaEm: encerradaEm ?? this.encerradaEm,
      agendadaPara: agendadaPara ?? this.agendadaPara,
      equipeA: equipeA ?? this.equipeA,
      equipeB: equipeB ?? this.equipeB,
    );
  }
}
