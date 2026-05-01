import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/models/atletica_membro_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import 'package:kyarem_eventos/models/equipe_staff_model.dart';
import 'package:kyarem_eventos/models/esporte_model.dart';
import 'package:kyarem_eventos/models/modalidade_catalogo_model.dart';

class AdminApiService {
  final Dio _dio;
  final SupabaseClient? _supabaseOverride;

  /// Retorna o client configurado ou o singleton global (lazy).
  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  AdminApiService({Dio? dio, SupabaseClient? supabaseClient})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'http://10.0.2.2:8080/api/v1',
              connectTimeout: const Duration(seconds: 10),
            ),
          ),
      _supabaseOverride = supabaseClient {
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

  Future<Campeonato?> atualizarCampeonato(
    String id,
    Map<String, dynamic> data,
  ) async {
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
            item['presidenteId']?.toString() ??
            item['presidente_id']?.toString();
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

  Future<Atletica?> atualizarAtletica(
    String id,
    Map<String, dynamic> data,
  ) async {
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

  Future<List<AtleticaMembro>> listarMembrosAtletica(String atleticaId) async {
    try {
      final res = await _dio.get('/atleticas/$atleticaId/membros');
      return (res.data as List)
          .map((e) => AtleticaMembro.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Erro listarMembrosAtletica: $e");
      return [];
    }
  }

  Future<AtleticaMembro?> associarMembroAtletica({
    required String atleticaId,
    required String userId,
    required String papelCodigo,
  }) async {
    try {
      final res = await _dio.post(
        '/atleticas/$atleticaId/membros',
        data: {'userId': userId, 'papelCodigo': papelCodigo},
      );
      return AtleticaMembro.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro associarMembroAtletica: $e");
      return null;
    }
  }

  Future<AtleticaMembro?> criarEAssociarMembroAtletica({
    required String atleticaId,
    required String nomeExibicao,
    required String email,
    required String senha,
    required String papelCodigo,
  }) async {
    try {
      final res = await _dio.post(
        '/atleticas/$atleticaId/membros/criar-user',
        data: {
          'nomeExibicao': nomeExibicao,
          'email': email,
          'senha': senha,
          'papelCodigo': papelCodigo,
        },
      );
      return AtleticaMembro.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro criarEAssociarMembroAtletica: $e");
      return null;
    }
  }

  // ============== EQUIPES ==============
  Future<List<Equipe>> listarEquipes({
    String? campeonatoId,
    String? modalidadeId,
    String? atleticaId,
  }) async {
    try {
      List<dynamic> data = [];
      if (campeonatoId != null && campeonatoId.isNotEmpty) {
        final res = await _dio.get('/times/campeonato/$campeonatoId');
        data = res.data as List;
      } else if (atleticaId != null && atleticaId.isNotEmpty) {
        final res = await _dio.get('/times/atletica/$atleticaId');
        data = res.data as List;
      } else {
        final atleticas = await listarAtleticas();
        final agregadas = <dynamic>[];
        for (final atletica in atleticas) {
          final res = await _dio.get('/times/atletica/${atletica.id}');
          agregadas.addAll(res.data as List);
        }
        data = agregadas;
      }

      final equipes = data.map((e) => Equipe.fromMap(e)).toList();
      if (modalidadeId != null && modalidadeId.isNotEmpty) {
        return equipes
            .where(
              (e) =>
                  e.modalidade?.id == modalidadeId ||
                  e.campeonatoModalidadeId == modalidadeId ||
                  e.modalidade?.modalidadeCatalogoId == modalidadeId,
            )
            .toList();
      }
      return equipes;
    } catch (e) {
      debugPrint("Erro listarEquipes: $e");
      return [];
    }
  }

  Future<Equipe?> criarEquipe(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/times/atletica',
        data: {
          'atleticaId': data['atleticaId'],
          'modalidadeCatalogoId': data['modalidadeId'],
          'nome': data['nomeEquipe'] ?? data['nome'],
        },
      );
      return Equipe.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro criarEquipe: $e");
      return null;
    }
  }

  Future<Equipe?> atualizarEquipe(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(
        '/times/atletica/$id',
        data: {
          'modalidadeCatalogoId': data['modalidadeId'],
          'nome': data['nomeEquipe'] ?? data['nome'],
        },
      );
      return Equipe.fromMap(res.data);
    } catch (e) {
      debugPrint("Erro atualizarEquipe: $e");
      return null;
    }
  }

  Future<bool> excluirEquipe(String id) async {
    try {
      await _dio.delete('/times/atletica/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirEquipe: $e");
      return false;
    }
  }

  // ============== ATLETAS ==============
  Future<List<Atleta>> listarAtletas(String atleticaId) async {
    try {
      final res = await _dio.get(
        '/atletas',
        queryParameters: {'atleticaId': atleticaId},
      );
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

  Future<bool> adicionarInscritos(
    String equipeId,
    List<Map<String, dynamic>> inscritos,
  ) async {
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

  Future<Map<String, dynamic>?> atualizarInscrito(
    String equipeId,
    String inscritoId, {
    bool? isGoleiro,
    bool? isCapitao,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isGoleiro != null) body['isGoleiro'] = isGoleiro;
      if (isCapitao != null) body['isCapitao'] = isCapitao;
      final res = await _dio.patch(
        '/equipes/$equipeId/inscritos/$inscritoId',
        data: body,
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erro atualizarInscrito: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listarProfiles({String? role}) async {
    try {
      final params = <String, dynamic>{};
      if (role != null) params['role'] = role;
      final res = await _dio.get(
        '/profiles',
        queryParameters: params.isEmpty ? null : params,
      );
      return (res.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("Erro listarProfiles: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> criarPresidente({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final res = await _dio.post(
        '/profiles/criar-presidente',
        data: {'nomeExibicao': nome, 'email': email, 'senha': senha},
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erro criarPresidente: $e");
      return null;
    }
  }

  // ============== STAFF DA EQUIPE ==============
  Future<List<EquipeStaff>> listarEquipeStaff(String equipeId) async {
    try {
      final res = await _dio.get('/equipes/$equipeId/staff');
      return (res.data as List).map((e) => EquipeStaff.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarEquipeStaff: $e");
      return [];
    }
  }

  Future<EquipeStaff?> criarEquipeStaff(Map<String, dynamic> data) async {
    try {
      final equipeId =
          data['equipe_id']?.toString() ?? data['equipeId']?.toString();
      if (equipeId == null || equipeId.isEmpty) {
        throw ArgumentError('equipe_id é obrigatório para criar staff.');
      }

      final payload = {'nome': data['nome'], 'cargo': data['cargo']};
      final res = await _dio.post('/equipes/$equipeId/staff', data: payload);
      return EquipeStaff.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro criarEquipeStaff: $e");
      return null;
    }
  }

  Future<bool> removerEquipeStaff(String equipeId, String staffId) async {
    try {
      await _dio.delete('/equipes/$equipeId/staff/$staffId');
      return true;
    } catch (e) {
      debugPrint("Erro removerEquipeStaff: $e");
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
    String id,
    Map<String, dynamic> data,
  ) async {
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

  Future<List<dynamic>> listarModalidadesCatalogo() async {
    try {
      final res = await _dio.get('/modalidades-catalogo');
      return (res.data as List)
          .map((e) => ModalidadeCatalogo.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Erro listarModalidadesCatalogo: $e");
      return [];
    }
  }

  Future<ModalidadeCatalogo?> criarModalidadeCatalogo(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/modalidades-catalogo', data: data);
      return ModalidadeCatalogo.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro criarModalidadeCatalogo: $e");
      return null;
    }
  }

  Future<ModalidadeCatalogo?> atualizarModalidadeCatalogo(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put('/modalidades-catalogo/$id', data: data);
      return ModalidadeCatalogo.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro atualizarModalidadeCatalogo: $e");
      return null;
    }
  }

  Future<bool> excluirModalidadeCatalogo(String id) async {
    try {
      await _dio.delete('/modalidades-catalogo/$id');
      return true;
    } catch (e) {
      debugPrint("Erro excluirModalidadeCatalogo: $e");
      return false;
    }
  }

  Future<List<Esporte>> listarEsportes() async {
    try {
      final res = await _dio.get('/esportes');
      return (res.data as List)
          .map((e) => Esporte.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Erro listarEsportes: $e");
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

  // ============== ÁRBITROS ==============

  /// POST /api/v1/arbitros
  /// Vincula um usuário existente ao quadro de arbitragem.
  Future<bool> associarArbitro(String userId) async {
    try {
      await _dio.post('/arbitros', data: {'userId': userId});
      return true;
    } catch (e) {
      debugPrint("Erro associarArbitro: $e");
      return false;
    }
  }

  /// POST /api/v1/arbitros/criar
  /// Cria um novo usuário auth e já o vincula ao quadro de arbitragem.
  Future<Arbitro?> criarEAssociarArbitro({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final res = await _dio.post(
        '/arbitros/criar',
        data: {'nome': nome, 'email': email, 'senha': senha},
      );
      return Arbitro.fromMap(res.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Erro criarEAssociarArbitro: $e");
      return null;
    }
  }

  /// GET /api/v1/arbitros — lista todos os árbitros (role='arbitro').
  Future<List<Arbitro>> listarArbitros() async {
    try {
      final res = await _dio.get('/arbitros');
      return (res.data as List).map((e) => Arbitro.fromMap(e)).toList();
    } catch (e) {
      debugPrint("Erro listarArbitros: $e");
      return [];
    }
  }

  /// GET /api/v1/arbitros/{arbitroId}/partidas
  /// Retorna todas as partidas (ativas e encerradas) vinculadas ao árbitro.
  Future<List<PartidaDoArbitro>> listarPartidasDoArbitro(
    String arbitroId,
  ) async {
    try {
      final res = await _dio.get('/arbitros/$arbitroId/partidas');
      return (res.data as List)
          .map((e) => PartidaDoArbitro.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint("Erro listarPartidasDoArbitro: $e");
      return [];
    }
  }

  /// POST /api/v1/partidas/{partidaId}/arbitros
  /// Vincula um árbitro a uma partida com a função informada.
  Future<bool> vincularArbitro(
    String partidaId,
    String arbitroId,
    String funcao,
  ) async {
    try {
      await _dio.post(
        '/partidas/$partidaId/arbitros',
        data: {'arbitroId': arbitroId, 'funcao': funcao},
      );
      return true;
    } catch (e) {
      debugPrint("Erro vincularArbitro: $e");
      return false;
    }
  }

  /// DELETE /api/v1/partidas/{partidaId}/arbitros/{vinculoId}
  /// Remove o vínculo de árbitro de uma partida.
  Future<bool> desvincularArbitro(String partidaId, String vinculoId) async {
    try {
      await _dio.delete('/partidas/$partidaId/arbitros/$vinculoId');
      return true;
    } catch (e) {
      debugPrint("Erro desvincularArbitro: $e");
      return false;
    }
  }

  // ============== UPLOAD DE IMAGENS ==============

  /// Faz upload do escudo do campeonato via multipart.
  /// Retorna a URL pública da imagem ou null em caso de erro.
  Future<String?> uploadEscudoCampeonato(File imageFile) async {
    try {
      final fileName = p.basename(imageFile.path);
      final multipart = await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      );
      final formData = FormData.fromMap({'file': multipart});
      final res = await _dio.post('/campeonatos/upload-escudo', data: formData);
      return res.data['url'] as String?;
    } catch (e) {
      debugPrint("Erro uploadEscudoCampeonato: $e");
      return null;
    }
  }

  /// Faz upload da foto do atleta via multipart.
  /// Retorna a URL pública da imagem ou null em caso de erro.
  Future<String?> uploadFotoAtleta(File imageFile) async {
    try {
      final fileName = p.basename(imageFile.path);
      final multipart = await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      );
      final formData = FormData.fromMap({'file': multipart});
      final res = await _dio.post('/atletas/upload-foto', data: formData);
      return res.data['url'] as String?;
    } catch (e) {
      debugPrint("Erro uploadFotoAtleta: $e");
      return null;
    }
  }

  /// Faz upload do escudo da atlética via multipart.
  /// Retorna a URL pública da imagem ou null em caso de erro.
  Future<String?> uploadEscudoAtletica(File imageFile) async {
    try {
      final fileName = p.basename(imageFile.path);
      final multipart = await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      );
      final formData = FormData.fromMap({'file': multipart});
      final res = await _dio.post('/atleticas/upload-escudo', data: formData);
      return res.data['url'] as String?;
    } catch (e) {
      debugPrint("Erro uploadEscudoAtletica: $e");
      return null;
    }
  }
}
