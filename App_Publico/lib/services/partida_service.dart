import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/core/app_globals.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  static List<Partida>? _cachedFinishedMatches;
  static DateTime? _lastFinishedMatchesTime;

  Future<List<Partida>> getMatchesByModalityAndStatus({
    required String modalityId,
    String status = 'all',
  }) async {
    try {
      List<Partida> allMatches = [];

      // Se não for especificamente finalizadas_e_fechadas, busca nas ao_vivo
      if (status != 'finalizadas_e_fechadas') {
        var queryAoVivo = _supabase.from('partidas_ao_vivo').select('*');
        queryAoVivo = queryAoVivo.eq('campeonato_modalidade_id', modalityId);
        
        if (status != 'all' && status != 'finalizadas_e_fechadas') {
            queryAoVivo = queryAoVivo.eq('status', status);
        }

        final resAoVivo = await queryAoVivo.order('agendado_para', ascending: true);
        allMatches.addAll((resAoVivo as List).map((json) => Partida.fromMap(json)));
      }

      // Se for all ou especificamente finalizadas_e_fechadas, busca no historico
      if (status == 'all' || status == 'finalizadas_e_fechadas') {
        var queryHist = _supabase.from('partidas_historico').select('*');
        queryHist = queryHist.eq('campeonato_modalidade_id', modalityId);

        if (status == 'finalizadas_e_fechadas') {
           // O historico já tem finalizadas e fechadas
        }

        final resHist = await queryHist.order('iniciada_em', ascending: false);
        allMatches.addAll((resHist as List).map((json) => Partida.fromMap(json)));
      }

      return allMatches;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar partidas: $e');
      return [];
    }
  }

  Future<List<Partida>> getActiveMatches() async {
    try {
      var query = _supabase
          .from('partidas_ao_vivo')
          .select('*')
          .neq('status', 'agendada')
          .neq('status', 'finalizada')
          .neq('status', 'fechada');

      // Filtra pelo campeonato ativo configurado no .env
      final campId = AppGlobals.campeonatoAtivo?.id;
      if (campId != null && campId.isNotEmpty) {
        query = query.eq('campeonato_id', campId);
      }

      final response = await query.order('partida_id', ascending: false);
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
      var query = _supabase
          .from('partidas_historico')
          .select('*');

      // Filtra pelo campeonato ativo configurado no .env
      final campId = AppGlobals.campeonatoAtivo?.id;
      if (campId != null && campId.isNotEmpty) {
        query = query.eq('campeonato_id', campId);
      }

      final response = await query
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
