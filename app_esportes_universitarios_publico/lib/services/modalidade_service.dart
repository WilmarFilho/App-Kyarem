import 'dart:convert';
import '../core/api_client.dart';
import '../models/modalidade_catalogo.dart';

class ModalidadeService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ModalidadeCatalogo>> getModalidadesCatalogo() async {
    final response = await _apiClient.get('/modalidades-catalogo');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ModalidadeCatalogo.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar catálogo de modalidades');
    }
  }
}
