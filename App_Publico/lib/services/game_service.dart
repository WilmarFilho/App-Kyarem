import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço responsável por buscar dados de partidas e atletas para as telas de Game.
/// Todas as consultas usam exclusivamente o schema public via Supabase SDK.
class GameService {
  final SupabaseClient _supabase;

  GameService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Busca os IDs dos times de campeonato de uma partida.
  /// Consulta primeiro em partidas_ao_vivo; se não encontrar, tenta partidas_historico.
  Future<Map<String, dynamic>> getPartidaEquipes(String partidaId) async {
    try {
      final resAoVivo = await _supabase
          .from('partidas_ao_vivo')
          .select(
            'partida_id, campeonato_modalidade_id, campeonato_time_a_id, campeonato_time_b_id, time_a_atletica_id, time_b_atletica_id',
          )
          .eq('partida_id', partidaId)
          .maybeSingle();

      if (resAoVivo != null) {
        return {
          'equipe_a_id': resAoVivo['campeonato_time_a_id'],
          'equipe_b_id': resAoVivo['campeonato_time_b_id'],
          'atletica_a_id': resAoVivo['time_a_atletica_id'],
          'atletica_b_id': resAoVivo['time_b_atletica_id'],
          'campeonato_time_a_id': resAoVivo['campeonato_time_a_id'],
          'campeonato_time_b_id': resAoVivo['campeonato_time_b_id'],
          'campeonato_modalidade_id': resAoVivo['campeonato_modalidade_id'],
          'partida_id': partidaId,
          'fonte': 'ao_vivo',
        };
      }

      final resHist = await _supabase
          .from('partidas_historico')
          .select(
            'partida_id, campeonato_modalidade_id, campeonato_time_a_id, campeonato_time_b_id, time_a_atletica_id, time_b_atletica_id',
          )
          .eq('partida_id', partidaId)
          .maybeSingle();

      if (resHist != null) {
        return {
          'equipe_a_id': resHist['campeonato_time_a_id'],
          'equipe_b_id': resHist['campeonato_time_b_id'],
          'atletica_a_id': resHist['time_a_atletica_id'],
          'atletica_b_id': resHist['time_b_atletica_id'],
          'campeonato_time_a_id': resHist['campeonato_time_a_id'],
          'campeonato_time_b_id': resHist['campeonato_time_b_id'],
          'campeonato_modalidade_id': resHist['campeonato_modalidade_id'],
          'partida_id': partidaId,
          'fonte': 'historico',
        };
      }
    } catch (e) {
      debugPrint('GameService.getPartidaEquipes error: $e');
    }
    return {};
  }

  /// Busca atletas inscritos de um campeonato_time.
  /// Usa public.campeonato_atletas_publicos.
  Future<List<Map<String, dynamic>>> getAtletasInscritos(
    String campeonatoTimeId, {
    String? campeonatoId,
  }) async {
    try {
      var query = _supabase
          .from('campeonato_atletas_publicos')
          .select(
            'atleta_id, atletica_id, numero_camisa, is_capitao, is_goleiro, status, campeonato_time_id',
          )
          .eq('campeonato_time_id', campeonatoTimeId)
          .eq('status', 'ATIVO');

      if (campeonatoId != null && campeonatoId.isNotEmpty) {
        query = query.eq('campeonato_id', campeonatoId);
      }

      final inscritosRes = await query;
      final inscritos = List<Map<String, dynamic>>.from(inscritosRes);

      if (inscritos.isEmpty) return [];

      // Buscar perfis dos atletas
      final atletaIds = inscritos
          .map((i) => i['atleta_id'].toString())
          .toList();

      final perfisRes = await _supabase
          .from('perfis_atletas')
          .select('atleta_id, nome_exibicao, nome_completo, avatar_url')
          .inFilter('atleta_id', atletaIds);

      final perfisMap = {
        for (var p in (perfisRes as List))
          p['atleta_id'].toString(): p as Map<String, dynamic>,
      };

      // Montar resultado compatível com o model Atleta
      return inscritos.map((inscrito) {
        final atletaId = inscrito['atleta_id'].toString();
        final perfil = perfisMap[atletaId] ?? {};
        return {
          'ativo': inscrito['status'] == 'ATIVO',
          'numero_camisa': inscrito['numero_camisa'],
          'is_capitao': inscrito['is_capitao'],
          'is_goleiro': inscrito['is_goleiro'],
          // estrutura compatível com Atleta.fromMap via 'atletas'
          'atletas': {
            'id': atletaId,
            'atletica_id': inscrito['atletica_id'] ?? '',
            'nome':
                perfil['nome_exibicao'] ?? perfil['nome_completo'] ?? 'Atleta',
            'foto_url': perfil['avatar_url'],
          },
        };
      }).toList();
    } catch (e) {
      debugPrint('GameService.getAtletasInscritos error: $e');
      return [];
    }
  }

