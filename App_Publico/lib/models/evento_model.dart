class TipoEvento {
  final String id;
  final String esporteId;
  final String nome;

  TipoEvento({
    required this.id,
    required this.esporteId,
    required this.nome,
  });

  factory TipoEvento.fromMap(Map<String, dynamic> map) {
    return TipoEvento(
      id: map['id'],
      esporteId: map['esporte_id'],
      nome: map['nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'esporte_id': esporteId,
      'nome': nome,
    };
  }
}

class EventoPartida {
  final String id;
  final String partidaId;
  final String? atletaId;
  final String? equipeId;
  final String tipoEventoId;
  final String? tempoCronometro;
  final String? descricaoDetalhada;
  final DateTime? criadoEm;

  // Campos auxiliares para facilitar a exibição na UI (populados via JOIN)
  final String? nomeAtleta;
  final String? nomeEquipe;
  final String? nomeEvento;

  EventoPartida({
    required this.id,
    required this.partidaId,
    this.atletaId,
    this.equipeId,
    required this.tipoEventoId,
    this.tempoCronometro,
    this.descricaoDetalhada,
    this.criadoEm,
    this.nomeAtleta,
    this.nomeEquipe,
    this.nomeEvento,
  });

  factory EventoPartida.fromMap(Map<String, dynamic> map) {
    String min = map['minuto']?.toString() ?? '';
    String sec = map['segundo']?.toString() ?? '';
    String? tempoCronometro = map['tempo_cronometro']?.toString();
    if (tempoCronometro == null && min.isNotEmpty && sec.isNotEmpty) {
      tempoCronometro = "${min.padLeft(2, '0')}:${sec.padLeft(2, '0')}";
    }

    return EventoPartida(
      id: (map['evento_id'] ?? map['id']).toString(),
      partidaId: map['partida_id']?.toString() ?? '',
      atletaId: map['atleta_id']?.toString(),
      equipeId: map['equipe_id']?.toString(),
      tipoEventoId: (map['tipo_evento_codigo'] ?? map['tipo_evento_id'] ?? '').toString(),
      tempoCronometro: tempoCronometro,
      descricaoDetalhada: map['descricao'] ?? map['descricao_detalhada'],
      criadoEm: map['criado_em'] != null 
          ? DateTime.tryParse(map['criado_em'].toString()) 
          : null,
      nomeAtleta: map['atleta_nome_exibicao'] ?? map['atletas']?['nome'],
      nomeEquipe: map['equipe_nome'] ?? map['equipes']?['nome_equipe'],
      nomeEvento: map['tipo_evento_nome'] ?? map['tipos_eventos']?['nome'],
    );
  }
}