/// Representa um árbitro (perfil com role='arbitro').
class Arbitro {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String? telefone;
  final String role;

  Arbitro({
    required this.id,
    required this.nome,
    this.fotoUrl,
    this.telefone,
    this.role = 'referee',
  });

  factory Arbitro.fromMap(Map<String, dynamic> map) {
    return Arbitro(
      id: map['id']?.toString() ?? '',
      nome: map['nomeExibicao'] ?? map['nome'] ?? 'Sem nome',
      fotoUrl: map['fotoUrl'] ?? map['foto_url'],
      telefone: map['telefone'],
      role: map['role'] ?? 'referee',
    );
  }
}

/// Representa um vínculo de árbitro com uma partida.
/// Retornado pelo endpoint GET /api/v1/arbitros/{id}/partidas.
class PartidaDoArbitro {
  final String vinculoId;      // ID do registro em partida_arbitros (para desvincular)
  final String funcao;         // Ex: Árbitro Principal, Mesário, Delegado
  final DateTime? vinculadoEm;
  final String partidaId;
  final String status;
  final DateTime? agendadaPara;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;
  final String? local;
  final String? fase;
  final String? categoria;
  final int placarA;
  final int placarB;
  final String? equipeANome;
  final String? equipeBNome;
  final String? modalidadeNome;

  PartidaDoArbitro({
    required this.vinculoId,
    required this.funcao,
    this.vinculadoEm,
    required this.partidaId,
    required this.status,
    this.agendadaPara,
    this.iniciadaEm,
    this.encerradaEm,
    this.local,
    this.fase,
    this.categoria,
    this.placarA = 0,
    this.placarB = 0,
    this.equipeANome,
    this.equipeBNome,
    this.modalidadeNome,
  });

  factory PartidaDoArbitro.fromMap(Map<String, dynamic> map) {
    return PartidaDoArbitro(
      vinculoId: map['vinculoId']?.toString() ?? '',
      funcao: map['funcao'] ?? '',
      vinculadoEm: map['vinculadoEm'] != null ? DateTime.tryParse(map['vinculadoEm']) : null,
      partidaId: map['partidaId']?.toString() ?? '',
      status: map['status'] ?? '',
      agendadaPara: map['agendadaPara'] != null ? DateTime.tryParse(map['agendadaPara']) : null,
      iniciadaEm: map['iniciadaEm'] != null ? DateTime.tryParse(map['iniciadaEm']) : null,
      encerradaEm: map['encerradaEm'] != null ? DateTime.tryParse(map['encerradaEm']) : null,
      local: map['local'],
      fase: map['fase'],
      categoria: map['categoria'],
      placarA: map['placarA'] ?? 0,
      placarB: map['placarB'] ?? 0,
      equipeANome: map['equipeANome'],
      equipeBNome: map['equipeBNome'],
      modalidadeNome: map['modalidadeNome'],
    );
  }

  /// Partidas ativas = agendada ou em andamento (qualquer status que não seja encerrada/fechada)
  bool get isAtiva {
    final s = status.toLowerCase();
    return s != 'finalizada' && s != 'fechada';
  }

  bool get isEncerrada => !isAtiva;
}