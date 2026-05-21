import 'dart:convert';
import '../core/api_client.dart';
import '../models/campeonato.dart';

class CampeonatoService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Campeonato>> getCampeonatos() async {
    final response = await _apiClient.get('/campeonatos');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Campeonato.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar campeonatos');
    }
  }

  Future<List<CampeonatoModalidade>> getModalidadesDoCampeonato(
      String campeonatoId) async {
    final response =
        await _apiClient.get('/campeonatos/$campeonatoId/modalidades');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CampeonatoModalidade.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar modalidades do campeonato');
    }
  }

  Future<CampeonatoModalidade> getModalidadeById(String modalidadeId) async {
    final response = await _apiClient.get('/modalidades/$modalidadeId');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CampeonatoModalidade.fromJson(data);
    } else {
      throw Exception('Falha ao carregar a modalidade');
    }
  }

  /// Inscreve um time da atlética em uma modalidade do campeonato.
  /// [campeonatoModalidadeId] = ID da instância da modalidade no campeonato
  /// [timeAtleticaId] = ID do time permanente da atlética
  Future<void> inscreverTime(
      String campeonatoModalidadeId, String timeAtleticaId) async {
    final response = await _apiClient.post(
      '/times/campeonato',
      {
        'campeonatoModalidadeId': campeonatoModalidadeId,
        'timeAtleticaId': timeAtleticaId,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao inscrever o time');
    }
  }
}
