import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api_client.dart';
import '../models/atletica.dart';

class AtleticaService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Atletica>> getAtleticas() async {
    final response = await _apiClient.get('/atleticas');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Atletica.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar as atléticas');
    }
  }

  Future<List<MinhaAtletica>> getMinhasAtleticas() async {
    final response = await _apiClient.get('/atleticas/minhas');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MinhaAtletica.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar suas atléticas');
    }
  }

  Future<List<MinhaAtletica>> getMeusConvites() async {
    final response = await _apiClient.get('/atleticas/convites/minhas');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MinhaAtletica.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar seus convites');
    }
  }

  Future<MinhaAtletica> aceitarConvite(String membroId) async {
    final response = await _apiClient.post('/atleticas/membros/$membroId/aceitar', {});

    if (response.statusCode == 200) {
      return MinhaAtletica.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao aceitar convocação');
    }
  }

  Future<MinhaAtletica> recusarConvite(String membroId) async {
    final response = await _apiClient.post('/atleticas/membros/$membroId/recusar', {});

    if (response.statusCode == 200) {
      return MinhaAtletica.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao recusar convocação');
    }
  }

  Future<Atletica> getAtletica(String id) async {
    final response = await _apiClient.get('/atleticas/$id');

    if (response.statusCode == 200) {
      return Atletica.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar atlética');
    }
  }

  Future<Atletica> updateAtletica(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/atleticas/$id', data);

    if (response.statusCode == 200) {
      return Atletica.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao atualizar atlética');
    }
  }

  /// Faz upload do escudo diretamente no Supabase Storage
  /// e retorna a URL pública da imagem.
  Future<String> uploadEscudo(String atleticaId, File imageFile) async {
    final supabase = Supabase.instance.client;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName =
        '$atleticaId-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = 'atleticas/$fileName';

    await supabase.storage.from('escudos').upload(
          storagePath,
          imageFile,
          fileOptions: FileOptions(
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );

    return supabase.storage.from('escudos').getPublicUrl(storagePath);
  }
}
