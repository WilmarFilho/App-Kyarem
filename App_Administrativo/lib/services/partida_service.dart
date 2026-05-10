import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart'; // ← ADD: flutter pub add uuid

import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import '../models/arbitro_model.dart';
import '../models/campeonato_model.dart';
import '../models/modalidade_catalogo_model.dart';
import '../models/tipo_evento_model.dart';

class PartidaService {
  final Dio _dio;
  final SupabaseClient? _supabaseOverride;

  /// Retorna o client configurado ou o singleton global (lazy).
  SupabaseClient get _supabase => _supabaseOverride ?? Supabase.instance.client;

  final _uuid = const Uuid();
  Database? _db;
  Timer? _syncTimer;
  bool _isSyncing = false;

  final Map<String, Equipe> _equipesCache = {};

  PartidaService({Dio? dio, SupabaseClient? supabase})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://kyarem.nkwflow.com/api/v1',
              connectTimeout: const Duration(seconds: 5),
            ),
          ),
      _supabaseOverride = supabase {
    _initInterceptors();
    _initLocalDb().then((_) {
      _startSyncTimer();
    });
  }

  /// Construtor de teste: não inicializa o banco SQLite nem o timer periódico.
  /// Usado por [FakePartidaService] para evitar timers pendentes em testes.
  @visibleForTesting
  PartidaService.forTesting()
    : _dio = Dio(BaseOptions(baseUrl: 'http://localhost')),
      _supabaseOverride = null;
  // _initInterceptors, _initLocalDb e _startSyncTimer NÃO são chamados.

  // --- INICIALIZAÇÃO DO BANCO LOCAL (SQLITE) ---
  Future<void> _initLocalDb() async {
    try {
      final path = join(await getDatabasesPath(), 'fila_eventos_v2.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute('''CREATE TABLE fila_eventos (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              partida_id TEXT,
              dados TEXT, 
              criado_em TEXT
            )''');
        },
      );

      await _db!.delete('fila_eventos');
      debugPrint("SQFlite: Banco inicializado e registros antigos limpos.");
    } catch (e) {
      debugPrint("SQFlite: Erro ao inicializar banco: $e");
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _processarFilaOffline();
    });
  }

  // --- LÓGICA DE SINCRONIZAÇÃO ---
  Future<void> _processarFilaOffline() async {
    if (_isSyncing || _db == null) return;
    _isSyncing = true;

    try {
      final List<Map<String, dynamic>> pendentes = await _db!.query(
        'fila_eventos',
        orderBy: 'id ASC',
      );
      if (pendentes.isEmpty) return;

      Map<String, List<Map<String, dynamic>>> lotesComAtleta = {};
      Map<String, List<int>> idsParaDeletar = {};

      for (var item in pendentes) {
        final String pId = item['partida_id'];
        final int rowId = item['id'];
        final Map<String, dynamic> corpo = jsonDecode(item['dados']);

        // SE NÃO TEM ATLETA: envia para /eventos-gerais
        if (corpo['atletaId'] == null) {
          await _enviarEventoSemAtleta(pId, corpo, rowId);
          continue;
        }

        // SE TEM ATLETA: agrupa para envio em lote
        lotesComAtleta.putIfAbsent(pId, () => []).add(corpo);
        idsParaDeletar.putIfAbsent(pId, () => []).add(rowId);
      }

      for (var partidaId in lotesComAtleta.keys) {
        await _enviarLoteComAtleta(
          partidaId,
          lotesComAtleta[partidaId]!,
          idsParaDeletar[partidaId]!,
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  // ENDPOINT A: Eventos em Lote (Com Atleta)
  Future<void> _enviarLoteComAtleta(
    String partidaId,
    List<Map<String, dynamic>> lista,
    List<int> ids,
  ) async {
    try {
      debugPrint("=== LOTE COM ATLETA: /partidas/$partidaId/eventos ===");
      debugPrint(jsonEncode(lista));

      final response = await _dio.post(
        '/partidas/$partidaId/eventos',
        data: lista,
      );

      // ← FIX: 409 = servidor já tinha o evento (idempotência) → limpa fila normalmente
      final sucesso =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 409;

      if (sucesso && _db != null) {
        await _db!.delete('fila_eventos', where: 'id IN (${ids.join(',')})');
      }
    } on DioException catch (e) {
      // 409 pode vir como DioException dependendo da config do Dio
      if (e.response?.statusCode == 409 && _db != null) {
        await _db!.delete('fila_eventos', where: 'id IN (${ids.join(',')})');
      }
      debugPrint("Erro no lote: $e");
    }
  }

  // ENDPOINT B: Evento Individual (Sem Atleta)
  Future<void> _enviarEventoSemAtleta(
    String partidaId,
    Map<String, dynamic> dado,
    int rowId,
  ) async {
    try {
      debugPrint(
        "=== EVENTO SEM ATLETA: /partidas/$partidaId/eventos-gerais ===",
      );
      debugPrint(jsonEncode([dado]));

      final response = await _dio.post(
        '/partidas/$partidaId/eventos-gerais',
        data: [dado],
      );

      // ← FIX: 409 = servidor já tinha o evento (idempotência) → limpa fila normalmente
      final sucesso =
          response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 409;

      if (sucesso && _db != null) {
        await _db!.delete('fila_eventos', where: 'id = ?', whereArgs: [rowId]);
      }
    } on DioException catch (e) {
      // 409 pode vir como DioException dependendo da config do Dio
      if (e.response?.statusCode == 409 && _db != null) {
        await _db!.delete('fila_eventos', where: 'id = ?', whereArgs: [rowId]);
      }
      debugPrint("Erro evento individual: $e");
    }
  }

  // --- MÉTODO DE ESCRITA (SALVAR NA FILA) ---
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId,
    String? atletaSaiId,
    required String tempoFormatado,
    String? descricao,
    bool isSubstitution = false,
  }) async {
    final Map<String, dynamic> payload = {
      // ← ADD: chave de idempotência gerada no device
      "localEventoId": _uuid.v4(),
      "partidaId": partidaId,
      "equipeId": (equipeId?.isEmpty ?? true) ? null : equipeId,
      "atletaId": (atletaId?.isEmpty ?? true) ? null : atletaId,
      "atletaSaiId": (atletaSaiId?.isEmpty ?? true) ? null : atletaSaiId,
      "isSubstitution": isSubstitution,
      "tipoEventoId": tipoEventoId,
      "tempoCronometro": tempoFormatado,
      "descricaoDetalhada": descricao ?? "",
    };

    if (_db != null) {
      await _db!.insert('fila_eventos', {
        'partida_id': partidaId,
        'dados': jsonEncode(payload),
        'criado_em': DateTime.now().toIso8601String(), // ← FIX: campo faltante
      });

      // ← FIX: await garante que não reprocessa antes de terminar
      await _processarFilaOffline();
    }
  }

  // --- INTERCEPTORS ---
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

  // --- MÉTODOS DE BUSCA ---

  Future<Equipe?> buscarEquipePorId(String equipeId) async {
    final id = equipeId.trim();
    if (id.isEmpty) return null;

    final cached = _equipesCache[id];
    if (cached != null) return cached;

    return null;
  }

  Future<void> _precarregarEquipes(Iterable<String> ids) async {
    final uniques = <String>{};
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty) continue;
      if (_equipesCache.containsKey(id)) continue;
      uniques.add(id);
    }

    if (uniques.isEmpty) return;

    await Future.wait(uniques.map(buscarEquipePorId));
  }

  Future<List<Partida>> _enriquecerPartidasComEquipes(
    List<Partida> partidas,
  ) async {
    if (partidas.every((p) => p.equipeA != null && p.equipeB != null)) {
      return partidas;
    }

    final ids = <String>[];
    for (final p in partidas) {
      ids.add(p.equipeAId);
      ids.add(p.equipeBId);
    }

    await _precarregarEquipes(ids);

    return partidas.map((p) {
      // Buscamos as equipes no cache (que têm os escudos)
      final eqA = _equipesCache[p.equipeAId];
      final eqB = _equipesCache[p.equipeBId];

      return p.copyWith(
        // Forçamos o uso da equipe do cache se ela existir,
        // ignorando o que veio "seco" no snapshotSumula
        equipeA: eqA ?? p.equipeA,
        equipeB: eqB ?? p.equipeB,
      );
    }).toList();
  }

  Future<Partida> carregarEquipesDaPartida(Partida partida) async {
    if (partida.equipeA != null && partida.equipeB != null) return partida;

    await _precarregarEquipes([partida.equipeAId, partida.equipeBId]);

    return partida.copyWith(
      equipeA: partida.equipeA ?? _equipesCache[partida.equipeAId],
      equipeB: partida.equipeB ?? _equipesCache[partida.equipeBId],
    );
  }

  Future<List<Partida>> listarTodasPartidas() async {
    try {
      final response = await _dio.get('/partidas');
      if (response.statusCode == 200) {
        final partidas = (response.data as List)
            .map((m) => Partida.fromMap(m))
            .toList();
        return await _enriquecerPartidasComEquipes(partidas);
      }
    } catch (e) {
      debugPrint("Erro listarTodasPartidas: $e");
    }
    return [];
  }

  Future<List<Partida>> listarPartidasMinhas() async {
    try {
      final response = await _dio.get('/partidas/minhas');
      if (response.statusCode == 200) {
        final partidas = (response.data as List)
            .map((m) => Partida.fromMap(m))
            .toList();
        return await _enriquecerPartidasComEquipes(partidas);
      }
    } catch (e) {
      debugPrint("Erro listarPartidasMinhas: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> buscarUltimoEventoComTempo(
    String partidaId,
  ) async {
    try {
      final eventos = await buscarEventosDaPartida(partidaId);

      // Sort defensivo: eventos sem criadoEm vão para o fim
      eventos.sort((a, b) {
        final dateA = a['criadoEm']?.toString() ?? '';
        final dateB = b['criadoEm']?.toString() ?? '';
        if (dateA.isEmpty && dateB.isEmpty) return 0;
        if (dateA.isEmpty) return 1; // a vai para o fim
        if (dateB.isEmpty) return -1; // b vai para o fim
        return dateB.compareTo(dateA); // mais recente primeiro
      });

      for (var ev in eventos) {
        final tempo = ev['tempoCronometro']?.toString() ?? '';
        if (tempo.isNotEmpty && ev['atletaId'] == null) {
          return {
            'tempo_cronometro': tempo,
            'criado_em': ev['criadoEm'],
            'tipo_evento_id': ev['tipoEventoId'],
            'tipo_evento_codigo': ev['tipoEventoCodigo'] ?? ev['codigo'] ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar ultimo evento: $e');
    }
    return null;
  }

  Future<List<Arbitro>> listarTodosArbitros() async {
    try {
      final response = await _dio.get('/arbitros');
      if (response.statusCode == 200) {
        return (response.data as List).map((m) => Arbitro.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodosArbitros: $e");
    }
    return [];
  }

  Future<List<Campeonato>> listarTodosCampeonatos() async {
    try {
      final response = await _dio.get('/campeonatos');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((m) => Campeonato.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodosCampeonatos: $e");
    }
    return [];
  }

  Future<List<Atletica>> listarTodasAtleticas() async {
    try {
      final response = await _dio.get('/atleticas');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((m) => Atletica.fromMap(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodasAtleticas: $e");
    }
    return [];
  }

  Future<List<ModalidadeCatalogo>> listarTodasModalidadesCatalogo() async {
    try {
      final response = await _dio.get('/modalidades-catalogo');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((m) => ModalidadeCatalogo.fromMap(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Erro listarTodasModalidadesCatalogo: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> buscarConfiguracaoModalidadeDaPartida(
    String modalidadeId,
  ) async {
    try {
      final response = await _dio.get('/modalidades/$modalidadeId');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Erro buscarConfiguracaoModalidadeDaPartida: $e');
    }
    return null;
  }

  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(
    String modalidadeId,
  ) async {
    try {
      final modalidade = await buscarConfiguracaoModalidadeDaPartida(
        modalidadeId,
      );
      final modalidadeCatalogoId = modalidade?['modalidadeCatalogoId']
          ?.toString();
      if (modalidadeCatalogoId != null && modalidadeCatalogoId.isNotEmpty) {
        // O backend ainda expõe essa rota sob /esportes/{id}/tipos-eventos,
        // mas o parâmetro esperado é o ID da modalidade catálogo.
        final resEvt = await _dio.get(
          '/esportes/$modalidadeCatalogoId/tipos-eventos',
        );
        if (resEvt.statusCode == 200) {
          return (resEvt.data as List)
              .map((e) => TipoEventoEsporte.fromMap(e))
              .toList()
            ..sort(
              (a, b) => (a.ordemExibicao ?? a.idx ?? 9999).compareTo(
                b.ordemExibicao ?? b.idx ?? 9999,
              ),
            );
        }
      }
    } catch (e) {
      debugPrint('Erro buscarTiposDeEventoDaPartida: $e');
    }
    return [];
  }

  Future<List<dynamic>> buscarInscritos(String equipeId) async {
    try {
      final response = await _dio.get('/times/campeonato/$equipeId/atletas');
      if (response.statusCode == 200 && response.data is List) {
        return response.data as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Erro buscarInscritos (novo endpoint): $e');
    }

    try {
      final fallback = await _dio.get('/equipes/$equipeId/inscritos');
      if (fallback.statusCode == 200 && fallback.data is List) {
        return fallback.data as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Erro buscarInscritos (fallback legado): $e');
    }
    return [];
  }

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    switch (aba) {
      case 'Jogos':
        return await listarTodasPartidas();
      case 'Árbitros':
        return await listarTodosArbitros();
      case 'Campeonatos':
        return await listarTodosCampeonatos();
      case 'Atléticas':
        return await listarTodasAtleticas();
      case 'Modalidades':
        return await listarTodasModalidadesCatalogo();
      default:
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> buscarEventosDaPartida(
    String partidaId,
  ) async {
    try {
      final response = await _dio.get('/partidas/' + partidaId + '/eventos');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      debugPrint("Erro buscarEventosDaPartida: " + e.toString());
    }
    return [];
  }

  Future<void> atualizarEvento({
    required String partidaId,
    required String eventoId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId,
    String? atletaSaiId,
    bool isSubstitution = false,
    required String tempoFormatado,
    String? descricao,
  }) async {
    try {
      await _dio.put(
        '/partidas/$partidaId/eventos/$eventoId',
        data: {
          'equipeId': equipeId,
          'atletaId': atletaId,
          'atletaSaiId': atletaSaiId,
          'isSubstitution': isSubstitution,
          'tipoEventoId': tipoEventoId,
          'tempoCronometro': tempoFormatado,
          'descricaoDetalhada': descricao ?? '',
        },
      );
    } catch (e) {
      debugPrint('Erro atualizarEvento: $e');
    }
  }

  Future<void> excluirEvento({
    required String partidaId,
    required String eventoId,
  }) async {
    try {
      await _dio.delete('/partidas/$partidaId/eventos/$eventoId');
    } catch (e) {
      debugPrint('Erro excluirEvento: $e');
    }
  }

  Future<void> atualizarPartida(
    String partidaId, {
    String? novoStatus,
    String? periodoAntesPausa,
  }) async {
    final status = novoStatus?.trim();
    if (status == null || status.isEmpty) return;

    try {
      final data = <String, dynamic>{"status": status};
      final pap = periodoAntesPausa?.trim();
      if (pap != null && pap.isNotEmpty) {
        data["periodo_antes_pausa"] = pap;
      } else if (status.toLowerCase() != 'pausada') {
        data["periodo_antes_pausa"] = '';
      }
      await _dio.patch('/partidas/$partidaId/status', data: data);
    } catch (e) {
      debugPrint("Erro atualizar status da partida: $e");
    }
  }

  Future<Uint8List> baixarSumulaOficialPdf(String partidaId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/partidas/$partidaId/sumula-oficial.pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) {
        throw Exception('Resposta vazia ao gerar a súmula oficial.');
      }
      return Uint8List.fromList(data);
    } catch (e) {
      debugPrint('Erro baixarSumulaOficialPdf: $e');
      rethrow;
    }
  }

  Future<void> startPartida(String partidaId) async {
    try {
      await _dio.post('/partidas/$partidaId/start');
    } catch (e) {
      debugPrint("Erro ao iniciar partida: $e");
    }
  }

  Future<(int?, String?)> endPartida(String partidaId) async {
    try {
      final res = await _dio.post('/partidas/$partidaId/end');
      return (res.statusCode, null);
    } catch (e) {
      if (e is DioException) {
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String? detail;
        if (data is Map) {
          final d = data['detail'];
          if (d != null) detail = d.toString();
        }
        if (code != 409) {
          debugPrint("Erro ao fechar súmula da partida: $e");
        }
        return (code, detail);
      }
      debugPrint("Erro ao fechar súmula da partida: $e");
      return (null, null);
    }
  }

  Future<Partida?> buscarPartidaPorId(String partidaId) async {
    try {
      final res = await _dio.get('/partidas/$partidaId');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return Partida.fromMap(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Erro buscarPartidaPorId: $e");
    }
    return null;
  }

  /// Subscreve ao Supabase Realtime para mudanças na partida (operational.partidas).
  RealtimeChannel subscribeRealtimePartida(
    String partidaId, {
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _supabase
        .channel('partida_$partidaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'operational',
          table: 'partidas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: partidaId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) onUpdate(newRecord);
          },
        )
        .subscribe();
  }

  /// Subscreve ao Supabase Realtime para novos eventos da partida.
  RealtimeChannel subscribeRealtimeEventos(
    String partidaId, {
    required void Function(Map<String, dynamic> payload) onInsert,
  }) {
    return _supabase
        .channel('eventos_partida_$partidaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'operational',
          table: 'eventos_partida',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'partida_id',
            value: partidaId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) onInsert(newRecord);
          },
        )
        .subscribe();
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _db?.close();
  }
}
