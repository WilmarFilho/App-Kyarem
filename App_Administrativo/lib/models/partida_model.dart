import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/modalidade_model.dart';

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
  final String? categoria;
  final String? fase;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final DateTime? agendadaPara;
  final Equipe? equipeA;
  final Equipe? equipeB;
  final Modalidade? modalidade;

  /// Alias para compatibilidade com código que usa 'agendadoPara'
  DateTime? get agendadoPara => agendadaPara;

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
    this.categoria,
    this.fase,
    this.iniciadaEm,
    this.encerradaEm,
    this.agendadaPara,
    this.equipeA,
    this.equipeB,
    this.modalidade,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    final sumula = map['snapshotSumula'] as Map<String, dynamic>?;

    Modalidade? modalidade;
    if (map['modalidade'] is Map<String, dynamic>) {
      final mod = map['modalidade'] as Map<String, dynamic>;
      modalidade = Modalidade(
        id: mod['id']?.toString() ?? map['modalidadeId'] ?? '',
        campeonatoId: mod['campeonatoId']?.toString() ?? '',
        esporteId: mod['esporteId']?.toString() ?? '',
        genero: mod['genero']?.toString() ?? '',
        esporteNome: mod['nome']?.toString() ?? mod['esporteNome']?.toString(),
      );
    } else if (map['modalidadeNome'] != null || map['modalidadeId'] != null) {
      modalidade = Modalidade(
        id: map['modalidadeId']?.toString() ?? '',
        campeonatoId: '',
        esporteId: '',
        genero: '',
        esporteNome: map['modalidadeNome']?.toString(),
      );
    }

    return Partida(
      id: map['id'] ?? '',
      modalidadeId: map['modalidadeId'] ?? '',
      status: map['status'] ?? '',
      statusAntesPausa: map['status_antes_pausa'] ?? map['statusAntesPausa'],
      sumulaPdfUrl: map['sumula_pdf_url'] ?? map['sumulaPdfUrl'],
      equipeAId: map['equipeAId'] ?? map['equipe_a_id'] ?? '',
      equipeBId: map['equipeBId'] ?? map['equipe_b_id'] ?? '',
      placarA: map['placarA'] ?? 0,
      placarB: map['placarB'] ?? 0,
      local: map['local'],
      categoria: map['categoria'],
      fase: map['fase'],
      iniciadaEm: map['iniciadaEm'] != null
          ? DateTime.tryParse(map['iniciadaEm'])
          : null,
      encerradaEm: map['encerradaEm'] != null
          ? DateTime.tryParse(map['encerradaEm'])
          : null,
      agendadaPara: (map['agendadoPara'] ?? map['agendada_para']) != null
          ? DateTime.tryParse(map['agendadoPara'] ?? map['agendada_para'])
          : null,
      equipeA: map['equipeA'] != null
          ? Equipe.fromMap(map['equipeA'])
          : (sumula?['equipeA'] != null
                ? Equipe.fromMap(sumula!['equipeA'])
                : null),
      equipeB: map['equipeB'] != null
          ? Equipe.fromMap(map['equipeB'])
          : (sumula?['equipeB'] != null
                ? Equipe.fromMap(sumula!['equipeB'])
                : null),
      modalidade: modalidade,
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
    String? categoria,
    String? fase,
    DateTime? iniciadaEm,
    DateTime? encerradaEm,
    DateTime? agendadaPara,
    Equipe? equipeA,
    Equipe? equipeB,
    Modalidade? modalidade,
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
      categoria: categoria ?? this.categoria,
      fase: fase ?? this.fase,
      iniciadaEm: iniciadaEm ?? this.iniciadaEm,
      encerradaEm: encerradaEm ?? this.encerradaEm,
      agendadaPara: agendadaPara ?? this.agendadaPara,
      equipeA: equipeA ?? this.equipeA,
      equipeB: equipeB ?? this.equipeB,
      modalidade: modalidade ?? this.modalidade,
    );
  }
}
