import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  static List<Partida>? _cachedFinishedMatches;
  static DateTime? _lastFinishedMatchesTime;

  Future<List<Partida>> getMatchesByModalityAndStatus({
    required String modalityId,
    String status = 'all',
  }) async {
    try {
      // 1. Iniciamos a base da query
      var query = _supabase.from('partidas').select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''');

      // Aplica o filtro obrigatório de modalidade
      query = query.eq('modalidade_id', modalityId);

      // Lógica para o Status
      if (status == 'all') {
        // Se for 'all', não adicionamos nenhum filtro de status.
        // A query continuará apenas com o filtro de modalidade_id.
      } else if (status == 'finalizadas_e_fechadas') {
        // Caso queira um grupo específico (como discutimos antes)
        query = query.inFilter('status', ['finalizada', 'fechada']);
      } else {
        // Filtra pelo status específico passado (ex: 'andamento', 'agendada')
        query = query.eq('status', status);
      }

      // 4. Ordenação (Note que usei iniciada_em como no seu código original)
      final response = await query.order('iniciada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar partidas: $e');
      return [];
    }
  }

  Future<List<Partida>> getActiveMatches() async {
    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .neq('status', 'agendada')
          .neq('status', 'finalizada')
          .neq('status', 'fechada')
          .order('iniciada_em', ascending: false);

      return (response as List).map((json) => Partida.fromMap(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar destaques: $e');
      return [];
    }
  }

  Future<List<Partida>> getFinishedMatches({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedFinishedMatches != null &&
        _lastFinishedMatchesTime != null) {
      if (DateTime.now().difference(_lastFinishedMatchesTime!).inMinutes < 5) {
        return _cachedFinishedMatches!;
      }
    }

    try {
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*)),
            modalidade:modalidades(*)
          ''')
          .inFilter('status', ['finalizada', 'fechada'])
          .order('encerrada_em', ascending: false)
          .limit(4);

      _cachedFinishedMatches = (response as List)
          .map((json) => Partida.fromMap(json))
          .toList();
      _lastFinishedMatchesTime = DateTime.now();

      return _cachedFinishedMatches!;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }
}
