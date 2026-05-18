import 'dart:convert';
import '../core/api_client.dart';
import '../models/atletica_membro.dart';

class MembroService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AtleticaMembro>> getMembros(String atleticaId) async {
    final response = await _apiClient.get('/atleticas/$atleticaId/membros');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AtleticaMembro.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar elenco da atlética');
    }
  }

  Future<AtleticaMembro> criarUsuarioEAssociar(String atleticaId, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/atleticas/$atleticaId/membros/criar-user',
      data,
    );

    if (response.statusCode == 201) {
      return AtleticaMembro.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao criar e convidar membro');
    }
  }

  Future<AtleticaMembro> associarUsuarioExistente(String atleticaId, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/atleticas/$atleticaId/membros/associar-por-email',
      data,
    );

    if (response.statusCode == 201) {
      return AtleticaMembro.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao vincular membro existente');
    }
  }
}
