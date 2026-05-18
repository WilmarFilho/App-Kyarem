import 'dart:convert';
import '../core/api_client.dart';
import '../models/time_atletica.dart';

class TimeService {
  final ApiClient _apiClient = ApiClient();

  // ─── Times permanentes da atlética ──────────────────────────────────────────

  Future<List<TimeAtletica>> getTimesPorAtletica(String atleticaId) async {
    final response = await _apiClient.get('/times/atletica/$atleticaId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TimeAtletica.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar os times da atlética');
    }
  }

  Future<TimeAtletica> createTime(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/times/atletica', data);

    if (response.statusCode == 201) {
      return TimeAtletica.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao criar o time');
    }
  }

  Future<void> adicionarAtletasTimePermanente(
      String timeId, List<String> atletaIds) async {
    final response = await _apiClient.post(
      '/times/atletica/$timeId/atletas',
      {'atletaIds': atletaIds},
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao adicionar atletas ao time permanente');
    }
  }

  Future<void> deleteTime(String timeId) async {
    final response = await _apiClient.delete('/times/atletica/$timeId');

    if (response.statusCode != 204) {
      throw Exception('Falha ao excluir o time');
    }
  }

  // ─── Times inscritos em campeonato ─────────────────────────────────────────

  /// Lista todos os campeonato_times de um campeonato.
  Future<List<CampeonatoTime>> getTimesDoCampeonato(
      String campeonatoId) async {
    final response = await _apiClient.get('/times/campeonato/$campeonatoId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CampeonatoTime.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar times do campeonato');
    }
  }

  /// Inscreve um time permanente em uma modalidade do campeonato.
  Future<CampeonatoTime> inscreverTimeNoCampeonato({
    required String campeonatoModalidadeId,
    required String timeAtleticaId,
  }) async {
    final response = await _apiClient.post('/times/campeonato', {
      'campeonatoModalidadeId': campeonatoModalidadeId,
      'timeAtleticaId': timeAtleticaId,
    });

    if (response.statusCode == 201) {
      return CampeonatoTime.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao inscrever o time no campeonato');
    }
  }

  /// Remove um time inscrito do campeonato.
  Future<void> removerTimeDoCampeonato(String campeonatoTimeId) async {
    final response =
        await _apiClient.delete('/times/campeonato/$campeonatoTimeId');

    if (response.statusCode != 204) {
      throw Exception('Falha ao remover time do campeonato');
    }
  }

  // ─── Atletas do campeonato_time ─────────────────────────────────────────────

  Future<List<AtletaRoster>> getAtletasDoCampeonatoTime(
      String campeonatoTimeId) async {
    final response =
        await _apiClient.get('/times/campeonato/$campeonatoTimeId/atletas');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AtletaRoster.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar atletas do time no campeonato');
    }
  }

  Future<void> atualizarNumeroCamisa(
      String campeonatoTimeId, String atletaId, int numeroCamisa) async {
    final response = await _apiClient.patch(
      '/times/campeonato/$campeonatoTimeId/atletas/$atletaId/camisa',
      {'numeroCamisa': numeroCamisa},
    );

    if (response.statusCode != 204) {
      throw Exception('Falha ao atualizar o número da camisa do atleta');
    }
  }

  // ─── Staff do campeonato_time ──────────────────────────────────────────────

  Future<List<EquipeStaff>> getStaffDoCampeonatoTime(
      String campeonatoTimeId) async {
    final response =
        await _apiClient.get('/times/campeonato/$campeonatoTimeId/staff');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EquipeStaff.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar staff do time no campeonato');
    }
  }

  Future<EquipeStaff> adicionarStaff(
    String campeonatoTimeId, {
    String? userId,
    required String nome,
    required String cargo,
  }) async {
    final response = await _apiClient.post(
      '/times/campeonato/$campeonatoTimeId/staff',
      {
        'userId': userId,
        'nome': nome,
        'cargo': cargo,
      },
    );

    if (response.statusCode == 201) {
      return EquipeStaff.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao adicionar staff ao time');
    }
  }
}

// ─── Modelos auxiliares ────────────────────────────────────────────────────────

class CampeonatoTime {
  final String id;
  final String? campeonatoId;
  final String? campeonatoNome;
  final String? campeonatoModalidadeId;
  final String? timeAtleticaId;
  final String? nome;
  final String? atleticaNome;
  final String? modalidadeNome;
  final String? status;

  CampeonatoTime({
    required this.id,
    this.campeonatoId,
    this.campeonatoNome,
    this.campeonatoModalidadeId,
    this.timeAtleticaId,
    this.nome,
    this.atleticaNome,
    this.modalidadeNome,
    this.status,
  });

  factory CampeonatoTime.fromJson(Map<String, dynamic> json) {
    return CampeonatoTime(
      id: json['id'],
      campeonatoId: json['campeonatoId'],
      campeonatoNome: json['campeonatoNome'],
      campeonatoModalidadeId: json['campeonatoModalidadeId'],
      timeAtleticaId: json['timeAtleticaId'],
      nome: json['nome'],
      atleticaNome: json['atleticaNome'],
      modalidadeNome: json['modalidadeNome'],
      status: json['status'],
    );
  }
}

class AtletaRoster {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String? status;
  final int? numeroCamisa;

  AtletaRoster({
    required this.id,
    required this.nome,
    this.fotoUrl,
    this.status,
    this.numeroCamisa,
  });

  factory AtletaRoster.fromJson(Map<String, dynamic> json) {
    return AtletaRoster(
      id: json['id'],
      nome: json['nome'] ?? '',
      fotoUrl: json['fotoUrl'],
      status: json['status'],
      numeroCamisa: json['numeroCamisa'] is int ? json['numeroCamisa'] : null,
    );
  }
}

class EquipeStaff {
  final String id;
  final String? userId;
  final String nome;
  final String cargo;

  EquipeStaff({
    required this.id,
    this.userId,
    required this.nome,
    required this.cargo,
  });

  factory EquipeStaff.fromJson(Map<String, dynamic> json) {
    return EquipeStaff(
      id: json['id'],
      userId: json['userId'],
      nome: json['nome'] ?? '',
      cargo: json['cargo'] ?? '',
    );
  }
}
