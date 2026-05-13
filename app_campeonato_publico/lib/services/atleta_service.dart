import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/core/app_globals.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AtletaService {
  static final Map<String, List<Map<String, dynamic>>> _cachedTopAthletes = {};
  static final Map<String, DateTime> _lastCacheTime = {};

  /// Retorna o atleta com mais ocorrências do tipo de evento informado.
  /// [nomeTipoEvento] é o código do tipo de evento (ex: 'GOL', 'PONTO').
  /// Usa public.eventos_partida_publicos filtrado pelo campeonato ativo.
  Future<List<Map<String, dynamic>>> getTopAthletes(
    String nomeTipoEvento, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedTopAthletes.containsKey(nomeTipoEvento) &&
        _lastCacheTime.containsKey(nomeTipoEvento)) {
      if (DateTime.now()
              .difference(_lastCacheTime[nomeTipoEvento]!)
              .inMinutes <
          5) {
        return _cachedTopAthletes[nomeTipoEvento]!;
      }
    }

    try {
      // 1. Obter partidas do campeonato ativo (ao vivo + histórico)
      final campId = AppGlobals.campeonatoAtivo?.id;

      List<String> partidaIds = [];

      var queryAoVivo = _supabase
          .from('partidas_ao_vivo')
          .select('partida_id');
      if (campId != null && campId.isNotEmpty) {
        queryAoVivo = queryAoVivo.eq('campeonato_id', campId);
      }

      var queryHist = _supabase
          .from('partidas_historico')
          .select('partida_id');
      if (campId != null && campId.isNotEmpty) {
        queryHist = queryHist.eq('campeonato_id', campId);
      }

      final resAoVivo = await queryAoVivo;
      final resHist = await queryHist;

      partidaIds.addAll(
        (resAoVivo as List).map((p) => p['partida_id'].toString()),
      );
      partidaIds.addAll(
        (resHist as List).map((p) => p['partida_id'].toString()),
      );

      if (partidaIds.isEmpty) return [];

      // 2. Buscar eventos do tipo informado com atleta vinculado
      final eventosRes = await _supabase
          .from('eventos_partida_publicos')
          .select(
            'atleta_id, atleta_nome_exibicao, atleta_foto_url, equipe_nome, tipo_evento_codigo',
          )
          .inFilter('partida_id', partidaIds)
          .eq('tipo_evento_codigo', nomeTipoEvento.toUpperCase())
          .not('atleta_id', 'is', null);

      if ((eventosRes as List).isEmpty) return [];

      // 3. Agrupar por atleta_id e contar
      final Map<String, Map<String, dynamic>> countMap = {};
      for (final ev in eventosRes) {
        final atletaId = ev['atleta_id']?.toString();
        if (atletaId == null) continue;
        if (!countMap.containsKey(atletaId)) {
          countMap[atletaId] = {
            'atleta_id': atletaId,
            'nome': ev['atleta_nome_exibicao'] ?? 'Atleta',
            'foto': ev['atleta_foto_url'],
            'modalidade': ev['equipe_nome'] ?? 'Geral',
            'count': 0,
            'label': nomeTipoEvento.toUpperCase() == 'GOL' ? 'GOL' : 'PONTO',
          };
        }
        countMap[atletaId]!['count'] =
            (countMap[atletaId]!['count'] as int) + 1;
      }

      // 4. Ordenar e pegar o top 1
      final sorted = countMap.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      if (sorted.isEmpty) return [];

      final top = sorted.first;
      final result = [
        {
          'atleta_id': top['atleta_id'],
          'nome': top['nome'],
          'foto': top['foto'],
          'modalidade': top['modalidade'],
          'valor': top['count'].toString(),
          'label': top['label'],
          'time_escudo': null,
        },
      ];

      _cachedTopAthletes[nomeTipoEvento] = result;
      _lastCacheTime[nomeTipoEvento] = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('ERRO AtletaService.getTopAthletes: $e');
      return [];
    }
  }
}
