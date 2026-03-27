import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço responsável por buscar dados de partidas e atletas para as telas de Game.
class GameService {
  final SupabaseClient _supabase;

  GameService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Busca os IDs das equipes de uma partida.
  Future<Map<String, dynamic>> getPartidaEquipes(String partidaId) async {
    return await _supabase
        .from('partidas')
        .select('equipe_a_id, equipe_b_id')
        .eq('id', partidaId)
        .single();
  }

  /// Busca atletas inscritos de uma equipe, separados em titulares e reservas.
  Future<List<Map<String, dynamic>>> getAtletasInscritos(
    String equipeId,
  ) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('equipe_atlet_inscritos')
          .select('ativo, numero_camisa, atletas(*)')
          .eq('equipe_id', equipeId),
    );
  }

  /// Busca dados de uma partida com joins de equipes para a tela de resumo.
  Future<Map<String, dynamic>> getPartidaComEquipes(String partidaId) async {
    return await _supabase
        .from('partidas')
        .select('''
          modalidade_id,
          equipe_a:equipes!partidas_equipe_a_id_fkey(atletica_id),
          equipe_b:equipes!partidas_equipe_b_id_fkey(atletica_id)
        ''')
        .eq('id', partidaId)
        .single();
  }

  /// Busca modalidade para obter o esporte_id.
  Future<Map<String, dynamic>> getModalidadeInfo(String modalidadeId) async {
    return await _supabase
        .from('modalidades')
        .select('esporte_id')
        .eq('id', modalidadeId)
        .single();
  }

  /// Busca tipos de eventos por esporte_id.
  Future<List<Map<String, dynamic>>> getTiposEventos(String esporteId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('tipos_eventos')
          .select('id, nome')
          .eq('esporte_id', esporteId),
    );
  }

  /// Busca eventos de uma partida com join do atleta.
  Future<List<Map<String, dynamic>>> getEventosPartida(String partidaId) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('eventos_partida')
          .select(
            '*, atletas!eventos_partida_atleta_id_fkey(atletica_id,nome,foto_url)',
          )
          .eq('partida_id', partidaId),
    );
  }

  /// Busca eventos de um atleta em uma partida específica.
  Future<List<Map<String, dynamic>>> getEventosAtleta(
    String partidaId,
    String atletaId,
  ) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('eventos_partida')
          .select('*')
          .eq('partida_id', partidaId)
          .or('atleta_id.eq.$atletaId,atleta_sai_id.eq.$atletaId'),
    );
  }

  /// Busca geral de eventos de um atleta (sem filtro de partida).
  Future<List<Map<String, dynamic>>> getEventosAtletaGeral(
    String atletaId,
  ) async {
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('eventos_partida')
          .select('*')
          .or('atleta_id.eq.$atletaId,atleta_sai_id.eq.$atletaId'),
    );
  }

  /// Busca todos os tipos de eventos (sem filtro de esporte).
  Future<List<Map<String, dynamic>>> getTodosTiposEventos() async {
    return List<Map<String, dynamic>>.from(
      await _supabase.from('tipos_eventos').select('*'),
    );
  }
}
