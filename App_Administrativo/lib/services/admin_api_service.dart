import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';

class AdminApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.100.9:8080/api/v1',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  final _supabase = Supabase.instance.client;

  AdminApiService() {
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = _supabase.auth.currentSession;
          final token = session?.accessToken;
          if (token != null) {
            if (session!.isExpired) {
              final response = await _supabase.auth.refreshSession();
              final newToken = response.session?.accessToken;
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
              }
            } else {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ============== CAMPEONATOS ==============
  Future<List<Campeonato>> listarCampeonatos() async {
    try {
      final res = await _dio.get('/campeonatos');
      return (res.data as List).map((e) => Campeonato.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarCampeonatos: $e");
      return [];
    }
  }

  Future<Campeonato?> criarCampeonato(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/campeonatos', data: data);
      return Campeonato.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro criarCampeonato: $e");
      return null;
    }
  }

  Future<Campeonato?> atualizarCampeonato(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/campeonatos/$id', data: data);
      return Campeonato.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro atualizarCampeonato: $e");
      return null;
    }
  }

  Future<bool> excluirCampeonato(String id) async {
    try {
      await _dio.delete('/campeonatos/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirCampeonato: $e");
      return false;
    }
  }

  // ============== ATLÉTICAS ==============
  Future<Atletica?> buscarAtletica(String id) async {
    try {
      final res = await _dio.get('/atleticas/$id');
      return Atletica.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro buscarAtletica: $e");
      return null;
    }
  }

  /// Busca a atlética cujo [presidenteId] corresponde ao [userId] logado.
  /// Usado para descobrir o atleticaId do presidente sem precisar de coluna extra no Supabase.
  Future<String?> buscarAtleticaDoPresidente(String userId) async {
    try {
      final res = await _dio.get('/atleticas');
      final list = res.data as List;
      for (final item in list) {
        final presidenteId =
            item['presidenteId']?.toString() ?? item['presidente_id']?.toString();
        if (presidenteId == userId) {
          return item['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint("Erro buscarAtleticaDoPresidente: $e");
      return null;
    }
  }

  Future<List<Atletica>> listarAtleticas() async {
    try {
      final res = await _dio.get('/atleticas');
      return (res.data as List).map((e) => Atletica.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarAtleticas: $e");
      return [];
    }
  }

  Future<Atletica?> criarAtletica(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/atleticas', data: data);
      return Atletica.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro criarAtletica: $e");
      return null;
    }
  }

  Future<Atletica?> atualizarAtletica(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/atleticas/$id', data: data);
      return Atletica.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro atualizarAtletica: $e");
      return null;
    }
  }

  Future<bool> excluirAtletica(String id) async {
    try {
      await _dio.delete('/atleticas/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirAtletica: $e");
      return false;
    }
  }

  // ============== EQUIPES ==============
  Future<List<Equipe>> listarEquipes({String? campeonatoId, String? modalidadeId, String? atleticaId}) async {
    try {
      final params = <String, dynamic>{};
      if (campeonatoId != null) params['campeonatoId'] = campeonatoId;
      if (modalidadeId != null) params['modalidadeId'] = modalidadeId;
      if (atleticaId != null) params['atleticaId'] = atleticaId;

      final res = await _dio.get('/equipes', queryParameters: params);
      return (res.data as List).map((e) => Equipe.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarEquipes: $e");
      return [];
    }
  }

  Future<Equipe?> criarEquipe(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/equipes', data: data);
      return Equipe.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro criarEquipe: $e");
      return null;
    }
  }

  Future<Equipe?> atualizarEquipe(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/equipes/$id', data: data);
      return Equipe.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro atualizarEquipe: $e");
      return null;
    }
  }

  Future<bool> excluirEquipe(String id) async {
    try {
      await _dio.delete('/equipes/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirEquipe: $e");
      return false;
    }
  }

  // ============== ATLETAS ==============
  Future<List<Atleta>> listarAtletas(String atleticaId) async {
    try {
      final res = await _dio.get('/atletas', queryParameters: {'atleticaId': atleticaId});
      return (res.data as List).map((e) => Atleta.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarAtletas: $e");
      return [];
    }
  }

  Future<Atleta?> criarAtleta(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/atletas', data: data);
      return Atleta.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro criarAtleta: $e");
      return null;
    }
  }

  Future<bool> excluirAtleta(String id) async {
    try {
      await _dio.delete('/atletas/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirAtleta: $e");
      return false;
    }
  }

  // ============== INSCRITOS NA EQUIPE ==============
  Future<List<dynamic>> listarInscritos(String equipeId) async {
    try {
      final res = await _dio.get('/equipes/$equipeId/inscritos');
      return res.data as List;
    } catch (e) {
      debugPrint("Erro listarInscritos: $e");
      return [];
    }
  }

  Future<bool> adicionarInscritos(String equipeId, List<Map<String, dynamic>> inscritos) async {
    try {
      await _dio.post('/equipes/$equipeId/inscritos', data: inscritos);
      return true;
    } catch (e) {
      debugPrint("Erro adicionarInscritos: $e");
      return false;
    }
  }

  Future<bool> removerInscrito(String equipeId, String inscritoId) async {
    try {
      await _dio.delete('/equipes/$equipeId/inscritos/$inscritoId');
      return true;
    } catch (e) {
      debugPrint("Erro removerInscrito: $e");
      return false;
    }
  }

  // ============== PARTIDAS (ADMIN) ==============
  Future<Map<String, dynamic>?> criarPartida(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/partidas', data: data);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erro criarPartida: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> atualizarPartida(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/partidas/$id', data: data);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erro atualizarPartida: $e");
      return null;
    }
  }

  Future<bool> excluirPartida(String id) async {
    try {
      await _dio.delete('/partidas/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirPartida: $e");
      return false;
    }
  }

  // ============== MODALIDADES ==============
  Future<List<dynamic>> listarModalidades(String campeonatoId) async {
    try {
      final res = await _dio.get('/campeonatos/$campeonatoId/modalidades');
      return res.data as List;
    } catch (e) {
      debugPrint("Erro listarModalidades: $e");
      return [];
    }
  }

  /// Busca uma modalidade específica pelo ID.
  /// Retorna o map com id, campeonatoId, campeonatoNome, esporteNome, nome.
  /// Endpoint: GET /api/v1/modalidades/{id} (público).
  Future<Map<String, dynamic>?> buscarModalidade(String modalidadeId) async {
    try {
      final res = await _dio.get('/modalidades/$modalidadeId');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erro buscarModalidade: $e");
      return null;
    }
  }
}
