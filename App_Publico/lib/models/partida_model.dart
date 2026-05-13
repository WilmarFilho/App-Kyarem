import 'package:kyarem_eventos_publico/models/atletica_equipe_model.dart';

class Partida {
  final String id;
  final String modalidadeId;
  final String status;
  final int placarA;
  final int placarB;
  final String? local;
  final DateTime? iniciadaEm;
  final DateTime? agendadoPara;
  final Equipe? equipeA;
  final Equipe? equipeB;

  Partida({
    required this.id,
    required this.modalidadeId,
    required this.status,
    this.placarA = 0,
    this.placarB = 0,
    this.local,
    this.iniciadaEm,
    this.agendadoPara,
    this.equipeA,
    this.equipeB,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    // Adapter for flattened schema from public.partidas_ao_vivo or public.partidas_historico
    final String id = (map['partida_id'] ?? map['id']).toString();
    final String modId =
        (map['campeonato_modalidade_id'] ?? map['modalidade_id'] ?? '')
            .toString();

    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value?.toString();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      return null;
    }

    Equipe? equipeA;
    if (map['equipe_a'] != null) {
      equipeA = Equipe.fromMap(map['equipe_a']);
    } else if (map['time_a_nome'] != null) {
      final timeAEscudoUrl = firstNonEmpty([
        map['time_a_escudo_url'],
        map['time_a_atletica_escudo_url'],
      ]);
      equipeA = Equipe(
        id: (map['time_a_id'] ?? '').toString(),
        nome: map['time_a_nome'].toString(),
        atleticaId: (map['time_a_atletica_id'] ?? '').toString(),
        atleticaNome: firstNonEmpty([
          map['time_a_atletica_nome'],
          map['time_a_nome_atletica'],
        ]),
        atleticaEscudoUrl: timeAEscudoUrl,
        atletica: Atletica(
          id: (map['time_a_atletica_id'] ?? '').toString(),
          nome: (map['time_a_atletica_nome'] ?? '').toString(),
          escudoUrl: timeAEscudoUrl,
          // time_a_cor_principal foi removido na revisão 12.5
          corPrincipal: null,
        ),
      );
    }

    Equipe? equipeB;
    if (map['equipe_b'] != null) {
      equipeB = Equipe.fromMap(map['equipe_b']);
    } else if (map['time_b_nome'] != null) {
      final timeBEscudoUrl = firstNonEmpty([
        map['time_b_escudo_url'],
        map['time_b_atletica_escudo_url'],
      ]);
      equipeB = Equipe(
        id: (map['time_b_id'] ?? '').toString(),
        nome: map['time_b_nome'].toString(),
        atleticaId: (map['time_b_atletica_id'] ?? '').toString(),
        atleticaNome: firstNonEmpty([
          map['time_b_atletica_nome'],
          map['time_b_nome_atletica'],
        ]),
        atleticaEscudoUrl: timeBEscudoUrl,
        atletica: Atletica(
          id: (map['time_b_atletica_id'] ?? '').toString(),
          nome: (map['time_b_atletica_nome'] ?? '').toString(),
          escudoUrl: timeBEscudoUrl,
          // time_b_cor_principal foi removido na revisão 12.5
          corPrincipal: null,
        ),
      );
    }

    DateTime? iniciadaEm;
    if (map['iniciada_em'] != null) {
      iniciadaEm = DateTime.tryParse(map['iniciada_em'].toString());
    }

    DateTime? agendadoPara;
    if (map['agendado_para'] != null) {
      agendadoPara = DateTime.tryParse(map['agendado_para'].toString());
    }

    return Partida(
      id: id,
      modalidadeId: modId,
      status: map['status'] ?? 'agendada',
      placarA: (map['placar_a'] ?? 0) as int,
      placarB: (map['placar_b'] ?? 0) as int,
      local: map['local']?.toString(),
      iniciadaEm: iniciadaEm,
      agendadoPara: agendadoPara,
      equipeA: equipeA,
      equipeB: equipeB,
    );
  }
}
