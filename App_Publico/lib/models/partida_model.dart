import 'package:kyarem_eventos_publico/models/atletica_equipe_model.dart';

class Partida {
  final String id;
  final String modalidadeId;
  final String status; // agendada, em_andamento, encerrada [cite: 36]
  final int placarA;
  final int placarB;
  final String? local;
  final DateTime? iniciadaEm;
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
    this.equipeA,
    this.equipeB,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    // Adapter for flattened schema from public.partidas_ao_vivo or public.partidas_historico
    String id = (map['partida_id'] ?? map['id']).toString();
    String modId = (map['campeonato_modalidade_id'] ?? map['modalidade_id']).toString();
    
    Equipe? equipeA;
    if (map['equipe_a'] != null) {
      equipeA = Equipe.fromMap(map['equipe_a']);
    } else if (map['time_a_nome'] != null) {
      equipeA = Equipe(
        id: (map['time_a_id'] ?? '').toString(),
        nome: map['time_a_nome'].toString(),
        atleticaId: (map['time_a_atletica_id'] ?? '').toString(),
        atleticaNome: map['time_a_atletica_nome']?.toString(),
        atleticaEscudoUrl: map['time_a_escudo_url']?.toString(),
        atletica: Atletica(
          id: (map['time_a_atletica_id'] ?? '').toString(),
          nome: (map['time_a_atletica_nome'] ?? '').toString(),
          escudoUrl: map['time_a_escudo_url']?.toString(),
          corPrincipal: map['time_a_cor_principal']?.toString(),
        ),
      );
    }

    Equipe? equipeB;
    if (map['equipe_b'] != null) {
      equipeB = Equipe.fromMap(map['equipe_b']);
    } else if (map['time_b_nome'] != null) {
      equipeB = Equipe(
        id: (map['time_b_id'] ?? '').toString(),
        nome: map['time_b_nome'].toString(),
        atleticaId: (map['time_b_atletica_id'] ?? '').toString(),
        atleticaNome: map['time_b_atletica_nome']?.toString(),
        atleticaEscudoUrl: map['time_b_escudo_url']?.toString(),
        atletica: Atletica(
          id: (map['time_b_atletica_id'] ?? '').toString(),
          nome: (map['time_b_atletica_nome'] ?? '').toString(),
          escudoUrl: map['time_b_escudo_url']?.toString(),
          corPrincipal: map['time_b_cor_principal']?.toString(),
        ),
      );
    }

    return Partida(
      id: id,
      modalidadeId: modId,
      status: map['status'] ?? 'agendada',
      placarA: map['placar_a'] ?? 0,
      placarB: map['placar_b'] ?? 0,
      local: map['local'],
      iniciadaEm: map['iniciada_em'] != null ? DateTime.parse(map['iniciada_em'].toString()) : null,
      equipeA: equipeA,
      equipeB: equipeB,
    );
  }
}