  /// Busca dados de uma partida com info de equipes para a tela de resumo.
  Future<Map<String, dynamic>> getPartidaComEquipes(String partidaId) async {
    try {
      final resAoVivo = await _supabase
          .from('partidas_ao_vivo')
          .select('*')
          .eq('partida_id', partidaId)
          .maybeSingle();
      if (resAoVivo != null) return Map<String, dynamic>.from(resAoVivo);

      final resHist = await _supabase
          .from('partidas_historico')
          .select('*')
          .eq('partida_id', partidaId)
          .maybeSingle();
      if (resHist != null) return Map<String, dynamic>.from(resHist);
    } catch (e) {
      debugPrint('GameService.getPartidaComEquipes error: $e');
    }
    return {};
  }

  /// Busca tipos de eventos únicos de uma modalidade a partir dos eventos públicos.
  Future<List<Map<String, dynamic>>> getTiposEventos(
    String campeonatoModalidadeId,
  ) async {
    try {
      // Busca as partidas da modalidade
      final partAoVivo = await _supabase
          .from('partidas_ao_vivo')
          .select('partida_id')
          .eq('campeonato_modalidade_id', campeonatoModalidadeId);
      final partHist = await _supabase
          .from('partidas_historico')
          .select('partida_id')
          .eq('campeonato_modalidade_id', campeonatoModalidadeId);

      final ids = [
        ...(partAoVivo as List).map((p) => p['partida_id'].toString()),
        ...(partHist as List).map((p) => p['partida_id'].toString()),
      ];
      if (ids.isEmpty) return [];

      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('tipo_evento_codigo, tipo_evento_nome')
          .inFilter('partida_id', ids);

      // Deduplicar por codigo
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];
      for (final e in (res as List)) {
        final codigo = e['tipo_evento_codigo']?.toString() ?? '';
        if (seen.add(codigo)) {
          result.add({
            'id': codigo, // usa codigo como id para lookup
            'nome': e['tipo_evento_nome'] ?? codigo,
            'codigo': codigo,
          });
        }
      }
      return result;
    } catch (e) {
      debugPrint('GameService.getTiposEventos error: $e');
      return [];
    }
  }

  /// Busca eventos de uma partida no schema público.
  Future<List<Map<String, dynamic>>> getEventosPartida(String partidaId) async {
    try {
      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('*')
          .eq('partida_id', partidaId)
          .order('criado_em', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('GameService.getEventosPartida error: $e');
      return [];
    }
  }

  /// Busca eventos de um atleta em uma partida específica (schema público).
  Future<List<Map<String, dynamic>>> getEventosAtleta(
    String partidaId,
    String atletaId,
  ) async {
    try {
      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('*')
          .eq('partida_id', partidaId)
          .or('atleta_id.eq.$atletaId,atleta_sai_id.eq.$atletaId');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('GameService.getEventosAtleta error: $e');
      return [];
    }
  }

  /// Busca geral de eventos de um atleta (sem filtro de partida).
  Future<List<Map<String, dynamic>>> getEventosAtletaGeral(
    String atletaId,
  ) async {
    try {
      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('*')
          .or('atleta_id.eq.$atletaId,atleta_sai_id.eq.$atletaId');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('GameService.getEventosAtletaGeral error: $e');
      return [];
    }
  }

  /// Busca todos os tipos de eventos únicos (sem filtro de modalidade).
  Future<List<Map<String, dynamic>>> getTodosTiposEventos() async {
    try {
      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('tipo_evento_codigo, tipo_evento_nome');

      final seen = <String>{};
      final result = <Map<String, dynamic>>[];
      for (final e in (res as List)) {
        final codigo = e['tipo_evento_codigo']?.toString() ?? '';
        if (seen.add(codigo)) {
          result.add({
            'id': codigo,
            'nome': e['tipo_evento_nome'] ?? codigo,
            'codigo': codigo,
          });
        }
      }
      return result;
    } catch (e) {
      debugPrint('GameService.getTodosTiposEventos error: $e');
      return [];
    }
  }
}
